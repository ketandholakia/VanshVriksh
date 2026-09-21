// Migration parity and safety.
//
// The canonical schema is v12. Everything older is an *import path*, and the
// upgrade is one consolidated, deterministic routine. These tests pin the two
// properties that matter:
//
//  1. a migrated database is structurally identical to a fresh one — same
//     tables, columns, defaults, nullability, primary keys, foreign keys, delete
//     actions, unique constraints and indexes;
//  2. a migration that cannot complete leaves the database exactly as it was,
//     instead of half-migrated.
//
// Plus the lossless handling of legacy data that is ambiguous (a child with more
// recorded parents than a family can hold) and of legacy relationship values
// that are not part of the confirmed vocabulary.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// Transitive dependency of drift; used only to build the fixtures.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:vanshvriksh/data/database/app_database.dart';

/// A structural fingerprint of a database: everything that must be identical
/// between a fresh and a migrated schema.
Future<Map<String, Object?>> schemaFingerprint(AppDatabase db) async {
  final fingerprint = <String, Object?>{};

  final tables = await db
      .customSelect(
        "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();

  fingerprint['tables'] = tables.map((row) => row.data['name']).toList();

  for (final table in tables) {
    final name = table.data['name'] as String;

    final columns = await db.customSelect('PRAGMA table_info($name)').get();
    final foreignKeys =
        await db.customSelect('PRAGMA foreign_key_list($name)').get();
    final indexes = await db.customSelect("PRAGMA index_list('$name')").get();

    fingerprint[name] = {
      // name | type | notnull | default | primary-key position
      'columns': [
        for (final column in columns)
          '${column.data['name']}|${column.data['type']}|'
              '${column.data['notnull']}|${column.data['dflt_value']}|'
              '${column.data['pk']}',
      ]..sort(),
      // from -> table.to | on_delete | on_update
      'foreignKeys': [
        for (final fk in foreignKeys)
          '${fk.data['from']}->${fk.data['table']}.${fk.data['to']}|'
              '${fk.data['on_delete']}|${fk.data['on_update']}',
      ]..sort(),
      // name | unique | origin (u = UNIQUE constraint, pk = PRIMARY KEY)
      'indexes': [
        for (final index in indexes)
          '${index.data['name']}|${index.data['unique']}|'
              '${index.data['origin']}',
      ]..sort(),
      'sql': (table.data['sql'] as String? ?? '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    };
  }

  final namedIndexes = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_autoindex%' ORDER BY name",
      )
      .get();
  fingerprint['namedIndexes'] =
      namedIndexes.map((row) => row.data['name']).toList();

  return fingerprint;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vv_parity_');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {
      // best effort
    }
  });

  String pathFor(String name) =>
      '${tempDir.path}${Platform.pathSeparator}$name.sqlite';

  Future<Map<String, Object?>> freshFingerprint() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('SELECT 1');
    final fingerprint = await schemaFingerprint(db);
    await db.close();
    return fingerprint;
  }

  /// Creates a database holding only the legacy tables, rewinds `user_version`
  /// to [version], then reopens it so the consolidated upgrade runs.
  Future<void> seedLegacyOnly(String path, int version) async {
    final setup = AppDatabase.forTesting(NativeDatabase(File(path)));
    await setup.customStatement('SELECT 1');
    await setup.close();

    final raw = sqlite.sqlite3.open(path);
    try {
      raw.execute('''
        CREATE TABLE persons (
          id TEXT NOT NULL, tree_id TEXT NOT NULL, full_name TEXT NOT NULL,
          first_name TEXT, middle_name TEXT, last_name TEXT, prefix TEXT,
          suffix TEXT, nickname TEXT, gender TEXT NOT NULL, birth_date INTEGER,
          death_date INTEGER, birth_place TEXT, current_place TEXT,
          profile_photo_path TEXT, bio TEXT, notes TEXT,
          private INTEGER NOT NULL DEFAULT 0,
          is_living INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
          PRIMARY KEY (id)
        )
      ''');
      raw.execute('''
        CREATE TABLE relationships (
          id TEXT NOT NULL, tree_id TEXT NOT NULL, person_id TEXT NOT NULL,
          related_person_id TEXT NOT NULL, relationship_type TEXT NOT NULL,
          created_at INTEGER NOT NULL, PRIMARY KEY (id)
        )
      ''');
      raw.execute('PRAGMA user_version = $version');
    } finally {
      raw.close();
    }
  }

  group('a migrated database matches a fresh one', () {
    test('after upgrading a v11 database', () async {
      final path = pathFor('from11');
      final setup = AppDatabase.forTesting(NativeDatabase(File(path)));
      await setup.customStatement('SELECT 1');
      await setup.close();

      final raw = sqlite.sqlite3.open(path);
      raw.execute('PRAGMA user_version = 11');
      raw.close();

      final migrated = AppDatabase.forTesting(NativeDatabase(File(path)));
      await migrated.customStatement('SELECT 1');
      final migratedFingerprint = await schemaFingerprint(migrated);
      await migrated.close();

      expect(migratedFingerprint, await freshFingerprint());
    });

    test('after upgrading a sparse legacy database', () async {
      final path = pathFor('from7');
      await seedLegacyOnly(path, 7);

      final migrated = AppDatabase.forTesting(NativeDatabase(File(path)));
      await migrated.customStatement('SELECT 1');
      final migratedFingerprint = await schemaFingerprint(migrated);
      await migrated.close();

      // The upgrade had to create every canonical table from scratch and then
      // rebuild it; the result must still be indistinguishable from a fresh one.
      expect(migratedFingerprint, await freshFingerprint());
    });
  });

  group('legacy ambiguity is preserved, never guessed', () {
    test('a child with more recorded parents than a family keeps them all',
        () async {
      final path = pathFor('manyparents');
      await seedLegacyOnly(path, 11);

      final raw = sqlite.sqlite3.open(path);
      try {
        // The tokenizer above is a placeholder: reuse the real columns.
        raw.execute('DELETE FROM persons');
        for (final person in const [
          ('p1', 'M'),
          ('p2', 'F'),
          ('p3', 'F'),
          ('kid', 'M'),
        ]) {
          raw.execute(
            'INSERT INTO persons (id, tree_id, full_name, first_name, gender, '
            'created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, 0)',
            [person.$1, 'default-tree', person.$1, person.$1, person.$2],
          );
        }
        var index = 0;
        for (final parent in const ['p1', 'p2', 'p3']) {
          raw.execute(
            'INSERT INTO relationships (id, tree_id, person_id, '
            'related_person_id, relationship_type, created_at) '
            "VALUES (?, 'default-tree', ?, 'kid', 'parent_child', 0)",
            ['rel-${index++}', parent],
          );
        }
      } finally {
        raw.close();
      }

      final migrated = AppDatabase.forTesting(NativeDatabase(File(path)));
      await migrated.customStatement('SELECT 1');

      // All three parents survive, across two families.
      final links = await migrated.select(migrated.familyChildrenV2).get();
      expect(links.where((l) => l.childId == 'kid'), hasLength(2));

      final families = await migrated.select(migrated.familiesV2).get();
      final childParents = <String>{};
      for (final family in families) {
        final linked = links.any(
          (l) => l.familyId == family.id && l.childId == 'kid',
        );
        if (!linked) continue;
        if (family.husbandId != null) childParents.add(family.husbandId!);
        if (family.wifeId != null) childParents.add(family.wifeId!);
      }
      expect(childParents, {'p1', 'p2', 'p3'});

      // ...and the family that holds the additional parent says why.
      expect(
        families.where((f) => (f.notes ?? '').contains('additional parents')),
        isNotEmpty,
      );

      await migrated.close();
    });

    test('a legacy relationship value outside the confirmed vocabulary is '
        'ignored rather than guessed', () async {
      final path = pathFor('unknowntype');
      await seedLegacyOnly(path, 11);

      final raw = sqlite.sqlite3.open(path);
      try {
        raw.execute('DELETE FROM persons');
        for (final person in const [('p1', 'M'), ('p2', 'F')]) {
          raw.execute(
            'INSERT INTO persons (id, tree_id, full_name, first_name, gender, '
            'created_at, updated_at) VALUES (?, ?, ?, ?, ?, 0, 0)',
            [person.$1, 'default-tree', person.$1, person.$1, person.$2],
          );
        }
        raw.execute(
          'INSERT INTO relationships (id, tree_id, person_id, '
          'related_person_id, relationship_type, created_at) '
          "VALUES ('r1', 'default-tree', 'p1', 'p2', 'partner', 0)",
        );
      } finally {
        raw.close();
      }

      final migrated = AppDatabase.forTesting(NativeDatabase(File(path)));
      await migrated.customStatement('SELECT 1');

      // 'partner' is not a confirmed legacy value, so no relationship is
      // invented from it. The people survive.
      expect(await migrated.select(migrated.familiesV2).get(), isEmpty);
      expect(await migrated.select(migrated.genealogyPersons).get(), hasLength(2));

      await migrated.close();
    });
  });

  group('a migration that cannot complete changes nothing', () {
    test('an unmigratable legacy database keeps its version and its tables',
        () async {
      final path = pathFor('broken');
      await seedLegacyOnly(path, 11);

      final raw = sqlite.sqlite3.open(path);
      try {
        // Remove a column the import has to read, so the upgrade fails while
        // running. (A real ancient database would have it; this is a harness to
        // prove the failure path.)
        raw.execute('DROP TABLE persons');
        raw.execute('''
          CREATE TABLE persons (
            id TEXT NOT NULL, tree_id TEXT NOT NULL, full_name TEXT NOT NULL,
            gender TEXT NOT NULL, created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL, PRIMARY KEY (id)
          )
        ''');
        raw.execute(
          'INSERT INTO persons (id, tree_id, full_name, gender, created_at, '
          "updated_at) VALUES ('p1', 'default-tree', 'P1', 'M', 0, 0)",
        );
      } finally {
        raw.close();
      }

      final broken = AppDatabase.forTesting(NativeDatabase(File(path)));
      Object? failure;
      try {
        await broken.customStatement('SELECT 1');
      } catch (error) {
        failure = error;
      }
      try {
        await broken.close();
      } catch (_) {
        // the connection may already be unusable
      }
      expect(failure, isNotNull, reason: 'the upgrade must fail');

      final probe = sqlite.sqlite3.open(path);
      try {
        final version =
            probe.select('PRAGMA user_version').first.values.first as int;
        final tables = probe
            .select("SELECT name FROM sqlite_master WHERE type = 'table'")
            .map((row) => row['name'] as String)
            .toSet();
        final people = probe.select('SELECT COUNT(*) AS c FROM persons')
            .first['c'] as int;

        expect(version, 11, reason: 'the version is not advanced');
        expect(
          tables,
          contains('persons'),
          reason: 'the legacy table is still there',
        );
        expect(
          tables,
          isNot(contains('sync_change_log')),
          reason: 'nothing later in the routine ran',
        );
        expect(people, 1, reason: 'the legacy rows are untouched');
      } finally {
        probe.close();
      }
    });
  });
}

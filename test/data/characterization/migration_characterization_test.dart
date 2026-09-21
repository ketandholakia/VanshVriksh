// CHARACTERIZATION TESTS — H1 / H2 (v9 -> v10 -> v11 migration).
//
// These tests document CURRENT, INCORRECT migration behaviour. They are
// expected to FAIL after the Phase 2 migration fix and must be updated then.
//
// H1  _migrateLegacyRelationshipsToFamilies() selects legacy spouse rows with
//     `relationshipType == 'marriage'`, but the legacy contract for the
//     `relationships` table is `parent_child` | `spouse`
//     (lib/core/constants/relationship_types.dart). The v10 step then drops the
//     `relationships` table, so legacy marriages are deleted, not migrated.
//     The test below demonstrates this as an A/B: the same fixture with
//     `'spouse'` loses the marriage, with `'marriage'` it survives.
// H2  The single-parent branch looks a family up with
//     `husbandId = p1 OR wifeId = p1` and calls `getSingleOrNull()`. A parent
//     with two families makes that query return two rows, and drift's
//     getSingleOrNull() throws (StateError: Too many elements).
//     Two further facts make this worse than a crash, and both are asserted
//     below:
//       * onUpgrade is NOT executed inside a transaction by drift
//         (drift 2.33.0 `lib/src/runtime/api/db_base.dart:116-142` calls
//         `_resolvedMigration.onUpgrade(...)` directly), so the families and
//         child links created before the throw REMAIN COMMITTED while
//         `user_version` stays at 9;
//       * the second launch therefore reaches the `if (familyTotal > 0) return;`
//         guard at the top of _migrateLegacyRelationshipsToFamilies and silently
//         completes the migration with the unresolved links missing — and the
//         legacy tables are dropped in the same run, so the missing data is
//         unrecoverable.
//     Net effect: the first launch after such an upgrade shows a database
//     initialisation error, and the second launch silently loses parent links.
//
// Fixture note: the database is created by the CURRENT schema (createAll) and
// then has its `user_version` forced back to 9, so only the migration logic is
// exercised. This is a migration-path harness, not a byte-accurate v9 file;
// real v9 databases have older column sets in events/media_items/research_notes
// /todos. The tables H1/H2 actually depend on (relationships, persons,
// genealogy_persons, families_v2, family_children_v2) use their real shapes.
//
// Source under test:
//   lib/data/database/app_database.dart:142-235 (_migrateLegacyRelationshipsToFamilies)
//   lib/data/database/app_database.dart:153     (the 'marriage' filter)
//   lib/data/database/app_database.dart:190-200 (ambiguous lookup)
//   lib/data/database/app_database.dart:130-135 (DROP TABLE relationships)

import 'dart:io';

// `isNull` / `isNotNull` are also exported by drift as query expressions, so
// they are hidden here to keep the matcher versions unambiguous.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// Transitive dependency of drift; used only to inspect user_version on a file
// WITHOUT re-triggering the app's migration logic.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:vanshvriksh/data/database/app_database.dart';

/// Legacy relationship rows to seed, as (personId, relatedPersonId, type).
typedef _LegacyRel = (String, String, String);

void main() {
  late Directory tempDir;
  late String dbPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vv_migration_char_');
    dbPath = '${tempDir.path}${Platform.pathSeparator}vanshvriksh.sqlite';
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {
      // ignore: temp dir cleanup is best effort
    }
  });

  /// Creates a v11 database, seeds the legacy tables, then rewinds
  /// `user_version` to 9 so that opening it runs onUpgrade(9, 11).
  Future<void> seedLegacyDatabase({
    required List<String> personIds,
    required List<_LegacyRel> relationships,
  }) async {
    // 1. Let the app create its current schema.
    final setup = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    final now = DateTime.now();
    await setup.into(setup.familyTrees).insert(
          FamilyTreesCompanion.insert(
            id: 'tree-1',
            treeName: 'My Family',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 2. Legacy `persons` rows (the legacy `relationships` table has FKs into
    //    persons, and the v8 migration reused the same ids for
    //    genealogy_persons, so both tables carry the same ids).
    for (final id in personIds) {
      await setup.into(setup.persons).insert(
            PersonsCompanion.insert(
              id: id,
              treeId: 'tree-1',
              fullName: id,
              firstName: Value(id),
              // The legacy table's values are what H1 is about.
              gender: id == 'p2' ? 'female' : 'male',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await setup.into(setup.genealogyPersons).insert(
            GenealogyPersonsCompanion.insert(
              id: id,
              firstName: id,
              treeId: 'tree-1',
              gender: id == 'p2' ? 'female' : 'male',
              uuid: 'uuid-$id',
            ),
          );
    }

    // 3. Legacy relationship rows.
    var index = 0;
    for (final (personId, relatedPersonId, type) in relationships) {
      await setup.into(setup.relationships).insert(
            RelationshipsCompanion.insert(
              id: 'rel-${index++}',
              treeId: 'tree-1',
              personId: personId,
              relatedPersonId: relatedPersonId,
              relationshipType: type,
              createdAt: now,
            ),
          );
    }

    // 4. Rewind the schema version so the next open runs the migration.
    await setup.customStatement('PRAGMA user_version = 9');
    await setup.close();
  }

  /// Runs [body] against a plain SQLite connection, so that inspecting the file
  /// does not run (and re-fail) the app's migration.
  T inspectRaw<T>(T Function(sqlite.Database raw) body) {
    final raw = sqlite.sqlite3.open(dbPath);
    try {
      return body(raw);
    } finally {
      raw.close();
    }
  }

  int readUserVersion() => inspectRaw(
        (raw) =>
            raw.select('PRAGMA user_version').first.values.first! as int,
      );

  bool tableExists(String table) => inspectRaw(
        (raw) => raw
            .select(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
              [table],
            )
            .isNotEmpty,
      );

  int rowCount(String table) => inspectRaw((raw) {
        if (raw
            .select(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
              [table],
            )
            .isEmpty) {
          return -1;
        }
        return raw.select('SELECT COUNT(*) AS c FROM $table').first['c'] as int;
      });

  group('H1 — legacy spouse relationships', () {
    test(
      "legacy 'spouse' rows are NOT migrated and the table is dropped "
      '(data loss by wrong literal)',
      () async {
        await seedLegacyDatabase(
          personIds: ['p1', 'p2'],
          relationships: [('p1', 'p2', 'spouse')],
        );

        final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
        final families = await db.select(db.familiesV2).get();
        final tables = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name = 'relationships'",
            )
            .get();
        await db.close();

        expect(
          families,
          isEmpty,
          reason: 'the marriage was dropped instead of migrated',
        );
        expect(
          tables,
          isEmpty,
          reason: 'the legacy relationships table is gone, so the data is '
              'unrecoverable',
        );
      },
    );

    test(
      "the same fixture with 'marriage' DOES migrate (A/B proof that the "
      'filter literal is the defect)',
      () async {
        await seedLegacyDatabase(
          personIds: ['p1', 'p2'],
          relationships: [('p1', 'p2', 'marriage')],
        );

        final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
        final families = await db.select(db.familiesV2).get();
        await db.close();

        expect(families.length, 1);
        expect(families.single.husbandId, 'p1');
        expect(families.single.wifeId, 'p2');
      },
    );

    test('parent_child rows ARE migrated (control case)', () async {
      await seedLegacyDatabase(
        personIds: ['p1', 'childA'],
        relationships: [('p1', 'childA', 'parent_child')],
      );

      final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      final families = await db.select(db.familiesV2).get();
      final links = await db.select(db.familyChildrenV2).get();
      await db.close();

      expect(families.length, 1);
      expect(links.length, 1);
      expect(links.single.childId, 'childA');
    });
  });

  group('H2 — ambiguous family lookup during migration', () {
    // p1 has childA with no mother recorded, childB with p2, and childC with no
    // mother recorded. Migrating childB creates a second family for p1, so the
    // single-parent lookup for childC matches two rows and
    // `getSingleOrNull()` throws (StateError: Too many elements).
    Future<void> seedAmbiguous() => seedLegacyDatabase(
          personIds: ['p1', 'p2', 'childA', 'childB', 'childC'],
          relationships: [
            ('p1', 'childA', 'parent_child'),
            ('p1', 'childB', 'parent_child'),
            ('p2', 'childB', 'parent_child'),
            ('p1', 'childC', 'parent_child'),
          ],
        );

    /// Opens the database and reports the error thrown by the first query.
    Future<Object?> attemptOpen() async {
      final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      Object? failure;
      try {
        await db.select(db.genealogyPersons).get();
      } catch (error) {
        failure = error;
      }
      try {
        await db.close();
      } catch (_) {
        // the connection may already be broken
      }
      return failure;
    }

    test('a parent with two families aborts the migration', () async {
      await seedAmbiguous();

      final failure = await attemptOpen();

      expect(failure, isNotNull);
      expect(failure, isA<StateError>());
      expect(
        failure.toString(),
        contains('Too many elements'),
        reason: 'drift getSingleOrNull() -> list.single on a 2-row result',
      );
    });

    test(
      'the aborted migration has ALREADY committed the work it did first '
      '(onUpgrade is not atomic)',
      () async {
        await seedAmbiguous();
        expect(rowCount('families_v2'), 0, reason: 'fixture starts clean');

        await attemptOpen();

        expect(
          rowCount('families_v2'),
          2,
          reason: 'families created for childA and childB survived the throw',
        );
        expect(rowCount('family_children_v2'), 2);
        expect(
          rowCount('relationships'),
          4,
          reason: 'the legacy source table is still there',
        );
        expect(
          readUserVersion(),
          9,
          reason: 'the version is only written after onUpgrade returns, so the '
              'upgrade is retried on the next launch',
        );
      },
    );

    test(
      'the next open "succeeds" because families_v2 is no longer empty, and '
      'silently finishes the migration with the unresolved links lost',
      () async {
        await seedAmbiguous();

        expect(await attemptOpen(), isNotNull, reason: 'first launch fails');
        final secondFailure = await attemptOpen();

        expect(
          secondFailure,
          isNull,
          reason: 'the guard `if (familyTotal > 0) return;` now short-circuits '
              'the migration instead of resolving the ambiguity',
        );
        expect(readUserVersion(), 11);

        // childC's parent link was never created: 3 children, 2 links.
        expect(rowCount('family_children_v2'), 2);
        expect(rowCount('genealogy_persons'), 5);

        // ...and the legacy tables are now gone, so the missing link cannot be
        // recovered from the original data.
        expect(tableExists('relationships'), isFalse);
        expect(tableExists('persons'), isFalse);
      },
    );
  });
}

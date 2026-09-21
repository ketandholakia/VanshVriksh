// Permanent schema verification.
//
// Two things are checked:
//   1. a brand-new database is exactly the schema this project declares
//      (`test/support/schema_expectations.dart`);
//   2. every migrated database ends up as exactly that schema too — including a
//      sparse legacy database that has to have almost every table created.
//
// Comparing a fresh database with a migrated one alone would only prove they
// agree; these tests prove both are the schema we intend, so a lost index, a
// dropped foreign key or a silently changed default fails the suite.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';

import '../support/legacy_fixtures.dart';
import '../support/schema_expectations.dart';
import '../support/schema_verification.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vv_schema_');
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

  group('a brand-new database', () {
    test('is exactly the declared canonical schema', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customStatement('SELECT 1');

      await expectCanonicalSchema(db, because: 'fresh database');

      await db.close();
    });
  });

  group('a migrated database ends up as the declared schema', () {
    test('from the previous version (v12)', () async {
      final path = pathFor('from12');
      final setup = AppDatabase.forTesting(NativeDatabase(File(path)));
      await setup.customStatement('SELECT 1');
      await setup.close();

      final raw = File(path);
      expect(raw.existsSync(), isTrue);
      final downgrade = AppDatabase.forTesting(NativeDatabase(File(path)));
      await downgrade.customStatement('PRAGMA user_version = 12');
      await downgrade.close();

      final migrated = await openAndUpgrade(path);
      await expectCanonicalSchema(migrated, because: 'migrated from v12');
      await migrated.close();

      expect(storedUserVersion(path), expectedSchemaVersion);
    });

    test('from v11', () async {
      final path = pathFor('from11');
      await seedLegacyDatabase(path, version: 11);

      final migrated = await openAndUpgrade(path);
      await expectCanonicalSchema(migrated, because: 'migrated from v11');
      await migrated.close();
    });

    test('from a sparse legacy database (v7)', () async {
      final path = pathFor('from7');
      await seedLegacyDatabase(path, version: 7);

      final migrated = await openAndUpgrade(path);
      await expectCanonicalSchema(
        migrated,
        because: 'migrated from a database with no canonical tables',
      );
      await migrated.close();
    });

    test('from a legacy database that carries data', () async {
      final path = pathFor('legacywithdata');
      await seedLegacyDatabase(
        path,
        version: 9,
        people: [
          (
            id: 'p1',
            gender: 'male',
            firstName: 'Ram',
            lastName: 'Patel',
            birthSurname: 'Patel',
            marriedSurname: null,
          ),
          (
            id: 'p2',
            gender: 'female',
            firstName: 'Sita',
            lastName: 'Patel',
            birthSurname: 'Shah',
            marriedSurname: 'Patel',
          ),
          (
            id: 'c1',
            gender: 'male',
            firstName: 'Kid',
            lastName: 'Patel',
            birthSurname: 'Patel',
            marriedSurname: null,
          ),
        ],
        relationships: [
          ('p1', 'p2', 'spouse'),
          ('p1', 'c1', 'parent_child'),
          ('p2', 'c1', 'parent_child'),
        ],
      );

      final migrated = await openAndUpgrade(path);
      await expectCanonicalSchema(migrated, because: 'migrated with data');

      // The imported data is still there and still connected.
      expect(await migrated.select(migrated.genealogyPersons).get(), hasLength(3));
      final families = await migrated.select(migrated.familiesV2).get();
      final links = await migrated.select(migrated.familyChildrenV2).get();
      expect(families, hasLength(1), reason: 'the couple');
      expect(links, hasLength(1), reason: 'the child');
      expect(links.single.familyId, families.single.id);

      await migrated.close();
    });
  });

  group('fresh and migrated are structurally equivalent', () {
    test('their fingerprints are identical', () async {
      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      await fresh.customStatement('SELECT 1');
      final freshFingerprint = await schemaFingerprint(fresh);
      await fresh.close();

      for (final entry in {
        'v12': 12,
        'v11': 11,
        'v7': 7,
      }.entries) {
        final path = pathFor('fingerprint-${entry.key}');
        await seedLegacyDatabase(path, version: entry.value);
        final migrated = await openAndUpgrade(path);
        expect(
          await schemaFingerprint(migrated),
          freshFingerprint,
          reason: 'migrated from v${entry.value}',
        );
        await migrated.close();
      }
    });
  });
}

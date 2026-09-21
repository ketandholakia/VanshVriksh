// Tests for the v11 → v12 upgrade into the canonical model.
//
// These replace `migration_characterization_test.dart`, which documented two
// defects: legacy `'spouse'` rows were dropped (the filter only accepted
// `'marriage'`) and an ambiguous parent lookup aborted the upgrade halfway,
// leaving committed partial work behind. Both are fixed by the rewritten
// migration, so the assertions below describe the intended behaviour.
//
// The fixture is a real file-backed database: the canonical schema is created,
// the legacy tables are then injected with plain SQL exactly as an old database
// would have them, `user_version` is rewound to 11, and the file is reopened so
// that `onUpgrade(11, 12)` runs for real.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// Transitive dependency of drift; used to build the legacy fixture without
// touching the app's own migration logic.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:vanshvriksh/data/database/app_database.dart';

/// The `persons` / `relationships` tables as they existed before schema v10.
const _legacySchema = <String>[
  '''
  CREATE TABLE persons (
    id TEXT NOT NULL,
    tree_id TEXT NOT NULL,
    full_name TEXT NOT NULL,
    first_name TEXT,
    middle_name TEXT,
    last_name TEXT,
    birth_surname TEXT,
    married_surname TEXT,
    prefix TEXT,
    suffix TEXT,
    nickname TEXT,
    gender TEXT NOT NULL,
    birth_date INTEGER,
    birth_date_display TEXT,
    birth_date_sort REAL,
    death_date INTEGER,
    death_date_display TEXT,
    death_date_sort REAL,
    birth_place TEXT,
    current_place TEXT,
    profile_photo_path TEXT,
    bio TEXT,
    notes TEXT,
    private INTEGER NOT NULL DEFAULT 0,
    is_living INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (id)
  )
  ''',
  '''
  CREATE TABLE relationships (
    id TEXT NOT NULL,
    tree_id TEXT NOT NULL,
    person_id TEXT NOT NULL,
    related_person_id TEXT NOT NULL,
    relationship_type TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (id)
  )
  ''',
];

typedef _LegacyPerson = ({
  String id,
  String gender,
  String? firstName,
  String? lastName,
  String? birthSurname,
  String? marriedSurname,
});

typedef _LegacyRel = (String personId, String relatedPersonId, String type);

void main() {
  late Directory tempDir;
  late String dbPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vv_migration_');
    dbPath = '${tempDir.path}${Platform.pathSeparator}vanshvriksh.sqlite';
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {
      // best effort
    }
  });

  /// Creates a database in the canonical shape, injects the legacy tables and
  /// rewinds `user_version` to 11.
  Future<void> seedLegacyDatabase({
    required List<_LegacyPerson> people,
    required List<_LegacyRel> relationships,
  }) async {
    final setup = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    await setup.customStatement('SELECT 1'); // open + createAll
    await setup.close();

    final raw = sqlite.sqlite3.open(dbPath);
    try {
      for (final statement in _legacySchema) {
        raw.execute(statement);
      }

      const createdAt = 1600000000; // seconds, as drift stores DateTimes
      final insertPerson = raw.prepare(
        'INSERT INTO persons (id, tree_id, full_name, first_name, last_name, '
        'birth_surname, married_surname, gender, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      );
      try {
        for (final person in people) {
          insertPerson.execute([
            person.id,
            'default-tree',
            [person.firstName, person.lastName]
                .whereType<String>()
                .join(' '),
            person.firstName,
            person.lastName,
            person.birthSurname,
            person.marriedSurname,
            person.gender,
            createdAt,
            createdAt,
          ]);
        }
      } finally {
        insertPerson.close();
      }

      final insertRel = raw.prepare(
        'INSERT INTO relationships (id, tree_id, person_id, related_person_id, '
        'relationship_type, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      );
      try {
        var index = 0;
        for (final (personId, relatedPersonId, type) in relationships) {
          insertRel.execute([
            'rel-${index++}',
            'default-tree',
            personId,
            relatedPersonId,
            type,
            createdAt,
          ]);
        }
      } finally {
        insertRel.close();
      }

      raw.execute('PRAGMA user_version = 11');
    } finally {
      raw.close();
    }
  }

  /// Opens the seeded file so the upgrade runs, then returns the database.
  Future<AppDatabase> openUpgraded() async {
    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    await db.customStatement('SELECT 1');
    return db;
  }

  int storedUserVersion() {
    final raw = sqlite.sqlite3.open(dbPath);
    try {
      return raw.select('PRAGMA user_version').first.values.first! as int;
    } finally {
      raw.close();
    }
  }

  Set<String> storedTables() {
    final raw = sqlite.sqlite3.open(dbPath);
    try {
      return raw
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((row) => row['name'] as String)
          .toSet();
    } finally {
      raw.close();
    }
  }

  Set<String> storedIndexes() {
    final raw = sqlite.sqlite3.open(dbPath);
    try {
      return raw
          .select("SELECT name FROM sqlite_master WHERE type = 'index'")
          .map((row) => row['name'] as String)
          .toSet();
    } finally {
      raw.close();
    }
  }

  group('legacy partner rows', () {
    test("'spouse' rows are migrated into a partnership", () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Ram', lastName: 'Patel', birthSurname: 'Patel', marriedSurname: null),
          (id: 'p2', gender: 'female', firstName: 'Sita', lastName: 'Patel', birthSurname: 'Shah', marriedSurname: 'Patel'),
        ],
        relationships: [('p1', 'p2', 'spouse')],
      );

      final db = await openUpgraded();
      final families = await db.select(db.familiesV2).get();
      await db.close();

      expect(families, hasLength(1));
      expect(families.single.husbandId, 'p1');
      expect(families.single.wifeId, 'p2');
      expect(families.single.treeId, 'default-tree');
    });

    test("the historical 'marriage' literal is migrated as well", () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Ram', lastName: null, birthSurname: null, marriedSurname: null),
          (id: 'p2', gender: 'female', firstName: 'Sita', lastName: null, birthSurname: null, marriedSurname: null),
        ],
        relationships: [('p1', 'p2', 'marriage')],
      );

      final db = await openUpgraded();
      final families = await db.select(db.familiesV2).get();
      await db.close();

      expect(families, hasLength(1));
      expect(families.single.husbandId, 'p1');
    });

    test('the partnership is stored once even when both directions exist',
        () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Ram', lastName: null, birthSurname: null, marriedSurname: null),
          (id: 'p2', gender: 'female', firstName: 'Sita', lastName: null, birthSurname: null, marriedSurname: null),
        ],
        relationships: [
          ('p1', 'p2', 'spouse'),
          ('p2', 'p1', 'marriage'),
        ],
      );

      final db = await openUpgraded();
      final families = await db.select(db.familiesV2).get();
      await db.close();

      expect(families, hasLength(1));
    });
  });

  group('legacy parent-child rows', () {
    test('a single parent becomes a single-parent family', () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Dad', lastName: null, birthSurname: null, marriedSurname: null),
          (id: 'c1', gender: 'male', firstName: 'Kid', lastName: null, birthSurname: null, marriedSurname: null),
        ],
        relationships: [('p1', 'c1', 'parent_child')],
      );

      final db = await openUpgraded();
      final families = await db.select(db.familiesV2).get();
      final links = await db.select(db.familyChildrenV2).get();
      await db.close();

      expect(families, hasLength(1));
      expect(families.single.husbandId, 'p1');
      expect(families.single.wifeId, isNull);
      expect(links, hasLength(1));
      expect(links.single.childId, 'c1');
    });

    test('two parents become one couple family', () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Dad', lastName: null, birthSurname: null, marriedSurname: null),
          (id: 'p2', gender: 'female', firstName: 'Mom', lastName: null, birthSurname: null, marriedSurname: null),
          (id: 'c1', gender: 'male', firstName: 'Kid', lastName: null, birthSurname: null, marriedSurname: null),
        ],
        relationships: [
          ('p1', 'c1', 'parent_child'),
          ('p2', 'c1', 'parent_child'),
        ],
      );

      final db = await openUpgraded();
      final families = await db.select(db.familiesV2).get();
      final links = await db.select(db.familyChildrenV2).get();
      await db.close();

      expect(families, hasLength(1));
      expect(families.single.husbandId, 'p1');
      expect(families.single.wifeId, 'p2');
      expect(links, hasLength(1));
    });

    test(
      'a parent with children from two partnerships no longer aborts the '
      'upgrade',
      () async {
        // This is the shape that used to throw StateError (Too many elements)
        // inside onUpgrade and leave the database at user_version 11.
        await seedLegacyDatabase(
          people: [
            (id: 'p1', gender: 'male', firstName: 'Dad', lastName: null, birthSurname: null, marriedSurname: null),
            (id: 'p2', gender: 'female', firstName: 'Mom', lastName: null, birthSurname: null, marriedSurname: null),
            (id: 'c1', gender: 'male', firstName: 'A', lastName: null, birthSurname: null, marriedSurname: null),
            (id: 'c2', gender: 'female', firstName: 'B', lastName: null, birthSurname: null, marriedSurname: null),
            (id: 'c3', gender: 'male', firstName: 'C', lastName: null, birthSurname: null, marriedSurname: null),
          ],
          relationships: [
            ('p1', 'c1', 'parent_child'),
            ('p1', 'c2', 'parent_child'),
            ('p2', 'c2', 'parent_child'),
            ('p1', 'c3', 'parent_child'),
          ],
        );

        final db = await openUpgraded();
        final people = await db.select(db.genealogyPersons).get();
        final links = await db.select(db.familyChildrenV2).get();
        final livingLinks =
            links.where((link) => !link.isDeleted).toList();
        await db.close();

        // Every person survived and every child kept a parent link.
        expect(people, hasLength(5));
        expect(
          livingLinks.map((link) => link.childId).toSet(),
          {'c1', 'c2', 'c3'},
        );
        expect(storedUserVersion(), 14);
      },
    );
  });

  group('legacy person rows', () {
    test('people are copied with their surname history', () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'female', firstName: 'Sita', lastName: 'Patel', birthSurname: 'Shah', marriedSurname: 'Patel'),
        ],
        relationships: const [],
      );

      final db = await openUpgraded();
      final person = (await db.select(db.genealogyPersons).get()).single;
      final surnames = await db.select(db.surnameEvents).get();
      await db.close();

      expect(person.id, 'p1');
      expect(person.firstName, 'Sita');
      expect(person.birthSurname, 'Shah');
      expect(person.marriedSurname, 'Patel');
      expect(person.treeId, 'default-tree');
      expect(person.isDeleted, isFalse);
      expect(
        surnames.map((s) => s.surnameType).toSet(),
        {'birth', 'marriage'},
      );
    });
  });

  group('the upgraded database is canonical', () {
    test('legacy tables are gone and the model tables remain', () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Ram', lastName: null, birthSurname: null, marriedSurname: null),
        ],
        relationships: const [],
      );

      final db = await openUpgraded();
      await db.close();

      final tables = storedTables();
      expect(tables, isNot(contains('persons')));
      expect(tables, isNot(contains('relationships')));
      expect(tables, contains('genealogy_persons'));
      expect(tables, contains('families_v2'));
    });

    test('an upgraded database has the same indexes as a fresh one', () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Ram', lastName: null, birthSurname: null, marriedSurname: null),
        ],
        relationships: const [],
      );

      final db = await openUpgraded();
      await db.close();

      final indexes = storedIndexes();
      for (final required in const [
        'idx_genealogy_persons_tree_id',
        'idx_families_v2_tree_id',
        'idx_families_v2_husband_id',
        'idx_events_person_id',
        'idx_duplicate_markers_person_b',
      ]) {
        expect(indexes, contains(required));
      }
    });

    test('people are anchored to a tree that exists', () async {
      await seedLegacyDatabase(
        people: [
          (id: 'p1', gender: 'male', firstName: 'Ram', lastName: null, birthSurname: null, marriedSurname: null),
        ],
        relationships: const [],
      );

      final db = await openUpgraded();
      final trees = await db.select(db.familyTrees).get();
      final people = await db.select(db.genealogyPersons).get();
      await db.close();

      expect(trees.map((t) => t.id), contains(people.single.treeId));
    });
  });
}

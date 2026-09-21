// CHARACTERIZATION TESTS — H3 / D4 / D7 and the FK graph behind C2.
//
// These tests document the CURRENT physical schema of a freshly created
// database. They are the baseline that the Phase 1/Phase 3 schema work must
// change; update them when the schema is fixed.
//
// Findings covered:
//   H3  A fresh database and a migrated database are physically different:
//       onCreate() only runs createAll(), while the named `idx_*` indexes are
//       created exclusively inside `if (from < 9)` in onUpgrade().
//   H3b createAll() builds all 15 tables, including `persons` and
//       `relationships`, which the v10 migration then DROPs.
//   D4  families_v2 has no tree ownership column.
//   D7  genealogy_persons.tree_id has no foreign key (the v1 schema did have
//       one on persons.tree_id / relationships.tree_id).
//   C2  Every person-referencing foreign key uses ON DELETE NO ACTION.
//   H5  Deleting a family tree succeeds silently and orphans its people.
//
// Source under test:
//   lib/data/database/app_database.dart:58-60   (onCreate: createAll)
//   lib/data/database/app_database.dart:96-121  (if (from < 9) CREATE INDEX)
//   lib/data/database/app_database.dart:130-135 (DROP TABLE persons/relationships)

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';

/// Tables a fresh database is expected to contain today.
const _expectedFreshTables = <String>{
  'citation_links',
  'citations',
  'duplicate_markers',
  'events',
  'families_v2',
  'family_children_v2',
  'family_trees',
  'genealogy_persons',
  'media_items',
  'persons',
  'relationships',
  'research_notes',
  'surname_events',
  'sync_change_log',
  'todos',
};

/// Tables the v10 migration drops, which nonetheless exist on a fresh install.
const _legacyTablesDroppedByMigration = <String>['persons', 'relationships'];

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<String>> objectNames(String type) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = '$type' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    return rows.map((r) => r.data['name'] as String).toList();
  }

  Future<List<String>> allIndexNames() async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' ORDER BY name",
        )
        .get();
    return rows.map((r) => r.data['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> foreignKeysOf(String table) async {
    final rows = await db.customSelect('PRAGMA foreign_key_list($table)').get();
    return rows.map((r) => r.data).toList();
  }

  Future<List<String>> columnsOf(String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.data['name'] as String).toList();
  }

  group('H3 — fresh database physical schema', () {
    test('contains all 15 tables, including the two the migration drops',
        () async {
      final tables = await objectNames('table');
      expect(tables.toSet(), _expectedFreshTables);

      for (final legacy in _legacyTablesDroppedByMigration) {
        expect(
          tables,
          contains(legacy),
          reason: 'createAll() still builds legacy table "$legacy"',
        );
      }
    });

    test('has NO named query indexes — every index is implicit', () async {
      final indexes = await allIndexNames();

      expect(indexes, isNotEmpty);
      expect(
        indexes.where((name) => name.startsWith('idx_')),
        isEmpty,
        reason:
            'onCreate() only runs createAll(); the idx_* indexes exist only '
            'inside onUpgrade() when from < 9',
      );
      expect(
        indexes.every((name) => name.startsWith('sqlite_autoindex_')),
        isTrue,
        reason: 'all indexes come from PRIMARY KEY / UNIQUE constraints',
      );
    });

    test('the query indexes the migration would create are absent', () async {
      // Spot-check the indexes the v9 migration block creates, on tables that
      // exist on a fresh database.
      final indexes = (await allIndexNames()).toSet();
      for (final expected in const [
        'idx_genealogy_persons_tree_id',
        'idx_families_v2_husband_id',
        'idx_families_v2_wife_id',
        'idx_family_children_v2_family_id',
        'idx_events_person_id',
      ]) {
        expect(
          indexes,
          isNot(contains(expected)),
          reason: '$expected is only created on the upgrade path',
        );
      }
    });
  });

  group('D4 / D7 — ownership columns', () {
    test('families_v2 has no tree ownership column', () async {
      final columns = await columnsOf('families_v2');
      expect(columns, contains('husband_id'));
      expect(columns, contains('wife_id'));
      expect(
        columns,
        isNot(contains('tree_id')),
        reason: 'family tree ownership is derived from people, not stored',
      );
    });

    test('genealogy_persons has no foreign keys at all', () async {
      expect(await foreignKeysOf('genealogy_persons'), isEmpty);
    });

    test('genealogy_persons.tree_id is an unconstrained TEXT column', () async {
      final columns = await db.customSelect('PRAGMA table_info(genealogy_persons)').get();
      final treeId = columns
          .map((r) => r.data)
          .firstWhere((c) => c['name'] == 'tree_id');

      expect(treeId['notnull'], 1);
      expect(
        treeId['pk'],
        0,
        reason: 'tree_id is part of no key and references no table',
      );
      expect(await foreignKeysOf('genealogy_persons'), isEmpty);
    });

    test('the legacy schema DID declare the tree foreign key (regression)', () async {
      // Contrast: the tables the v2 model replaced do declare the FK.
      final persons = await foreignKeysOf('persons');
      final relationships = await foreignKeysOf('relationships');

      expect(
        persons.map((fk) => fk['table']),
        contains('family_trees'),
        reason: 'legacy persons.tree_id REFERENCES family_trees(id)',
      );
      expect(
        relationships.map((fk) => fk['table']),
        contains('family_trees'),
        reason: 'legacy relationships.tree_id REFERENCES family_trees(id)',
      );
    });
  });

  group('C2 — foreign key delete actions', () {
    test('every person-referencing FK is ON DELETE NO ACTION', () async {
      const expected = {
        'events': ['genealogy_persons'],
        'media_items': ['genealogy_persons'],
        'research_notes': ['genealogy_persons'],
        'surname_events': ['genealogy_persons'],
        'todos': ['genealogy_persons'],
        'families_v2': ['genealogy_persons'],
        'family_children_v2': ['families_v2', 'genealogy_persons'],
      };

      for (final entry in expected.entries) {
        final fks = await foreignKeysOf(entry.key);
        expect(
          fks.map((fk) => fk['table']).toSet(),
          entry.value.toSet(),
          reason: 'FK targets of ${entry.key}',
        );
        for (final fk in fks) {
          expect(
            fk['on_delete'],
            'NO ACTION',
            reason: '${entry.key}.${fk['from']} does not cascade',
          );
        }
      }
    });

    test('child tables have no is_deleted column (blocks uniform soft delete)',
        () async {
      for (final table in const [
        'events',
        'media_items',
        'research_notes',
        'todos',
      ]) {
        expect(
          await columnsOf(table),
          isNot(contains('is_deleted')),
          reason: '$table cannot participate in a soft-delete policy yet',
        );
      }

      // ...while the v2 person/relationship tables DO have it, which is the
      // contradiction: the model is designed for soft delete, the delete path
      // is hard delete.
      for (final table in const [
        'genealogy_persons',
        'families_v2',
        'family_children_v2',
      ]) {
        expect(await columnsOf(table), contains('is_deleted'));
      }
    });
  });

  group('H5 — tree deletion', () {
    test('deleting a tree succeeds and silently orphans its people', () async {
      final repository = GenealogyRepository(db);
      final now = DateTime.now();

      await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              id: 'tree-1',
              treeName: 'My Family',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await repository.addPerson(
        treeId: 'tree-1',
        firstName: 'Orphan',
        gender: 'M',
      );

      // No FK on genealogy_persons.tree_id -> the delete is not refused.
      final deleted = await (db.delete(db.familyTrees)
            ..where((t) => t.id.equals('tree-1')))
          .go();

      expect(deleted, 1, reason: 'the tree row is gone');
      expect(
        (await db.select(db.familyTrees).get()).isEmpty,
        isTrue,
      );
      expect(
        (await repository.getPeopleByTree('tree-1')).length,
        1,
        reason: 'the person still points at the deleted tree',
      );
    });
  });
}

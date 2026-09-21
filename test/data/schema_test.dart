// Tests for the canonical schema: tables, ownership, foreign keys, delete
// actions, semantic uniqueness and indexes.
//
// These replace `schema_shape_characterization_test.dart`, which documented the
// pre-redesign shape (legacy tables on fresh installs, no ownership foreign
// keys, indexes only on the upgrade path).
//
// The schema is asserted from the physical database, not from the Dart table
// definitions, so a drift codegen mistake cannot hide.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

import '../support/test_database.dart';

/// The canonical model, and nothing else.
const _canonicalTables = <String>{
  'family_trees',
  'genealogy_persons',
  'families_v2',
  'family_children_v2',
  'events',
  'media_items',
  'research_notes',
  'todos',
  'surname_events',
  'duplicate_markers',
  'citations',
  'citation_links',
};

/// Indexes that must exist on **every** database, however it was created.
const _requiredIndexes = <String>[
  'idx_family_trees_root_person',
  'idx_genealogy_persons_tree_id',
  'idx_genealogy_persons_merged_into',
  'idx_families_v2_tree_id',
  'idx_families_v2_husband_id',
  'idx_families_v2_wife_id',
  'idx_family_children_v2_child_id',
  'idx_events_person_id',
  'idx_media_items_person_id',
  'idx_research_notes_person_id',
  'idx_todos_person_id',
  'idx_surname_events_person_id',
  'idx_duplicate_markers_person_b',
];

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;

  setUp(() async {
    db = await createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> tableNames() async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    return rows.map((r) => r.data['name'] as String).toSet();
  }

  Future<Set<String>> indexNames() async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_autoindex%'",
        )
        .get();
    return rows.map((r) => r.data['name'] as String).toSet();
  }

  Future<Map<String, ({String table, String onDelete})>> foreignKeysOf(
    String table,
  ) async {
    final rows = await db.customSelect('PRAGMA foreign_key_list($table)').get();
    return {
      for (final row in rows)
        row.data['from'] as String: (
          table: row.data['table'] as String,
          onDelete: row.data['on_delete'] as String,
        ),
    };
  }

  group('canonical table set', () {
    test('a fresh database contains exactly the canonical tables', () async {
      expect(await tableNames(), _canonicalTables);
    });

    test('the legacy tables and the unused sync log are gone', () async {
      final tables = await tableNames();
      expect(tables, isNot(contains('persons')));
      expect(tables, isNot(contains('relationships')));
      expect(tables, isNot(contains('sync_change_log')));
    });

    test('no sync/version bookkeeping columns remain', () async {
      for (final table in const [
        'genealogy_persons',
        'families_v2',
        'family_children_v2',
        'surname_events',
      ]) {
        final columns = await db.customSelect('PRAGMA table_info($table)').get();
        final names = columns.map((c) => c.data['name'] as String).toSet();
        expect(names, isNot(contains('sync_status')), reason: table);
        expect(names, isNot(contains('version')), reason: table);
        expect(names, isNot(contains('last_synced_at')), reason: table);
      }
    });
  });

  group('indexes are part of the schema', () {
    test('every required index exists on a fresh database', () async {
      final indexes = await indexNames();
      for (final required in _requiredIndexes) {
        expect(indexes, contains(required));
      }
    });
  });

  group('tree ownership', () {
    test('people are owned by a tree, enforced by a foreign key', () async {
      expect(
        await foreignKeysOf('genealogy_persons'),
        containsPair('tree_id', (table: 'family_trees', onDelete: 'RESTRICT')),
      );
    });

    test('families are owned by a tree, enforced by a foreign key', () async {
      expect(
        await foreignKeysOf('families_v2'),
        containsPair('tree_id', (table: 'family_trees', onDelete: 'RESTRICT')),
      );
    });

    test('child links own no tree of their own', () async {
      final columns = await db
          .customSelect('PRAGMA table_info(family_children_v2)')
          .get();
      final names = columns.map((c) => c.data['name'] as String).toSet();
      expect(names, isNot(contains('tree_id')));
      // Ownership path: family_id -> families_v2.tree_id (both mandatory).
      expect(
        await foreignKeysOf('family_children_v2'),
        containsPair('family_id', (table: 'families_v2', onDelete: 'RESTRICT')),
      );
    });

    test('the tree root is an optional pointer, validated not enforced',
        () async {
      // It is intentionally not a foreign key: it would close a cycle with
      // genealogy_persons.tree_id and drift would drop one of the constraints.
      final columns = await db
          .customSelect('PRAGMA table_info(family_trees)')
          .get();
      final root = columns
          .map((c) => c.data)
          .firstWhere((c) => c['name'] == 'root_person_id');
      expect(root['notnull'], 0);
      expect(
        await foreignKeysOf('family_trees'),
        isNot(contains('root_person_id')),
      );
    });
  });

  group('family and child foreign keys', () {
    test('partner slots reference people with RESTRICT', () async {
      final fks = await foreignKeysOf('families_v2');
      expect(
        fks,
        containsPair('husband_id', (table: 'genealogy_persons', onDelete: 'RESTRICT')),
      );
      expect(
        fks,
        containsPair('wife_id', (table: 'genealogy_persons', onDelete: 'RESTRICT')),
      );
    });

    test('child links reference family and person with RESTRICT', () async {
      final fks = await foreignKeysOf('family_children_v2');
      expect(
        fks,
        containsPair('child_id', (table: 'genealogy_persons', onDelete: 'RESTRICT')),
      );
    });

    test('person-scoped records reference their person with RESTRICT',
        () async {
      for (final table in const [
        'events',
        'media_items',
        'research_notes',
        'todos',
        'surname_events',
      ]) {
        expect(
          await foreignKeysOf(table),
          containsPair('person_id', (table: 'genealogy_persons', onDelete: 'RESTRICT')),
          reason: table,
        );
      }
    });

    test('auxiliary pointers clear instead of blocking', () async {
      final fks = await foreignKeysOf('surname_events');
      expect(
        fks,
        containsPair(
          'related_person_id',
          (table: 'genealogy_persons', onDelete: 'SET NULL'),
        ),
      );
      expect(
        fks,
        containsPair('related_event_id', (table: 'events', onDelete: 'SET NULL')),
      );
    });

    test('duplicate markers cascade with the pair they describe', () async {
      final fks = await foreignKeysOf('duplicate_markers');
      expect(
        fks,
        containsPair('person_a_id', (table: 'genealogy_persons', onDelete: 'CASCADE')),
      );
      expect(
        fks,
        containsPair('person_b_id', (table: 'genealogy_persons', onDelete: 'CASCADE')),
      );
      expect(fks, isNot(contains('tree_id')));
    });

    test('merge pointers clear instead of blocking', () async {
      expect(
        await foreignKeysOf('genealogy_persons'),
        containsPair(
          'merged_into_id',
          (table: 'genealogy_persons', onDelete: 'SET NULL'),
        ),
      );
    });
  });

  group('delete semantics the constraints enforce', () {
    test('a tree holding people cannot be deleted', () async {
      final now = DateTime.now();
      await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              id: 'tree-1',
              treeName: 'My Family',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final repository = GenealogyRepository(db);
      await repository.addPerson(
        treeId: 'tree-1',
        firstName: 'Anchored',
        gender: 'M',
      );

      await expectLater(
        (db.delete(db.familyTrees)..where((t) => t.id.equals('tree-1'))).go(),
        throwsA(
          predicate(
            (e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'a foreign key violation',
          ),
        ),
      );
    });

    test('a person that still has events cannot be hard-deleted', () async {
      final repository = GenealogyRepository(db);
      final id = await repository.addPerson(
        treeId: treeId,
        firstName: 'HasEvents',
        gender: 'M',
      );
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'event-1',
              personId: id,
              eventType: 'baptism',
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );

      await expectLater(
        (db.delete(db.genealogyPersons)..where((t) => t.id.equals(id))).go(),
        throwsA(
          predicate(
            (e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'a foreign key violation',
          ),
        ),
      );
    });

    test('a family that still has children cannot be deleted', () async {
      final repository = GenealogyRepository(db);
      final relationships = RelationshipRepository(db);
      final dad = await repository.addPerson(
        treeId: treeId,
        firstName: 'Dad',
        gender: 'M',
      );
      final kid = await repository.addPerson(
        treeId: treeId,
        firstName: 'Kid',
        gender: 'M',
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );
      final familyId = (await repository.getFamiliesForPerson(dad)).single.id;

      await expectLater(
        (db.delete(db.familiesV2)..where((t) => t.id.equals(familyId))).go(),
        throwsA(
          predicate(
            (e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'a foreign key violation',
          ),
        ),
      );
    });
  });

  group('semantic uniqueness', () {
    test('the same couple cannot be stored twice', () async {
      final repository = GenealogyRepository(db);
      final dad = await repository.addPerson(
        treeId: treeId,
        firstName: 'Dad',
        gender: 'M',
      );
      final mom = await repository.addPerson(
        treeId: treeId,
        firstName: 'Mom',
        gender: 'F',
      );

      Future<void> insertCouple(String id) => db.into(db.familiesV2).insert(
            FamiliesV2Companion.insert(
              id: id,
              treeId: treeId,
              husbandId: Value(dad),
              wifeId: Value(mom),
              uuid: 'uuid-$id',
            ),
          );

      await insertCouple('family-1');
      await expectLater(insertCouple('family-2'), throwsA(anything));
    });

    test('a child cannot appear twice in the same family', () async {
      final repository = GenealogyRepository(db);
      final dad = await repository.addPerson(
        treeId: treeId,
        firstName: 'Dad',
        gender: 'M',
      );
      final kid = await repository.addPerson(
        treeId: treeId,
        firstName: 'Kid',
        gender: 'M',
      );

      final familyId = await repository.createFamily(
        treeId: treeId,
        husbandId: dad,
      );
      await repository.addChildToFamily(familyId: familyId, childId: kid);
      expect(await repository.getChildrenForFamily(familyId), hasLength(1));

      await expectLater(
        db.into(db.familyChildrenV2).insert(
              FamilyChildrenV2Companion.insert(
                id: 'duplicate-link',
                familyId: familyId,
                childId: kid,
                uuid: 'uuid-duplicate-link',
              ),
            ),
        throwsA(anything),
      );
    });

    test('a duplicate marker is stored once per pair, in canonical order',
        () async {
      final repository = GenealogyRepository(db);
      final a = await repository.addPerson(
        treeId: treeId,
        firstName: 'Same',
        gender: 'M',
      );
      final b = await repository.addPerson(
        treeId: treeId,
        firstName: 'Same',
        gender: 'M',
      );

      await repository.markAsDuplicate(
        treeId: treeId,
        sourceId: a,
        targetId: b,
      );
      await repository.markAsDuplicate(
        treeId: treeId,
        sourceId: b,
        targetId: a,
      );

      final markers = await repository.getDuplicateMarkers(treeId);
      expect(markers, hasLength(1));
      expect(markers.single.personAId.compareTo(markers.single.personBId) < 0,
          isTrue);
    });

    test('a person cannot be marked as a duplicate of themselves', () async {
      final repository = GenealogyRepository(db);
      final id = await repository.addPerson(
        treeId: treeId,
        firstName: 'Solo',
        gender: 'M',
      );

      await expectLater(
        repository.markAsDuplicate(
          treeId: treeId,
          sourceId: id,
          targetId: id,
        ),
        throwsArgumentError,
      );
    });
  });
}

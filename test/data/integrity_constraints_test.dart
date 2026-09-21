// Database integrity: the constraints themselves, exercised directly.
//
// Every test here bypasses the repositories and talks to the database with raw
// drift inserts, updates and deletes. The point is to prove that corruption is
// prevented by the **schema**, not only by repository-level validation: if a
// future change removes a constraint, these tests fail even though every
// repository call still looks correct.
//
// The first group is the integrity matrix in executable form — the exact
// (column → parent table, delete action) map for every table in the model.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

import '../support/test_database.dart';

/// column -> (parent table, on delete, on update)
typedef FkMap = Map<String, ({String table, String onDelete, String onUpdate})>;

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;
  late GenealogyRepository people;
  late RelationshipRepository relationships;

  setUp(() async {
    db = await createTestDatabase();
    people = GenealogyRepository(db);
    relationships = RelationshipRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<FkMap> foreignKeysOf(String table) async {
    final rows = await db.customSelect('PRAGMA foreign_key_list($table)').get();
    return {
      for (final row in rows)
        row.data['from'] as String: (
          table: row.data['table'] as String,
          onDelete: row.data['on_delete'] as String,
          onUpdate: row.data['on_update'] as String,
        ),
    };
  }

  Future<String> addPerson({
    required String firstName,
    String gender = 'M',
    String tree = treeId,
  }) {
    return people.addPerson(
      treeId: tree,
      firstName: firstName,
      gender: gender,
    );
  }

  final isRejected = throwsA(anything);

  // ---------------------------------------------------------------------------
  group('the integrity matrix', () {
    test('genealogy_persons', () async {
      final fks = await foreignKeysOf('genealogy_persons');
      expect(
        fks['tree_id'],
        (table: 'family_trees', onDelete: 'RESTRICT', onUpdate: 'NO ACTION'),
        reason: 'mandatory tree ownership',
      );
      expect(
        fks['merged_into_id'],
        (table: 'genealogy_persons', onDelete: 'SET NULL', onUpdate: 'NO ACTION'),
        reason: 'merge pointer',
      );
      expect(fks, hasLength(2));
    });

    test('family_trees', () async {
      final fks = await foreignKeysOf('family_trees');
      expect(
        fks['root_person_id'],
        (table: 'genealogy_persons', onDelete: 'SET NULL', onUpdate: 'NO ACTION'),
      );
      expect(fks, hasLength(1));
    });

    test('families_v2', () async {
      final fks = await foreignKeysOf('families_v2');
      expect(
        fks['tree_id'],
        (table: 'family_trees', onDelete: 'RESTRICT', onUpdate: 'NO ACTION'),
      );
      expect(
        fks['husband_id'],
        (table: 'genealogy_persons', onDelete: 'RESTRICT', onUpdate: 'NO ACTION'),
      );
      expect(
        fks['wife_id'],
        (table: 'genealogy_persons', onDelete: 'RESTRICT', onUpdate: 'NO ACTION'),
      );
      expect(fks, hasLength(3));
    });

    test('family_children_v2', () async {
      final fks = await foreignKeysOf('family_children_v2');
      expect(
        fks['family_id'],
        (table: 'families_v2', onDelete: 'RESTRICT', onUpdate: 'NO ACTION'),
      );
      expect(
        fks['child_id'],
        (table: 'genealogy_persons', onDelete: 'RESTRICT', onUpdate: 'NO ACTION'),
      );
      expect(fks, hasLength(2));
    });

    test('person-scoped tables', () async {
      for (final table in const [
        'events',
        'media_items',
        'research_notes',
        'surname_events',
      ]) {
        expect(
          (await foreignKeysOf(table))['person_id'],
          (table: 'genealogy_persons', onDelete: 'RESTRICT', onUpdate: 'NO ACTION'),
          reason: table,
        );
      }

      final surname = await foreignKeysOf('surname_events');
      expect(
        surname['related_person_id'],
        (table: 'genealogy_persons', onDelete: 'SET NULL', onUpdate: 'NO ACTION'),
      );
      expect(
        surname['related_event_id'],
        (table: 'events', onDelete: 'SET NULL', onUpdate: 'NO ACTION'),
      );
      expect(surname, hasLength(3));
    });

    test('duplicate_markers', () async {
      final fks = await foreignKeysOf('duplicate_markers');
      expect(
        fks['person_a_id'],
        (table: 'genealogy_persons', onDelete: 'CASCADE', onUpdate: 'NO ACTION'),
      );
      expect(
        fks['person_b_id'],
        (table: 'genealogy_persons', onDelete: 'CASCADE', onUpdate: 'NO ACTION'),
      );
      expect(
        fks.containsKey('tree_id'),
        isFalse,
        reason: 'the tree is derived through the people, not stored twice',
      );
    });

    test('a family cannot be created in a tree that does not exist', () async {
      await expectLater(
        db.into(db.familiesV2).insert(
              FamiliesV2Companion.insert(
                id: 'f1',
                treeId: 'no-such-tree',
              ),
            ),
        isRejected,
      );
    });

    test('a family partner must exist', () async {
      await expectLater(
        db.into(db.familiesV2).insert(
              FamiliesV2Companion.insert(
                id: 'f1',
                treeId: treeId,
                husbandId: const Value('no-such-person'),
              ),
            ),
        isRejected,
      );
    });

    test('a family cannot be given a non-existent wife afterwards', () async {
      final husband = await addPerson(firstName: 'Ram');
      final familyId = await people.createFamily(
        treeId: treeId,
        husbandId: husband,
      );

      await expectLater(
        (db.update(db.familiesV2)..where((t) => t.id.equals(familyId))).write(
          const FamiliesV2Companion(wifeId: Value('no-such-person')),
        ),
        isRejected,
      );
      expect(
        (await db.select(db.familiesV2).get()).single.wifeId,
        isNull,
        reason: 'the rejected update changed nothing',
      );
    });

    test('a child link must reference an existing family and child', () async {
      final kid = await addPerson(firstName: 'Kid');
      final parent = await addPerson(firstName: 'Parent');
      final familyId = await people.createFamily(
        treeId: treeId,
        husbandId: parent,
      );

      await expectLater(
        db.into(db.familyChildrenV2).insert(
              FamilyChildrenV2Companion.insert(
                id: 'l1',
                familyId: 'no-such-family',
                childId: kid,
              ),
            ),
        isRejected,
      );
      await expectLater(
        db.into(db.familyChildrenV2).insert(
              FamilyChildrenV2Companion.insert(
                id: 'l2',
                familyId: familyId,
                childId: 'no-such-child',
              ),
            ),
        isRejected,
      );
    });

    test('person-scoped rows must reference an existing person', () async {
      final now = DateTime(2000);
      await expectLater(
        db.into(db.events).insert(
              EventsCompanion.insert(
                id: 'e1',
                personId: 'no-such-person',
                eventType: 'baptism',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        isRejected,
      );
      await expectLater(
        db.into(db.mediaItems).insert(
              MediaItemsCompanion.insert(
                id: 'm1',
                personId: 'no-such-person',
                filePath: '/tmp/x.jpg',
                mediaType: 'photo',
                createdAt: now,
              ),
            ),
        isRejected,
      );
      await expectLater(
        db.into(db.researchNotes).insert(
              ResearchNotesCompanion.insert(
                id: 'n1',
                personId: const Value('no-such-person'),
                noteText: 'x',
                createdAt: now,
              ),
            ),
        isRejected,
      );
      await expectLater(
        db.into(db.surnameEvents).insert(
              SurnameEventsCompanion.insert(
                id: 's1',
                personId: 'no-such-person',
                surname: 'Patel',
                surnameType: 'birth',
              ),
            ),
        isRejected,
      );
    });

    test('a duplicate marker must reference existing people', () async {
      final a = await addPerson(firstName: 'A');

      await expectLater(
        db.into(db.duplicateMarkers).insert(
              DuplicateMarkersCompanion.insert(
                id: 'd1',
                personAId: a,
                personBId: 'no-such-person',
                createdAt: DateTime(2000),
              ),
            ),
        isRejected,
      );
    });

    test('a merged person must point at an existing survivor', () async {
      final id = await addPerson(firstName: 'Ram');

      await expectLater(
        (db.update(db.genealogyPersons)..where((t) => t.id.equals(id))).write(
          const GenealogyPersonsCompanion(
            mergedIntoId: Value('no-such-person'),
          ),
        ),
        isRejected,
      );
    });

    test('a tree root must reference an existing person', () async {
      await expectLater(
        (db.update(db.familyTrees)..where((t) => t.id.equals(treeId))).write(
          const FamilyTreesCompanion(rootPersonId: Value('no-such-person')),
        ),
        isRejected,
      );
    });

    test('RESTRICT: a person referenced by a family cannot be deleted',
        () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );

      await expectLater(
        (db.delete(db.genealogyPersons)..where((t) => t.id.equals(dad))).go(),
        isRejected,
      );
    });

    test('RESTRICT: a family with child links cannot be deleted', () async {
      final parent = await addPerson(firstName: 'Parent');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: kid,
      );
      final familyId = (await relationships.getFamiliesForPerson(parent)).single.id;

      await expectLater(
        (db.delete(db.familiesV2)..where((t) => t.id.equals(familyId))).go(),
        isRejected,
      );
    });

    test('SET NULL: hard-deleting a person clears a tree root', () async {
      final root = await addPerson(firstName: 'Root');
      await (db.update(db.familyTrees)..where((t) => t.id.equals(treeId)))
          .write(FamilyTreesCompanion(rootPersonId: Value(root)));

      expect(
        (await db.select(db.familyTrees).get()).single.rootPersonId,
        root,
      );

      // The person has no other references, so the ROW can go.
      await (db.delete(db.genealogyPersons)..where((t) => t.id.equals(root))).go();

      expect((await db.select(db.familyTrees).get()).single.rootPersonId, isNull);
    });

    test('SET NULL: hard-deleting an event clears the surname event pointer',
        () async {
      final id = await addPerson(firstName: 'Ram');
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'e1',
              personId: id,
              eventType: 'baptism',
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );
      await db.into(db.surnameEvents).insert(
            SurnameEventsCompanion.insert(
              id: 's1',
              personId: id,
              surname: 'Patel',
              surnameType: 'birth',
              relatedEventId: const Value('e1'),
            ),
          );

      await (db.delete(db.events)..where((t) => t.id.equals('e1'))).go();

      expect(
        (await db.select(db.surnameEvents).get()).single.relatedEventId,
        isNull,
      );
      expect((await db.select(db.surnameEvents).get()).single.personId, id);
    });

    test('CASCADE: hard-deleting a person removes their duplicate markers',
        () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B');
      await people.markAsDuplicate(treeId: treeId, sourceId: a, targetId: b);
      expect(await db.select(db.duplicateMarkers).get(), hasLength(1));

      await (db.delete(db.genealogyPersons)..where((t) => t.id.equals(b))).go();

      expect(await db.select(db.duplicateMarkers).get(), isEmpty);
    });

    test('SET NULL: hard-deleting the survivor clears merged_into_id', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);
      expect(
        (await people.getPersonById(duplicate))!.mergedIntoId,
        survivor,
      );

      await (db.delete(db.genealogyPersons)
            ..where((t) => t.id.equals(survivor)))
          .go();

      final retired = (await people.getPersonById(duplicate))!;
      expect(retired.mergedIntoId, isNull);
      expect(retired.isDeleted, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  group('uniqueness constraints', () {
    test('two people cannot share a uuid', () async {
      final first = await addPerson(firstName: 'A');
      final existingUuid = (await people.getPersonById(first))!.uuid;

      await expectLater(
        db.into(db.genealogyPersons).insert(
              GenealogyPersonsCompanion.insert(
                id: 'different-id',
                firstName: 'A',
                treeId: treeId,
                gender: 'M',
                uuid: existingUuid,
              ),
            ),
        isRejected,
      );
    });

    test('the same couple cannot be recorded twice', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );

      await expectLater(
        db.into(db.familiesV2).insert(
              FamiliesV2Companion.insert(
                id: 'second-family',
                treeId: treeId,
                husbandId: Value(dad),
                wifeId: Value(mom),
              ),
            ),
        isRejected,
      );
    });

    test('a child cannot appear twice in the same family', () async {
      final parent = await addPerson(firstName: 'Parent');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: kid,
      );
      final familyId = (await relationships.getFamiliesForPerson(parent)).single.id;

      await expectLater(
        db.into(db.familyChildrenV2).insert(
              FamilyChildrenV2Companion.insert(
                id: 'second-link',
                familyId: familyId,
                childId: kid,
              ),
            ),
        isRejected,
      );
    });

    test('the same pair of people cannot be marked as duplicates twice',
        () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B');
      await people.markAsDuplicate(treeId: treeId, sourceId: a, targetId: b);

      // The repository normalises the order, but the constraint holds even for a
      // row inserted directly.
      await expectLater(
        db.into(db.duplicateMarkers).insert(
              DuplicateMarkersCompanion.insert(
                id: 'second-marker',
                personAId: a.compareTo(b) <= 0 ? a : b,
                personBId: a.compareTo(b) <= 0 ? b : a,
                createdAt: DateTime(2000),
              ),
            ),
        isRejected,
      );
    });

    test('a family needs a tree and a uuid', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO families_v2 (id, uuid) VALUES (?, ?)',
          ['f1', 'uf1'],
        ),
        isRejected,
      );
    });

    test('a child link needs a family, a child and a uuid', () async {
      final parent = await addPerson(firstName: 'Parent');
      final kid = await addPerson(firstName: 'Kid');
      final familyId = await people.createFamily(
        treeId: treeId,
        husbandId: parent,
      );

      await expectLater(
        db.customStatement(
          'INSERT INTO family_children_v2 (id, family_id, uuid) VALUES (?, ?, ?)',
          ['l1', familyId, 'ul1'],
        ),
        isRejected,
        reason: 'child_id is NOT NULL',
      );
      expect(await people.getPersonById(kid), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('indexes for foreign keys and query paths', () {
    test('every foreign-key column and query path is indexed', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name NOT LIKE 'sqlite_autoindex%'",
          )
          .get();
      final indexes = rows.map((r) => r.data['name'] as String).toSet();

      for (final expected in const [
        // Ownership and relationships
        'idx_genealogy_persons_tree_id',
        'idx_families_v2_tree_id',
        'idx_families_v2_husband_id',
        'idx_families_v2_wife_id',
        'idx_family_children_v2_child_id',
        // Person-scoped query paths
        'idx_events_person_id',
        'idx_media_items_person_id',
        'idx_research_notes_person_id',
        'idx_surname_events_person_id',
        // Auxiliary references
        'idx_surname_events_related_person_id',
        'idx_surname_events_related_event_id',
        'idx_family_trees_root_person',
        'idx_genealogy_persons_merged_into',
        'idx_duplicate_markers_person_b',
      ]) {
        expect(indexes, contains(expected));
      }
    });

    test('the unique constraints are backed by indexes', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'sqlite_autoindex%'",
          )
          .get();
      expect(
        rows.length,
        greaterThanOrEqualTo(6),
        reason: 'PK/UNIQUE auto-indexes across the model',
      );
    });
  });
}
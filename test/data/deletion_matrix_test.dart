// The deletion matrix: every delete / remove / purge operation the application
// offers, and exactly what each one is allowed to touch.
//
// Semantics under test
//   person      soft delete. The row is flagged and everything that references
//               it stays intact (so the delete is reversible); reads exclude
//               anything involving a deleted person. The person is detached
//               from the families they were a partner of: the family survives
//               for the surviving spouse and children, and a family left with no
//               partner is retired with its child links.
//   family      soft delete ("dissolve"). Refused while the family still has
//               live child links unless the caller says to remove them too.
//   child link  soft delete of the link alone. Never touches the child, the
//               parent or the family.
//   tree        the only destructive operation. Deleting an empty tree is a row
//               delete; a populated tree is refused unless it is purged, and a
//               purge removes every owned record in one transaction.
//
// Cross-checks: invalid ids, repeated deletions and direct SQL deletes that the
// foreign keys must reject.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/family_tree_repository.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

import '../support/test_database.dart';

void main() {
  const treeId = 'default-tree';
  const otherTreeId = 'other-tree';

  late AppDatabase db;
  late GenealogyRepository people;
  late RelationshipRepository relationships;
  late FamilyTreeRepository trees;

  setUp(() async {
    db = await createTestDatabase();
    people = GenealogyRepository(db);
    relationships = RelationshipRepository(db);
    trees = FamilyTreeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> addPerson({
    required String firstName,
    String gender = 'M',
    String tree = treeId,
    String? profilePhotoPath,
  }) {
    return people.addPerson(
      treeId: tree,
      firstName: firstName,
      gender: gender,
      profilePhotoPath: profilePhotoPath,
    );
  }

  /// dad + mom (partners) with one child, in the default tree.
  Future<({String dad, String mom, String kid, String familyId, String linkId})>
      coupleWithChild() async {
    final dad = await addPerson(firstName: 'Dad');
    final mom = await addPerson(firstName: 'Mom', gender: 'F');
    final kid = await addPerson(firstName: 'Kid');
    await relationships.addSpouseRelationship(
      treeId: treeId,
      personAId: dad,
      personBId: mom,
    );
    final familyId = (await people.getFamiliesForPerson(dad)).single.id;
    await people.addChildToFamily(familyId: familyId, childId: kid);
    final linkId = (await people.getChildrenForFamily(familyId)).single.id;
    return (dad: dad, mom: mom, kid: kid, familyId: familyId, linkId: linkId);
  }

  Future<void> addOtherTree() async {
    final now = DateTime.now();
    await db.into(db.familyTrees).insert(
          FamilyTreesCompanion.insert(
            id: otherTreeId,
            treeName: 'Another tree',
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  // ---------------------------------------------------------------------------
  group('person deletion is a soft delete', () {
    test('an unknown person is reported', () async {
      await expectLater(people.deletePerson('ghost'), throwsArgumentError);
    });

    test('repeated deletion is a no-op', () async {
      final id = await addPerson(firstName: 'Solo');

      await people.deletePerson(id);
      await people.deletePerson(id);

      expect((await people.getPersonById(id))!.isDeleted, isTrue);
      expect(await people.getPeopleByTree(treeId), isEmpty);
    });

    test('the row survives, flagged, and no other row is destroyed', () async {
      final family = await coupleWithChild();
      final before = (
        persons: (await db.select(db.genealogyPersons).get()).length,
        families: (await db.select(db.familiesV2).get()).length,
        links: (await db.select(db.familyChildrenV2).get()).length,
      );

      await people.deletePerson(family.kid);

      expect((await people.getPersonById(family.kid))!.isDeleted, isTrue);
      expect(
        (await db.select(db.genealogyPersons).get()).length,
        before.persons,
        reason: 'nothing is hard-deleted',
      );
      expect((await db.select(db.familiesV2).get()).length, before.families);
      expect((await db.select(db.familyChildrenV2).get()).length, before.links);
    });

    test('a partner is detached and the family survives for the spouse',
        () async {
      final family = await coupleWithChild();

      await people.deletePerson(family.dad);

      // The family stays live, now with a single recorded partner.
      final familyRow = (await db.select(db.familiesV2).get()).single;
      expect(familyRow.isDeleted, isFalse);
      expect(familyRow.husbandId, isNull);
      expect(familyRow.wifeId, family.mom);

      final partnerships = await relationships.getPartnerships(treeId);
      expect(partnerships, hasLength(1));
      expect(partnerships.single.partnerIds, [family.mom]);

      // The child keeps the living parent and loses the removed one.
      expect(
        (await relationships.getParents(family.kid)).map((p) => p.id),
        [family.mom],
      );
      expect((await relationships.getChildren(family.mom)).single.id, family.kid);
    });

    test('a person who is a child is hidden from every lookup, and the link '
        'row is left intact so the delete is reversible', () async {
      final family = await coupleWithChild();

      await people.deletePerson(family.kid);

      final link = (await db.select(db.familyChildrenV2).get()).single;
      expect(
        link.isDeleted,
        isFalse,
        reason: 'only the person is flagged, nothing else',
      );
      expect(await relationships.getChildren(family.dad), isEmpty);
      expect(await relationships.getChildren(family.mom), isEmpty);
      expect(await relationships.getSiblings(family.kid), isEmpty);
    });

    test('the only parent of a family retires that family and its links',
        () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      await people.deletePerson(dad);

      expect((await db.select(db.familiesV2).get()).single.isDeleted, isTrue);
      expect(
        (await db.select(db.familyChildrenV2).get()).single.isDeleted,
        isTrue,
      );
      expect((await people.getPersonById(kid))!.isDeleted, isFalse);
    });

    test('person-scoped records are kept and become unreachable', () async {
      final id = await addPerson(firstName: 'HasEverything');
      final now = DateTime(2000);
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'event-1',
              personId: id,
              eventType: 'baptism',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media-1',
              personId: id,
              filePath: '/tmp/photo.jpg',
              mediaType: 'photo',
              createdAt: now,
            ),
          );
      await db.into(db.researchNotes).insert(
            ResearchNotesCompanion.insert(
              id: 'note-1',
              personId: Value(id),
              noteText: 'check the register',
              createdAt: now,
            ),
          );

      await people.deletePerson(id);

      expect((await db.select(db.events).get()).single.personId, id);
      expect((await db.select(db.mediaItems).get()).single.personId, id);
      expect((await db.select(db.researchNotes).get()).single.personId, id);
      expect(await people.getPeopleByTree(treeId), isEmpty);
      expect(
        await people.searchPeople(treeId: treeId, query: 'HasEverything'),
        isEmpty,
      );
    });

    test('restore brings the person back and the tree stays coherent',
        () async {
      final family = await coupleWithChild();
      await people.deletePerson(family.dad);

      await people.restorePerson(family.dad);

      expect((await people.getPersonById(family.dad))!.isDeleted, isFalse);
      expect((await people.getPeopleByTree(treeId)), hasLength(3));
      // The partner slot was cleared by the delete and is not rebuilt, so the
      // person is back in the tree without inventing a relationship.
      final partnerships = await relationships.getPartnerships(treeId);
      expect(partnerships.single.partnerIds, [family.mom]);
      expect((await relationships.getParents(family.kid)).map((p) => p.id),
          [family.mom]);
    });

    test('a merged person cannot be deleted or restored', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      await expectLater(people.deletePerson(duplicate), throwsStateError);
      await expectLater(people.restorePerson(duplicate), throwsStateError);
      expect((await people.getPersonById(duplicate))!.mergedIntoId, survivor);
    });

    test('the merge record survives a delete of the survivor', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      await people.deletePerson(survivor);

      final merged = (await people.getPersonById(duplicate))!;
      expect(merged.isDeleted, isTrue);
      expect(merged.mergedIntoId, survivor);
      expect((await people.getPersonById(survivor))!.isDeleted, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  group('family deletion (dissolve)', () {
    test('a childless family dissolves', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final familyId = (await people.getFamiliesForPerson(dad)).single.id;

      expect(await relationships.dissolveFamily(familyId), 1);
      expect((await db.select(db.familiesV2).get()).single.isDeleted, isTrue);
      expect(await relationships.getSpouses(dad), isEmpty);
      // People are untouched.
      expect((await people.getPeopleByTree(treeId)), hasLength(2));
    });

    test('dissolving twice is idempotent', () async {
      final dad = await addPerson(firstName: 'Dad');
      final familyId = await people.createFamily(
        treeId: treeId,
        husbandId: dad,
      );

      expect(await relationships.dissolveFamily(familyId), 1);
      expect(await relationships.dissolveFamily(familyId), 0);
    });

    test('an unknown family is reported', () async {
      await expectLater(
        relationships.dissolveFamily('ghost'),
        throwsArgumentError,
      );
    });

    test('a family with children is refused, and nothing changes', () async {
      final family = await coupleWithChild();

      await expectLater(
        relationships.dissolveFamily(family.familyId),
        throwsStateError,
      );

      expect((await db.select(db.familiesV2).get()).single.isDeleted, isFalse);
      expect(
        (await db.select(db.familyChildrenV2).get()).single.isDeleted,
        isFalse,
      );
      expect(await relationships.getChildren(family.dad), hasLength(1));
    });

    test('a family with children dissolves only with an explicit instruction, '
        'and still never deletes a person', () async {
      final family = await coupleWithChild();

      expect(
        await relationships.dissolveFamily(
          family.familyId,
          removeChildLinks: true,
        ),
        1,
      );

      expect((await db.select(db.familiesV2).get()).single.isDeleted, isTrue);
      expect(
        (await db.select(db.familyChildrenV2).get()).single.isDeleted,
        isTrue,
      );
      expect((await people.getPeopleByTree(treeId)), hasLength(3));
      expect((await people.getPersonById(family.kid))!.isDeleted, isFalse);
      expect((await people.getPersonById(family.dad))!.isDeleted, isFalse);
      expect((await people.getPersonById(family.mom))!.isDeleted, isFalse);
    });

    test('a single-parent family with children is refused like any other',
        () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );
      final familyId = (await people.getFamiliesForPerson(dad)).single.id;

      await expectLater(
        relationships.dissolveFamily(familyId),
        throwsStateError,
      );
      expect((await db.select(db.familiesV2).get()).single.isDeleted, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  group('child-link deletion', () {
    test('removing a link touches nothing but the link', () async {
      final family = await coupleWithChild();

      expect(await relationships.removeParentChildLink(family.linkId), 1);

      final link = (await db.select(db.familyChildrenV2).get()).single;
      expect(link.isDeleted, isTrue);
      expect((await db.select(db.familiesV2).get()).single.isDeleted, isFalse);
      expect((await people.getPeopleByTree(treeId)), hasLength(3));
      expect((await people.getPersonById(family.kid))!.isDeleted, isFalse);
      expect(await relationships.getChildren(family.dad), isEmpty);
    });

    test('removing twice reports nothing removed', () async {
      final family = await coupleWithChild();

      expect(await relationships.removeParentChildLink(family.linkId), 1);
      expect(await relationships.removeParentChildLink(family.linkId), 0);
    });

    test('an unknown link reports 0', () async {
      expect(await relationships.removeParentChildLink('ghost'), 0);
    });

    test('re-adding restores the same row instead of duplicating it', () async {
      final family = await coupleWithChild();
      await relationships.removeParentChildLink(family.linkId);

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: family.dad,
        childId: family.kid,
      );

      final links = await db.select(db.familyChildrenV2).get();
      expect(links, hasLength(1));
      expect(links.single.isDeleted, isFalse);
      expect(await relationships.getChildren(family.dad), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  group('tree deletion', () {
    test('an empty tree is deleted', () async {
      final now = DateTime.now();
      await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              id: 'empty-tree',
              treeName: 'Empty',
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(await trees.deleteFamilyTree('empty-tree'), 1);
      expect(await trees.getFamilyTreeById('empty-tree'), isNull);
    });

    test('a tree holding people refuses plain deletion and says why', () async {
      await coupleWithChild();

      await expectLater(
        trees.deleteFamilyTree(treeId),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('3 people'), contains('1 families')),
          ),
        ),
      );
      expect(await trees.getFamilyTreeById(treeId), isNotNull);
    });

    test('the purge preview counts every owned record', () async {
      final family = await coupleWithChild();
      final now = DateTime(2000);
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'event-1',
              personId: family.kid,
              eventType: 'baptism',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media-1',
              personId: family.kid,
              filePath: '/tmp/kid.jpg',
              mediaType: 'photo',
              createdAt: now,
            ),
          );
      await db.into(db.researchNotes).insert(
            ResearchNotesCompanion.insert(
              id: 'note-1',
              personId: Value(family.kid),
              noteText: 'note',
              createdAt: now,
            ),
          );
      await db.into(db.todos).insert(
            TodosCompanion.insert(
              id: 'todo-1',
              personId: Value(family.kid),
              taskText: 'todo',
              createdAt: now,
            ),
          );
      await people.markAsDuplicate(
        treeId: treeId,
        sourceId: family.dad,
        targetId: family.mom,
      );

      final preview = await trees.previewTreePurge(treeId);

      expect(preview.people, 3);
      expect(preview.families, 1);
      expect(preview.childLinks, 1);
      expect(preview.events, 1);
      expect(preview.mediaItems, 1);
      expect(preview.researchNotes, 1);
      expect(preview.todos, 1);
      expect(preview.surnameEvents, 0);
      expect(preview.duplicateMarkers, 1);
    });

    test('a purge removes every owned record and reports orphaned files',
        () async {
      final family = await coupleWithChild();
      final now = DateTime(2000);
      await people.updatePerson(
        GenealogyPersonsCompanion(
          id: Value(family.dad),
          profilePhotoPath: const Value('/tmp/dad.jpg'),
        ),
      );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'media-1',
              personId: family.kid,
              filePath: '/tmp/kid.jpg',
              mediaType: 'photo',
              createdAt: now,
            ),
          );
      // A soft-deleted person is purged too.
      final extra = await addPerson(firstName: 'Removed');
      await people.deletePerson(extra);

      final result = await trees.purgeTree(treeId);

      expect(result.people, 4, reason: 'including the soft-deleted person');
      expect(result.orphanedFilePaths, containsAll(['/tmp/dad.jpg', '/tmp/kid.jpg']));
      expect(await trees.getFamilyTreeById(treeId), isNull);
      expect(await db.select(db.genealogyPersons).get(), isEmpty);
      expect(await db.select(db.familiesV2).get(), isEmpty);
      expect(await db.select(db.familyChildrenV2).get(), isEmpty);
      expect(await db.select(db.mediaItems).get(), isEmpty);
      expect(await db.select(db.familyTrees).get(), isEmpty);
    });

    test('a purge leaves another tree completely untouched', () async {
      await addOtherTree();
      final otherPerson = await addPerson(
        firstName: 'Other',
        tree: otherTreeId,
      );
      final otherFamilyId = await people.createFamily(
        treeId: otherTreeId,
        husbandId: otherPerson,
      );
      await coupleWithChild();

      await trees.purgeTree(treeId);

      expect(await trees.getFamilyTreeById(otherTreeId), isNotNull);
      expect(
        (await people.getPeopleByTree(otherTreeId)).single.id,
        otherPerson,
      );
      expect(await people.getFamiliesForPerson(otherPerson), hasLength(1));
      expect(
        (await db.select(db.familiesV2).get()).single.id,
        otherFamilyId,
      );
    });

    test('purging an unknown tree is reported', () async {
      await expectLater(trees.purgeTree('ghost'), throwsArgumentError);
    });

    test('the tree id can be reused after a purge', () async {
      await coupleWithChild();
      await trees.purgeTree(treeId);

      final now = DateTime.now();
      await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              id: treeId,
              treeName: 'Rebuilt',
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect((await trees.getFamilyTreeById(treeId))!.treeName, 'Rebuilt');
    });
  });

  // ---------------------------------------------------------------------------
  group('foreign-key integrity', () {
    test('a person who still has events cannot be hard-deleted', () async {
      final id = await addPerson(firstName: 'HasEvents');
      final now = DateTime(2000);
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'event-1',
              personId: id,
              eventType: 'baptism',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await expectLater(
        (db.delete(db.genealogyPersons)..where((t) => t.id.equals(id))).go(),
        throwsA(anything),
      );
    });

    test('a tree that still holds people cannot be hard-deleted', () async {
      await addPerson(firstName: 'Anchored');

      await expectLater(
        (db.delete(db.familyTrees)..where((t) => t.id.equals(treeId))).go(),
        throwsA(anything),
      );
    });

    test('a family that still has children cannot be hard-deleted', () async {
      final family = await coupleWithChild();

      await expectLater(
        (db.delete(db.familiesV2)
              ..where((t) => t.id.equals(family.familyId)))
            .go(),
        throwsA(anything),
      );
    });

    test('a person who is still a partner cannot be hard-deleted', () async {
      final family = await coupleWithChild();

      await expectLater(
        (db.delete(db.genealogyPersons)
              ..where((t) => t.id.equals(family.dad)))
            .go(),
        throwsA(anything),
      );
    });
  });
}

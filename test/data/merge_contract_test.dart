// The merge contract.
//
// Person A + Person B → survivor, in one transaction, with a defined answer for
// every question the contract has to settle: survivor identity, UUID behaviour,
// field conflicts, partnerships, children, duplicate markers, other references,
// retired state, and sync/version (which does not exist).
//
// The failure-midway test injects an error with a SQLite trigger, so a real
// failure happens *after* earlier steps have written — which is what proves the
// transaction rolls the whole merge back.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/family_tree_repository.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

import '../support/test_database.dart';

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

  Future<String> addPerson({
    required String firstName,
    String gender = 'M',
    String tree = treeId,
    String? notes,
    String? occupation,
  }) {
    return people.addPerson(
      treeId: tree,
      firstName: firstName,
      gender: gender,
      notes: notes,
      occupation: occupation,
    );
  }

  Future<List<FamiliesV2Data>> liveFamilies() async {
    final families = await db.select(db.familiesV2).get();
    return families.where((f) => !f.isDeleted).toList();
  }

  // ---------------------------------------------------------------------------
  group('survivor identity and UUID behaviour', () {
    test('a simple merge keeps the survivor intact and retires the duplicate',
        () async {
      final survivor = await addPerson(firstName: 'Ram', notes: 'kept');
      final duplicate = await addPerson(firstName: 'Ram');
      final survivorBefore = (await people.getPersonById(survivor))!;
      final duplicateBefore = (await people.getPersonById(duplicate))!;

      final result = await people.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      final after = (await people.getPersonById(survivor))!;
      expect(after.id, survivor, reason: 'id is unchanged');
      expect(after.uuid, survivorBefore.uuid, reason: 'uuid is unchanged');
      expect(after.treeId, survivorBefore.treeId);
      expect(after.createdAt, survivorBefore.createdAt);
      expect(after.isDeleted, isFalse);
      expect(after.mergedIntoId, isNull);
      expect(after.notes, 'kept');

      final retired = (await people.getPersonById(duplicate))!;
      expect(retired.isDeleted, isTrue);
      expect(retired.mergedIntoId, survivor);
      expect(
        retired.uuid,
        duplicateBefore.uuid,
        reason: 'the retired identity is still resolvable',
      );

      expect(result.partnershipsMoved, 0);
      expect(result.partnershipsCollapsed, 0);
      expect(result.childLinksMoved, 0);
      expect(await people.getPeopleByTree(treeId), hasLength(1));
    });

    test('nothing is hard-deleted and every row still points somewhere valid',
        () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      // The retired row is still there; the only references to it are its own.
      final persons = await db.select(db.genealogyPersons).get();
      expect(persons, hasLength(2));
      expect(persons.where((p) => p.mergedIntoId == duplicate), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('field conflict resolution', () {
    test('the survivor wins, gaps are filled from the duplicate', () async {
      final survivor = await addPerson(
        firstName: 'Ram',
        notes: 'survivor note',
      );
      final duplicate = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'M',
        notes: 'duplicate note',
        occupation: 'weaver',
        religion: 'Hindu',
      );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      final merged = (await people.getPersonById(survivor))!;
      expect(merged.notes, 'survivor note', reason: 'survivor wins');
      expect(merged.occupation, 'weaver', reason: 'gap filled');
      expect(merged.religion, 'Hindu');
    });

    test('a caller can prefer the duplicate for a field', () async {
      final survivor = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'M',
        notes: 'survivor note',
      );
      final duplicate = await addPerson(firstName: 'Ram', notes: 'dup note');

      await people.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
        preferredNotesSource: 'secondary',
      );

      expect((await people.getPersonById(survivor))!.notes, 'dup note');
    });

    test('life status follows the merged death date', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'M',
        deathDate: DateTime(1990, 4, 5),
        isLiving: false,
      );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      final merged = (await people.getPersonById(survivor))!;
      expect(merged.deathDate, DateTime(1990, 4, 5));
      expect(merged.isLiving, isFalse);
    });

    test('privacy is the union and the stricter level wins', () async {
      final survivor = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'M',
        isPrivate: false,
        privacyLevel: 1,
      );
      final duplicate = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'M',
        isPrivate: true,
        privacyLevel: 3,
      );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      final merged = (await people.getPersonById(survivor))!;
      expect(merged.isPrivate, isTrue);
      expect(merged.privacyLevel, 3);
    });

    test('a recorded display-name format beats the schema default', () async {
      final survivor = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'M',
        displayNameFormat: 'birth_married',
      );
      final duplicate = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'M',
        displayNameFormat: 'nickname',
      );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      expect(
        (await people.getPersonById(survivor))!.displayNameFormat,
        'nickname',
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('partnerships', () {
    test('different partnerships are inherited by the survivor', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final firstWife = await addPerson(firstName: 'Sita', gender: 'F');
      final secondWife = await addPerson(firstName: 'Gita', gender: 'F');
      final duplicate = await addPerson(firstName: 'Ram');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: survivor,
        personBId: firstWife,
      );
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: duplicate,
        personBId: secondWife,
      );

      final result = await people.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      expect(result.partnershipsMoved, 1);
      expect(result.partnershipsCollapsed, 0);
      expect((await relationships.getSpouses(survivor)), hasLength(2));
      final partners = (await relationships.getSpouses(survivor))
          .map((p) => p.id)
          .toSet();
      expect(partners, {firstWife, secondWife});
    });

    test('overlapping partnerships collapse into one family', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final wife = await addPerson(firstName: 'Sita', gender: 'F');
      final duplicate = await addPerson(firstName: 'Ram');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: survivor,
        personBId: wife,
      );
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: duplicate,
        personBId: wife,
      );

      final result = await people.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      expect(result.partnershipsCollapsed, 1);
      expect(result.partnershipsMoved, 0);
      expect(await liveFamilies(), hasLength(1));
      expect((await relationships.getSpouses(survivor)).single.id, wife);
    });

    test('the couple\'s own family is retired instead of becoming a '
        'self-relationship', () async {
      final first = await addPerson(firstName: 'Ram');
      final second = await addPerson(firstName: 'Ram');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: first,
        personBId: second,
      );

      final result = await people.mergePeople(
        survivorId: first,
        duplicateId: second,
      );

      expect(result.partnershipsCollapsed, 1);
      expect(await liveFamilies(), isEmpty);
      // No family has the same person in both slots.
      for (final family in await db.select(db.familiesV2).get()) {
        expect(
          family.husbandId == family.wifeId && family.husbandId != null,
          isFalse,
          reason: 'self-relationship',
        );
      }
      expect(await relationships.getSpouses(first), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('children', () {
    test('the duplicate\'s children move to the survivor', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: duplicate,
        childId: kid,
      );

      final result = await people.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      expect(result.childLinksMoved, 0, reason: 'the child followed the family');
      expect(result.partnershipsMoved, 1);
      expect((await relationships.getChildren(survivor)).single.id, kid);
      expect(await relationships.getChildren(duplicate), isEmpty);
    });

    test('a child link that already exists for the pair is collapsed', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final wife = await addPerson(firstName: 'Sita', gender: 'F');
      final duplicate = await addPerson(firstName: 'Ram');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: survivor,
        personBId: wife,
      );
      final survivorFamily =
          (await relationships.getFamiliesForPerson(survivor)).single.id;
      await people.addChildToFamily(familyId: survivorFamily, childId: kid);
      // The duplicate claims the same child in a family of their own.
      final duplicateFamily = await people.createFamily(
        treeId: treeId,
        husbandId: duplicate,
      );
      await people.addChildToFamily(
        familyId: duplicateFamily,
        childId: kid,
      );

      final result = await people.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      expect(result.childLinksCollapsed + result.childLinksMoved, 1);
      final liveLinks = (await db.select(db.familyChildrenV2).get())
          .where((l) => !l.isDeleted && l.childId == kid)
          .toList();
      expect(liveLinks, hasLength(1), reason: 'no duplicate parentage');
    });

    test('children of the couple survive the family being retired', () async {
      final first = await addPerson(firstName: 'Ram');
      final second = await addPerson(firstName: 'Ram');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: first,
        personBId: second,
      );
      final ownFamily = (await relationships.getFamiliesForPerson(first)).single;
      await people.addChildToFamily(familyId: ownFamily.id, childId: kid);

      await people.mergePeople(survivorId: first, duplicateId: second);

      expect(
        (await relationships.getChildren(first)).single.id,
        kid,
        reason: 'the child keeps the parent',
      );
      expect((await people.getPersonById(kid))!.isDeleted, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  group('duplicate markers', () {
    test('the pair\'s marker is resolved and a third-party marker is kept', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final third = await addPerson(firstName: 'Ram');
      await people.markAsDuplicate(
        treeId: treeId,
        sourceId: survivor,
        targetId: duplicate,
      );
      await people.markAsDuplicate(
        treeId: treeId,
        sourceId: duplicate,
        targetId: third,
      );
      await people.markAsDuplicate(
        treeId: treeId,
        sourceId: survivor,
        targetId: third,
      );

      final result = await people.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      expect(result.duplicateMarkersRemoved, 1);
      expect(result.duplicateMarkersRewritten, 1);

      final markers = await db.select(db.duplicateMarkers).get();
      // (survivor, third) existed already, so the rewritten marker collapses
      // onto it: exactly one marker remains and it names no retired person.
      expect(markers, hasLength(1));
      expect(markers.single.personAId, isNot(duplicate));
      expect(markers.single.personBId, isNot(duplicate));
      expect(
        {markers.single.personAId, markers.single.personBId},
        {survivor, third},
      );
    });

    test('a marker that never mentioned the duplicate is untouched', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final third = await addPerson(firstName: 'Other');
      final fourth = await addPerson(firstName: 'Another');
      await people.markAsDuplicate(
        treeId: treeId,
        sourceId: third,
        targetId: fourth,
      );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      final markers = await db.select(db.duplicateMarkers).get();
      expect(markers, hasLength(1));
      expect({markers.single.personAId, markers.single.personBId},
          {third, fourth});
    });
  });

  // ---------------------------------------------------------------------------
  group('references from other tables', () {
    test('person-scoped rows all follow the survivor', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final now = DateTime(2000);
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'e1',
              personId: duplicate,
              eventType: 'baptism',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.todos).insert(
            TodosCompanion.insert(
              id: 't1',
              personId: Value(duplicate),
              taskText: 'find the register',
              createdAt: now,
            ),
          );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'm1',
              personId: duplicate,
              filePath: '/tmp/photo.jpg',
              mediaType: 'photo',
              createdAt: now,
            ),
          );
      await db.into(db.researchNotes).insert(
            ResearchNotesCompanion.insert(
              id: 'n1',
              personId: Value(duplicate),
              noteText: 'note',
              createdAt: now,
            ),
          );
      await db.into(db.surnameEvents).insert(
            SurnameEventsCompanion.insert(
              id: 's1',
              personId: duplicate,
              surname: 'Patel',
              surnameType: 'birth',
              uuid: 'uuid-s1',
            ),
          );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      expect((await db.select(db.events).get()).single.personId, survivor);
      expect((await db.select(db.todos).get()).single.personId, survivor);
      expect((await db.select(db.mediaItems).get()).single.personId, survivor);
      expect(
        (await db.select(db.researchNotes).get()).single.personId,
        survivor,
      );
      expect((await db.select(db.surnameEvents).get()).single.personId, survivor);
    });

    test('a tree rooted at the duplicate now roots at the survivor', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final tree = (await db.select(db.familyTrees).get()).single;
      await FamilyTreeRepository(db).updateFamilyTree(
        id: tree.id,
        treeName: tree.treeName,
        description: tree.description,
        rootPersonId: duplicate,
        createdAt: tree.createdAt,
      );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      expect(
        (await db.select(db.familyTrees).get()).single.rootPersonId,
        survivor,
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('failure midway leaves no partial merge', () {
    test('an error inside the transaction rolls the whole merge back', () async {
      final survivor = await addPerson(firstName: 'Ram', notes: 'survivor');
      final wife = await addPerson(firstName: 'Sita', gender: 'F');
      final duplicate = await addPerson(firstName: 'Ram', notes: 'duplicate');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: duplicate,
        personBId: wife,
      );
      final familyId = (await relationships.getFamiliesForPerson(duplicate)).single.id;
      await people.addChildToFamily(familyId: familyId, childId: kid);
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'e1',
              personId: duplicate,
              eventType: 'baptism',
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );

      // Fail the *third* step of the merge (repointing events), after the
      // partnership and child-link steps have already written.
      await db.customStatement(
        'CREATE TRIGGER fail_merge BEFORE UPDATE ON events '
        "BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );

      await expectLater(
        people.mergePeople(survivorId: survivor, duplicateId: duplicate),
        throwsA(anything),
      );

      // Step 1 (partnerships) and step 2 (child links) must have been undone.
      final family = (await db.select(db.familiesV2).get()).single;
      expect(family.husbandId, duplicate, reason: 'partnership rolled back');
      expect(family.wifeId, wife);
      expect(
        (await db.select(db.familyChildrenV2).get()).single.childId,
        kid,
      );
      expect((await people.getPersonById(duplicate))!.isDeleted, isFalse);
      expect((await people.getPersonById(duplicate))!.mergedIntoId, isNull);
      expect((await people.getPersonById(survivor))!.notes, 'survivor');
      expect((await db.select(db.events).get()).single.personId, duplicate);

      // With the injected failure removed the same merge succeeds.
      await db.customStatement('DROP TRIGGER fail_merge');
      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);
      expect((await people.getPersonById(duplicate))!.mergedIntoId, survivor);
    });
  });

  // ---------------------------------------------------------------------------
  group('repeated and invalid merges', () {
    test('merging the same duplicate twice is refused', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      await expectLater(
        people.mergePeople(survivorId: survivor, duplicateId: duplicate),
        throwsArgumentError,
      );
    });

    test('a retired person cannot be a survivor', () async {
      final first = await addPerson(firstName: 'Ram');
      final second = await addPerson(firstName: 'Ram');
      final third = await addPerson(firstName: 'Ram');
      await people.mergePeople(survivorId: first, duplicateId: second);

      await expectLater(
        people.mergePeople(survivorId: second, duplicateId: third),
        throwsArgumentError,
      );
    });

    test('merging a person into themselves is refused', () async {
      final id = await addPerson(firstName: 'Solo');

      await expectLater(
        people.mergePeople(survivorId: id, duplicateId: id),
        throwsArgumentError,
      );
    });

    test('an unknown person is refused', () async {
      final id = await addPerson(firstName: 'Ram');

      await expectLater(
        people.mergePeople(survivorId: id, duplicateId: 'ghost'),
        throwsArgumentError,
      );
      await expectLater(
        people.mergePeople(survivorId: 'ghost', duplicateId: id),
        throwsArgumentError,
      );
    });

    test('a cross-tree merge is refused and changes nothing', () async {
      final now = DateTime.now();
      await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              id: 'other-tree',
              treeName: 'Other',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final mine = await addPerson(firstName: 'Ram');
      final theirs = await addPerson(firstName: 'Ram', tree: 'other-tree');

      await expectLater(
        people.mergePeople(survivorId: mine, duplicateId: theirs),
        throwsArgumentError,
      );

      expect((await people.getPersonById(mine))!.isDeleted, isFalse);
      expect((await people.getPersonById(theirs))!.isDeleted, isFalse);
      expect((await people.getPersonById(theirs))!.treeId, 'other-tree');
    });
  });
}

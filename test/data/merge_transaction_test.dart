// Regression tests for the merge path reworked in Phase 1.
//
// The merge used to run as ~15 independent statements with no transaction, it
// skipped `occupation`, `religion`, `ethnicity`, `customDisplayName` and
// `isPrivate`, it never repointed `citation_links`, it kept the survivor's
// `is_living` regardless of the merged death date, and its clash check for
// `UNIQUE(family_id, child_id)` ignored soft-deleted rows — so a merge could
// collide, throw, and leave the tree half-rewritten.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

import '../support/test_database.dart';

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;
  late GenealogyRepository repository;
  late RelationshipRepository relationships;

  setUp(() async {
    db = await createTestDatabase();
    repository = GenealogyRepository(db);
    relationships = RelationshipRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> addPerson({
    required String firstName,
    String gender = 'M',
    DateTime? birthDate,
    DateTime? deathDate,
    bool isLiving = true,
    String? occupation,
    String? religion,
    String? ethnicity,
    String? customDisplayName,
    bool isPrivate = false,
  }) {
    return repository.addPerson(
      treeId: treeId,
      firstName: firstName,
      gender: gender,
      birthDate: birthDate,
      deathDate: deathDate,
      isLiving: isLiving,
      occupation: occupation,
      religion: religion,
      ethnicity: ethnicity,
      customDisplayName: customDisplayName,
      isPrivate: isPrivate,
    );
  }

  group('merge field handling', () {
    test('fields that used to be dropped are carried over', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(
        firstName: 'Ram',
        occupation: 'weaver',
        religion: 'Hindu',
        ethnicity: 'Gujarati',
        customDisplayName: 'Ram the weaver',
        isPrivate: true,
      );

      await repository.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      final merged = (await repository.getPersonById(survivor))!;
      expect(merged.occupation, 'weaver');
      expect(merged.religion, 'Hindu');
      expect(merged.ethnicity, 'Gujarati');
      expect(merged.customDisplayName, 'Ram the weaver');
      expect(merged.isPrivate, isTrue);
    });

    test('life status follows the merged death date', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(
        firstName: 'Ram',
        deathDate: DateTime(1988, 2, 3),
        isLiving: false,
      );

      await repository.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      final merged = (await repository.getPersonById(survivor))!;
      expect(merged.deathDate, DateTime(1988, 2, 3));
      expect(merged.isLiving, isFalse);
    });

    test('the duplicate is retired and points at the survivor', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');

      await repository.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      final retired = (await repository.getPersonById(duplicate))!;
      expect(retired.isDeleted, isTrue);
      expect(retired.mergedIntoId, survivor);
      expect(await repository.getPeopleByTree(treeId), hasLength(1));
    });
  });

  group('merge structural handling', () {
    test('a spouse family is reassigned to the survivor', () async {
      final husband = await addPerson(firstName: 'Husband');
      final wife = await addPerson(firstName: 'Wife', gender: 'F');
      final replacement = await addPerson(firstName: 'Wife', gender: 'F');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: husband,
        personBId: wife,
      );

      await repository.mergePeople(
        survivorId: replacement,
        duplicateId: wife,
      );

      final family = (await db.select(db.familiesV2).get()).single;
      expect(family.husbandId, husband);
      expect(family.wifeId, replacement);
      expect(
        (await relationships.getSpouses(husband)).single.id,
        replacement,
      );
    });

    test(
      'a child-link collision is resolved even when the survivor\'s link was '
      'removed earlier (the UNIQUE(family_id, child_id) case)',
      () async {
        final parent = await addPerson(firstName: 'Parent');
        final survivor = await addPerson(firstName: 'Child');
        final duplicate = await addPerson(firstName: 'Child');
        await relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: parent,
          childId: survivor,
        );
        await relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: parent,
          childId: duplicate,
        );
        final links = await db.select(db.familyChildrenV2).get();
        expect(links, hasLength(2));

        // Remove the survivor's link, then merge the duplicate (which still has
        // a live link in the same family) into the survivor.
        final survivorLink = links.firstWhere((l) => l.childId == survivor);
        await relationships.removeParentChildLink(survivorLink.id);

        await repository.mergePeople(
          survivorId: survivor,
          duplicateId: duplicate,
        );

        final after = await db.select(db.familyChildrenV2).get();
        expect(after, hasLength(1), reason: 'the duplicate row is collapsed');
        expect(after.single.childId, survivor);
        expect(after.single.isDeleted, isFalse, reason: 'link is live again');
        expect((await relationships.getChildren(parent)).single.id, survivor);
      },
    );

    test('citation links are repointed, and a clash is dropped not overwritten',
        () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final now = DateTime(2000);

      await db.into(db.citations).insert(
            CitationsCompanion.insert(
              id: 'citation-shared',
              sourceTitle: 'Census 1901',
              citationText: 'Census entry',
              createdAt: now,
            ),
          );
      await db.into(db.citations).insert(
            CitationsCompanion.insert(
              id: 'citation-only-duplicate',
              sourceTitle: 'Birth register',
              citationText: 'Register entry',
              createdAt: now,
            ),
          );
      // The survivor already cites the shared source.
      await db.into(db.citationLinks).insert(
            CitationLinksCompanion.insert(
              citationId: 'citation-shared',
              entityType: 'person',
              entityId: survivor,
            ),
          );
      await db.into(db.citationLinks).insert(
            CitationLinksCompanion.insert(
              citationId: 'citation-shared',
              entityType: 'person',
              entityId: duplicate,
            ),
          );
      await db.into(db.citationLinks).insert(
            CitationLinksCompanion.insert(
              citationId: 'citation-only-duplicate',
              entityType: 'person',
              entityId: duplicate,
            ),
          );

      await repository.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      final links = await db.select(db.citationLinks).get();
      expect(links, hasLength(2));
      expect(
        links.where((l) => l.entityId == duplicate),
        isEmpty,
        reason: 'nothing still points at the duplicate',
      );
      expect(
        links.map((l) => l.citationId).toSet(),
        {'citation-shared', 'citation-only-duplicate'},
      );
    });

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
              noteText: 'check the parish register',
              createdAt: now,
            ),
          );

      await repository.mergePeople(
        survivorId: survivor,
        duplicateId: duplicate,
      );

      expect((await db.select(db.events).get()).single.personId, survivor);
      expect((await db.select(db.mediaItems).get()).single.personId, survivor);
      expect(
        (await db.select(db.researchNotes).get()).single.personId,
        survivor,
      );
    });
  });

  group('merge safety', () {
    test('merging a person into themselves is rejected', () async {
      final id = await addPerson(firstName: 'Solo');

      await expectLater(
        repository.mergePeople(survivorId: id, duplicateId: id),
        throwsArgumentError,
      );
    });

    test('a merge that fails validation leaves the database untouched',
        () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      await repository.deletePerson(duplicate);
      final before = {
        'persons': (await db.select(db.genealogyPersons).get()).length,
        'families': (await db.select(db.familiesV2).get()).length,
        'links': (await db.select(db.familyChildrenV2).get()).length,
      };

      await expectLater(
        repository.mergePeople(survivorId: survivor, duplicateId: duplicate),
        throwsArgumentError,
      );

      expect((await db.select(db.genealogyPersons).get()).length, before['persons']);
      expect((await db.select(db.familiesV2).get()).length, before['families']);
      expect(
        (await db.select(db.familyChildrenV2).get()).length,
        before['links'],
      );
      expect((await repository.getPersonById(survivor))!.isDeleted, isFalse);
    });

    test('an unknown person cannot be merged', () async {
      final id = await addPerson(firstName: 'Ram');

      await expectLater(
        repository.mergePeople(survivorId: id, duplicateId: 'ghost'),
        throwsArgumentError,
      );
      await expectLater(
        repository.mergePeople(survivorId: 'ghost', duplicateId: id),
        throwsArgumentError,
      );
    });
  });
}

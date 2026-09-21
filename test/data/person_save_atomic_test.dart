// Phase 1A: composite person-save operations are atomic.
//
// Every test below proves all-or-nothing behaviour at the real database
// level: a failure at any step of a logical save must leave no orphan person,
// no partial relationship and no orphan family behind. Late failures are
// injected with a SQLite trigger (following merge_contract_test.dart), so a
// real error fires *after* earlier steps have written — which is what proves
// the transaction rolls everything back.

import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/models/person_save_data.dart';
import 'package:vanshvriksh/data/repositories/family_tree_repository.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';
import 'package:vanshvriksh/data/services/person_save_service.dart';

import '../support/test_database.dart';
import 'domain_invariants_test.dart' as check;

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;
  late GenealogyRepository people;
  late RelationshipRepository relationships;
  late PersonSaveService save;

  setUp(() async {
    db = await createTestDatabase();
    people = GenealogyRepository(db);
    relationships = RelationshipRepository(db);
    save = PersonSaveService(db);
  });

  tearDown(() async {
    await db.close();
  });

  PersonSaveData data(String firstName, {String gender = 'male'}) {
    return PersonSaveData(firstName: firstName, gender: gender);
  }

  Future<String> addPerson(String firstName, {String gender = 'male'}) {
    return people.addPerson(
      treeId: treeId,
      firstName: firstName,
      gender: gender,
    );
  }

  Future<Set<String>> parentIdsOf(String childId) async {
    final parents = await relationships.getParents(childId);
    return parents.map((p) => p.id).toSet();
  }

  // ---------------------------------------------------------------------------
  group('create person as parent', () {
    test('success links the new person as parent', () async {
      final child = await addPerson('Child');
      final parent = await save.createPersonAsParent(
        treeId: treeId,
        person: data('Dad'),
        childId: child,
      );

      expect(await people.getPersonById(parent), isNotNull);
      expect(await parentIdsOf(child), {parent});
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('relationship failure rolls the new person back', () async {
      final before = await check.dataStateOf(db);

      await expectLater(
        save.createPersonAsParent(
          treeId: treeId,
          person: data('Dad'),
          childId: 'no-such-child',
        ),
        throwsArgumentError,
      );

      expect(await check.dataStateOf(db), before);
      expect(await check.violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('create person as child', () {
    test('success links the child and the co-parent', () async {
      final dad = await addPerson('Dad');
      final mom = await addPerson('Mom', gender: 'female');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );

      final kid = await save.createPersonAsChild(
        treeId: treeId,
        person: data('Kid'),
        parentId: dad,
        includeParentSpouses: true,
      );

      expect(await parentIdsOf(kid), {dad, mom});
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('first-link failure rolls everything back', () async {
      final before = await check.dataStateOf(db);

      await expectLater(
        save.createPersonAsChild(
          treeId: treeId,
          person: data('Kid'),
          parentId: 'no-such-parent',
        ),
        throwsArgumentError,
      );

      expect(await check.dataStateOf(db), before);
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('co-parent failure rolls back person, link and family', () async {
      final dad = await addPerson('Dad');
      final before = await check.dataStateOf(db);

      await expectLater(
        save.createPersonAsChild(
          treeId: treeId,
          person: data('Kid'),
          parentId: dad,
          coParentIds: const ['no-such-co-parent'],
        ),
        throwsArgumentError,
      );

      // The first link created a single-parent family for dad; it must be
      // gone along with the person and the link.
      expect(await check.dataStateOf(db), before);
      expect(await relationships.getParents('nobody'), isEmpty);
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('injected late failure rolls the whole save back', () async {
      final dad = await addPerson('Dad');
      final before = await check.dataStateOf(db);

      // Fail the child-link insert, after the person and family rows have
      // already been written inside the transaction.
      await db.customStatement(
        'CREATE TRIGGER fail_child_link BEFORE INSERT ON family_children_v2 '
        "BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );

      await expectLater(
        save.createPersonAsChild(
          treeId: treeId,
          person: data('Kid'),
          parentId: dad,
        ),
        throwsA(anything),
      );
      expect(await check.dataStateOf(db), before);

      // With the failure removed the same save succeeds.
      await db.customStatement('DROP TRIGGER fail_child_link');
      final kid = await save.createPersonAsChild(
        treeId: treeId,
        person: data('Kid'),
        parentId: dad,
      );
      expect(await parentIdsOf(kid), {dad});
      expect(await check.violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('create person as spouse', () {
    test('success records the partnership', () async {
      final partner = await addPerson('Partner', gender: 'female');
      final spouse = await save.createPersonAsSpouse(
        treeId: treeId,
        person: data('Spouse'),
        partnerId: partner,
      );

      final spouses = await relationships.getSpouses(partner);
      expect(spouses.map((p) => p.id), contains(spouse));
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('deleted-partner failure rolls the new person back', () async {
      final partner = await addPerson('Partner', gender: 'female');
      await people.deletePerson(partner);
      final before = await check.dataStateOf(db);

      await expectLater(
        save.createPersonAsSpouse(
          treeId: treeId,
          person: data('Spouse'),
          partnerId: partner,
        ),
        throwsArgumentError,
      );

      expect(await check.dataStateOf(db), before);
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('cross-tree failure rolls the new person back', () async {
      await FamilyTreeRepository(db).addFamilyTree(treeName: 'Other');
      final otherTreeId = (await FamilyTreeRepository(
        db,
      ).getAllFamilyTrees()).firstWhere((t) => t.id != treeId).id;
      final outsider = await people.addPerson(
        treeId: otherTreeId,
        firstName: 'Outsider',
        gender: 'female',
      );
      final before = await check.dataStateOf(db);

      await expectLater(
        save.createPersonAsSpouse(
          treeId: treeId,
          person: data('Spouse'),
          partnerId: outsider,
        ),
        throwsArgumentError,
      );

      expect(await check.dataStateOf(db), before);
      expect(await check.violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('create person as sibling', () {
    test('success shares both parents', () async {
      final dad = await addPerson('Dad');
      final mom = await addPerson('Mom', gender: 'female');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final kidA = await addPerson('KidA');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kidA,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: mom,
        childId: kidA,
      );

      final kidB = await save.createPersonAsSibling(
        treeId: treeId,
        person: data('KidB'),
        parentIds: [dad, mom],
      );

      expect(await parentIdsOf(kidB), {dad, mom});
      expect(
        (await relationships.getSiblings(kidA)).map((p) => p.id),
        contains(kidB),
      );
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('no resolvable parents fails without creating anyone', () async {
      final before = await check.dataStateOf(db);

      // The empty-parent rejection throws synchronously (before any write),
      // so assert on a closure rather than a Future.
      expect(
        () => save.createPersonAsSibling(
          treeId: treeId,
          person: data('KidB'),
          parentIds: const [],
        ),
        throwsArgumentError,
      );

      expect(await check.dataStateOf(db), before);
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('later parent-link failure rolls everything back', () async {
      final dad = await addPerson('Dad');
      final before = await check.dataStateOf(db);

      await expectLater(
        save.createPersonAsSibling(
          treeId: treeId,
          person: data('KidB'),
          parentIds: [dad, 'no-such-parent'],
        ),
        throwsArgumentError,
      );

      expect(await check.dataStateOf(db), before);
      expect(await check.violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('existing child with co-parents', () {
    test('success links the parent and the co-parent', () async {
      final dad = await addPerson('Dad');
      final mom = await addPerson('Mom', gender: 'female');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final kid = await addPerson('Kid');

      await save.addExistingChildWithCoParents(
        treeId: treeId,
        parentId: dad,
        childId: kid,
        includeParentSpouses: true,
      );

      expect(await parentIdsOf(kid), {dad, mom});
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('co-parent failure rolls the first link back', () async {
      final dad = await addPerson('Dad');
      final kid = await addPerson('Kid');
      final before = await check.dataStateOf(db);

      await expectLater(
        save.addExistingChildWithCoParents(
          treeId: treeId,
          parentId: dad,
          childId: kid,
          coParentIds: const ['no-such-co-parent'],
        ),
        throwsArgumentError,
      );

      expect(await check.dataStateOf(db), before);
      expect(await parentIdsOf(kid), isEmpty);
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('re-linking recorded parentage stays a no-op', () async {
      final dad = await addPerson('Dad');
      final kid = await addPerson('Kid');
      await save.addExistingChildWithCoParents(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );
      final before = await check.dataStateOf(db);

      await save.addExistingChildWithCoParents(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      expect(await check.dataStateOf(db), before);
      expect(await parentIdsOf(kid), {dad});
      expect(await check.violatedInvariants(db), isEmpty);
    });
  });
}

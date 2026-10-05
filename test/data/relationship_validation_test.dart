// The integrity rules added to the parentage path and the family APIs:
//   * both people in a parentage must belong to the requested tree;
//   * a parentage must not create an ancestry cycle;
//   * a biological parent must be born before the child (other relationship
//     types are exempt — a step-parent can be younger);
//   * createFamily stores couples canonically, so argument order cannot
//     duplicate a couple, and refuses an existing couple;
//   * addChildToFamily validates family/child/tree/cycle/duplicate parentage;
//   * addExistingSibling shares the profile person's parents.

import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/models/person_save_data.dart';
import 'package:vanshvriksh/data/repositories/family_tree_repository.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';
import 'package:vanshvriksh/data/services/person_save_service.dart';

import '../support/test_database.dart';

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;
  late GenealogyRepository people;
  late RelationshipRepository relationships;
  late PersonSaveService saves;
  late FamilyTreeRepository trees;

  setUp(() async {
    db = await createTestDatabase();
    people = GenealogyRepository(db);
    relationships = RelationshipRepository(db);
    saves = PersonSaveService(db);
    trees = FamilyTreeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> addPerson({
    required String firstName,
    String gender = 'M',
    DateTime? birthDate,
  }) {
    return people.addPerson(
      treeId: treeId,
      firstName: firstName,
      gender: gender,
      birthDate: birthDate,
    );
  }

  Future<String> addSecondTree() async {
    await trees.addFamilyTree(treeName: 'Second Tree');
    final all = await trees.getAllFamilyTrees();
    return all.firstWhere((tree) => tree.id != treeId).id;
  }

  group('parentage tree ownership', () {
    test('refuses a parent from another tree', () async {
      final parent = await addPerson(firstName: '跨树 Parent');
      final child = await addPerson(firstName: 'Child');
      final otherTree = await addSecondTree();

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: otherTree,
          parentId: parent,
          childId: child,
        ),
        throwsArgumentError,
      );
    });

    test('refuses a child from another tree', () async {
      final parent = await addPerson(firstName: 'Parent');
      final otherTree = await addSecondTree();
      final child = await people.addPerson(
        treeId: otherTree,
        firstName: 'Foreign Child',
        gender: 'M',
      );

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: parent,
          childId: child,
        ),
        throwsArgumentError,
      );
    });
  });

  group('parentage cycle prevention', () {
    test('refuses making a child the parent of their own parent', () async {
      final parent = await addPerson(firstName: 'Parent');
      final child = await addPerson(firstName: 'Child');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: child,
      );

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: child,
          childId: parent,
        ),
        throwsStateError,
      );
    });

    test('refuses a cycle through a longer ancestor chain', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B');
      final c = await addPerson(firstName: 'C');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: a,
        childId: b,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: b,
        childId: c,
      );

      // C as a parent of A would make A their own grandchild.
      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: c,
          childId: a,
        ),
        throwsStateError,
      );
    });

    test('rolls back a composite save whose link would cycle', () async {
      final parent = await addPerson(firstName: 'Parent');
      final child = await addPerson(firstName: 'Child');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: child,
      );

      // Recording the existing child as a parent of their own parent would
      // make the parent their own grandchild; the composite save must fail.
      await expectLater(
        saves.addExistingChildWithCoParents(
          treeId: treeId,
          parentId: child,
          childId: parent,
        ),
        throwsStateError,
      );

      // Nothing half-written: the parent still has no recorded parents.
      expect(await relationships.getParents(parent), isEmpty);
    });
  });

  group('biological plausibility', () {
    test('refuses a biological parent not born before the child', () async {
      final parent = await addPerson(
        firstName: 'Young Parent',
        birthDate: DateTime(2010, 1, 1),
      );
      final child = await addPerson(
        firstName: 'Older Child',
        birthDate: DateTime(2000, 1, 1),
      );

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: parent,
          childId: child,
        ),
        throwsArgumentError,
      );
    });

    test('allows a younger step-parent', () async {
      final parent = await addPerson(
        firstName: 'Step Parent',
        birthDate: DateTime(2010, 1, 1),
      );
      final child = await addPerson(
        firstName: 'Older Child',
        birthDate: DateTime(2000, 1, 1),
      );

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: child,
        relationshipType: 'step',
      );

      final parents = await relationships.getParents(child);
      expect(parents.map((p) => p.id), contains(parent));
    });

    test('allows a biological parent with unknown dates', () async {
      final parent = await addPerson(firstName: 'Parent');
      final child = await addPerson(firstName: 'Child');

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: child,
      );

      final parents = await relationships.getParents(child);
      expect(parents.map((p) => p.id), contains(parent));
    });
  });

  group('createFamily canonicalization', () {
    test('stores a couple canonically regardless of argument order', () async {
      final husband = await addPerson(firstName: 'Husband', gender: 'M');
      final wife = await addPerson(firstName: 'Wife', gender: 'F');

      await people.createFamily(
        treeId: treeId,
        husbandId: wife,
        wifeId: husband,
      );

      final families = await people.getFamiliesForPerson(husband);
      expect(families, hasLength(1));
      expect(families.single.husbandId, husband);
      expect(families.single.wifeId, wife);
    });

    test('refuses the same couple twice, even with swapped slots', () async {
      final a = await addPerson(firstName: 'A', gender: 'M');
      final b = await addPerson(firstName: 'B', gender: 'F');

      await people.createFamily(treeId: treeId, husbandId: a, wifeId: b);

      await expectLater(
        people.createFamily(treeId: treeId, husbandId: b, wifeId: a),
        throwsStateError,
      );
      final families = await people.getFamiliesForPerson(a);
      expect(families, hasLength(1));
    });

    test('refuses a person partnered with themselves', () async {
      final a = await addPerson(firstName: 'A');

      await expectLater(
        people.createFamily(treeId: treeId, husbandId: a, wifeId: a),
        throwsArgumentError,
      );
    });

    test('refuses cross-tree partners', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B');
      final otherTree = await addSecondTree();

      await expectLater(
        people.createFamily(treeId: otherTree, husbandId: a, wifeId: b),
        throwsArgumentError,
      );
    });
  });

  group('addChildToFamily validation', () {
    test('refuses a child from another tree', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B');
      final familyId = await people.createFamily(
        treeId: treeId,
        husbandId: a,
        wifeId: b,
      );
      final otherTree = await addSecondTree();
      final foreignChild = await people.addPerson(
        treeId: otherTree,
        firstName: 'Foreign',
        gender: 'M',
      );

      await expectLater(
        people.addChildToFamily(familyId: familyId, childId: foreignChild),
        throwsArgumentError,
      );
    });

    test(
      'refuses a child already parented by one of the family partners',
      () async {
        final parent = await addPerson(firstName: 'Parent');
        final spouse = await addPerson(firstName: 'Spouse');
        final familyId = await people.createFamily(
          treeId: treeId,
          husbandId: parent,
          wifeId: spouse,
        );
        // A second family so the parent's next parentage can be aimed at it
        // explicitly instead of joining the couple family above.
        final secondFamilyId = await people.createFamily(
          treeId: treeId,
          husbandId: parent,
          wifeId: await addPerson(firstName: 'Second Spouse'),
        );
        final child = await addPerson(firstName: 'Child');
        await relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: parent,
          childId: child,
          familyId: secondFamilyId,
        );

        // The same parent reaches the child through the couple family too —
        // a second, duplicate parentage that addChildToFamily must refuse.
        await expectLater(
          people.addChildToFamily(familyId: familyId, childId: child),
          throwsStateError,
        );
      },
    );

    test('restores a soft-deleted link instead of duplicating it', () async {
      final parent = await addPerson(firstName: 'Parent');
      final spouse = await addPerson(firstName: 'Spouse');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: parent,
        personBId: spouse,
      );
      final familyId = (await people.getFamiliesForPerson(parent)).single.id;
      final child = await addPerson(firstName: 'Child');
      final linkId = await people.addChildToFamily(
        familyId: familyId,
        childId: child,
      );

      // Soft-delete the child link only; the family itself stays live.
      await relationships.removeParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: child,
        removeCoParent: true,
      );

      final restored = await people.addChildToFamily(
        familyId: familyId,
        childId: child,
      );
      expect(restored, linkId);
    });
  });

  group('addExistingSibling', () {
    test('shares every recorded parent of the profile person', () async {
      final mother = await addPerson(firstName: 'Mother', gender: 'F');
      final father = await addPerson(firstName: 'Father', gender: 'M');
      final person = await saves.createPersonAsChild(
        treeId: treeId,
        person: PersonSaveData(firstName: 'Person', gender: 'M'),
        parentId: mother,
        coParentIds: [father],
      );
      final sibling = await addPerson(firstName: 'Sibling');

      await saves.addExistingSibling(
        treeId: treeId,
        personId: person,
        siblingId: sibling,
      );

      final siblingParents = (await relationships.getParents(
        sibling,
      )).map((p) => p.id).toSet();
      expect(siblingParents, {mother, father});

      // The two are siblings: they share parents.
      final personParents = (await relationships.getParents(
        person,
      )).map((p) => p.id).toSet();
      expect(siblingParents, personParents);
    });

    test('refuses a person without recorded parents', () async {
      final person = await addPerson(firstName: 'No Parents');
      final sibling = await addPerson(firstName: 'Sibling');

      await expectLater(
        saves.addExistingSibling(
          treeId: treeId,
          personId: person,
          siblingId: sibling,
        ),
        throwsArgumentError,
      );
    });

    test('refuses linking a person to themselves', () async {
      final person = await addPerson(firstName: 'Person');

      await expectLater(
        saves.addExistingSibling(
          treeId: treeId,
          personId: person,
          siblingId: person,
        ),
        throwsArgumentError,
      );
    });

    test(
      'refuses a sibling who is an ancestor of the profile person',
      () async {
        final parent = await addPerson(firstName: 'Parent');
        final person = await saves.createPersonAsChild(
          treeId: treeId,
          person: PersonSaveData(firstName: 'Person', gender: 'M'),
          parentId: parent,
        );

        // Attaching the parent as the person's "sibling" would make the
        // parent their own child — rejected, whichever rule fires first
        // (self-parent here, cycle in deeper chains).
        await expectLater(
          saves.addExistingSibling(
            treeId: treeId,
            personId: person,
            siblingId: parent,
          ),
          throwsA(anything),
        );
      },
    );
  });

  group('removeSiblingRelationship', () {
    test('deletes only the shared parentage; other parents stay', () async {
      final mother = await addPerson(firstName: 'Mother', gender: 'F');
      final father = await addPerson(firstName: 'Father', gender: 'M');
      final person = await saves.createPersonAsChild(
        treeId: treeId,
        person: PersonSaveData(firstName: 'Person', gender: 'M'),
        parentId: mother,
        coParentIds: [father],
      );
      final sibling = await addPerson(firstName: 'Sibling', gender: 'F');
      await saves.addExistingSibling(
        treeId: treeId,
        personId: person,
        siblingId: sibling,
      );
      // The sibling also has a parent the profile person does not share —
      // a half-sibling relationship on the other side.
      final otherParent = await addPerson(firstName: 'Other Parent');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: otherParent,
        childId: sibling,
      );

      final removed = await relationships.removeSiblingRelationship(
        treeId: treeId,
        personId: person,
        siblingId: sibling,
      );

      expect(removed, greaterThanOrEqualTo(1));
      // The shared parents are gone from the sibling…
      final siblingParents = (await relationships.getParents(
        sibling,
      )).map((p) => p.id).toSet();
      expect(siblingParents, {otherParent});
      // …the profile person's parentage is untouched…
      final personParents = (await relationships.getParents(
        person,
      )).map((p) => p.id).toSet();
      expect(personParents, {mother, father});
      // …and nobody was deleted.
      for (final id in [person, sibling, mother, father, otherParent]) {
        final row = await people.getPersonById(id);
        expect(row!.isDeleted, isFalse, reason: 'person $id must survive');
      }
    });

    test('is a no-op for people who share no parents', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B');

      final removed = await relationships.removeSiblingRelationship(
        treeId: treeId,
        personId: a,
        siblingId: b,
      );
      expect(removed, 0);
    });

    test('refuses removing a person as their own sibling', () async {
      final a = await addPerson(firstName: 'A');

      // The guard throws synchronously, before a future exists.
      expect(
        () => relationships.removeSiblingRelationship(
          treeId: treeId,
          personId: a,
          siblingId: a,
        ),
        throwsArgumentError,
      );
    });
  });
}

// The relationship repository's domain rules.
//
// Every operation is named after the domain concept it acts on, and the caller
// never handles an identifier whose meaning depends on which table it came from:
//   addSpouseRelationship / removeSpouseRelationship
//   addParentChildRelationship / removeParentChildRelationship
//   getSpouses / getParents / getChildren / getSiblings / getFamiliesForPerson
//
// The tests below pin the rules for partners (one, two or more, same-sex,
// unknown gender, remarriage), for parentage (duplicate links, self links,
// duplicate parentage, multiple parents, adoption, unknown parents) and for the
// getters that must stay coherent with each other.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/models/relationship_edges.dart';
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
  }) {
    return people.addPerson(
      treeId: treeId,
      firstName: firstName,
      gender: gender,
    );
  }

  // ---------------------------------------------------------------------------
  group('partner rules', () {
    test('one partner: a single partnership with both slots filled', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B', gender: 'F');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: a,
        personBId: b,
      );

      final partnerships = await relationships.getPartnerships(treeId);
      expect(partnerships, hasLength(1));
      expect(partnerships.single.partnerIds, hasLength(2));
      expect(await relationships.getSpouses(a), hasLength(1));
    });

    test('argument order does not matter, and re-adding is a no-op', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B', gender: 'F');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: a,
        personBId: b,
      );
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: b,
        personBId: a,
      );

      expect(await db.select(db.familiesV2).get(), hasLength(1));
    });

    test('remarriage: a person may have more than one partnership', () async {
      final a = await addPerson(firstName: 'A');
      final first = await addPerson(firstName: 'First', gender: 'F');
      final second = await addPerson(firstName: 'Second', gender: 'F');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: a,
        personBId: first,
      );
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: a,
        personBId: second,
      );

      expect(await relationships.getSpouses(a), hasLength(2));
      expect(await relationships.getFamiliesForPerson(a), hasLength(2));
    });

    test('a primary partnership is recorded', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B', gender: 'F');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: a,
        personBId: b,
        isPrimary: true,
      );

      expect((await relationships.getFamiliesForPerson(a)).single
          .isPrimaryMarriage, isTrue);
    });

    test('a same-sex couple is supported and uses both slots', () async {
      final a = await addPerson(firstName: 'A');
      final b = await addPerson(firstName: 'B');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: a,
        personBId: b,
      );

      final partnership = (await relationships.getPartnerships(treeId)).single;
      expect(partnership.husbandId, isNotNull);
      expect(partnership.wifeId, isNotNull);
      expect(partnership.partnerIds.toSet(), {a, b});
    });

    test('unknown gender is supported', () async {
      final a = await addPerson(firstName: 'A', gender: 'unknown');
      final b = await addPerson(firstName: 'B', gender: '');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: a,
        personBId: b,
      );

      expect((await relationships.getPartnerships(treeId)).single.partnerIds.toSet(),
          {a, b});
    });

    test('the canonical slot rule is order-independent', () {
      final first = canonicalPartnerSlots(
        firstId: 'zzz',
        firstGender: 'M',
        secondId: 'aaa',
        secondGender: 'M',
      );
      final reversed = canonicalPartnerSlots(
        firstId: 'aaa',
        firstGender: 'M',
        secondId: 'zzz',
        secondGender: 'M',
      );
      expect(first, reversed);
      expect(first.husbandId, 'aaa', reason: 'ordered by id for same gender');

      final mixed = canonicalPartnerSlots(
        firstId: 'zzz',
        firstGender: 'M',
        secondId: 'aaa',
        secondGender: 'F',
      );
      expect(mixed.wifeId, 'aaa', reason: 'female takes the wife slot');
      expect(mixed.husbandId, 'zzz');
    });

    test('a person cannot be their own partner', () async {
      final id = await addPerson(firstName: 'Solo');

      await expectLater(
        relationships.addSpouseRelationship(
          treeId: treeId,
          personAId: id,
          personBId: id,
        ),
        throwsArgumentError,
      );
    });

    test('a deleted person cannot be given a partner', () async {
      final live = await addPerson(firstName: 'Live');
      final gone = await addPerson(firstName: 'Gone');
      await people.deletePerson(gone);

      await expectLater(
        relationships.addSpouseRelationship(
          treeId: treeId,
          personAId: live,
          personBId: gone,
        ),
        throwsArgumentError,
      );
    });

    test('a person from another tree cannot be given a partner', () async {
      final now = DateTime.now();
      await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              id: 'other-tree',
              treeName: 'Other',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final mine = await addPerson(firstName: 'Mine');
      final theirs = await addPerson(firstName: 'Theirs');
      await people.updatePerson(
        GenealogyPersonsCompanion(
          id: Value(theirs),
          treeId: const Value('other-tree'),
        ),
      );

      await expectLater(
        relationships.addSpouseRelationship(
          treeId: treeId,
          personAId: mine,
          personBId: theirs,
        ),
        throwsArgumentError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('parent-child rules', () {
    test('a single parent gets a single-parent family', () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      final family = (await relationships.getFamiliesForPerson(dad)).single;
      expect(family.wifeId, isNull);
      expect((await relationships.getParents(kid)).single.id, dad);
    });

    test('a child of a partnership has both partners as parents', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      expect(
        (await relationships.getParents(kid)).map((p) => p.id).toSet(),
        {dad, mom},
      );
      // One link row, two parent edges.
      expect(await db.select(db.familyChildrenV2).get(), hasLength(1));
      expect(
        (await relationships.getParentChildRelationships(treeId))
            .where((edge) => edge.childId == kid),
        hasLength(2),
      );
    });

    test('adding the same parent twice is a no-op', () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      expect(await db.select(db.familyChildrenV2).get(), hasLength(1));
    });

    test('a person cannot be their own parent', () async {
      final id = await addPerson(firstName: 'Solo');

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: id,
          childId: id,
        ),
        throwsArgumentError,
      );
    });

    test('the same parent cannot be recorded twice through different families',
        () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final other = await addPerson(firstName: 'Other', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      // A second, unrelated partnership for the same father.
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: other,
      );
      final firstFamily = (await relationships.getFamiliesForPerson(mom)).single;
      final secondFamily =
          (await relationships.getFamiliesForPerson(other)).single;

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
        familyId: firstFamily.id,
      );

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: dad,
          childId: kid,
          familyId: secondFamily.id,
        ),
        throwsStateError,
      );
    });

    test('an ambiguous parent must name the family', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom1 = await addPerson(firstName: 'Mom1', gender: 'F');
      final mom2 = await addPerson(firstName: 'Mom2', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom1,
      );
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom2,
      );

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: dad,
          childId: kid,
        ),
        throwsStateError,
      );

      final target = (await relationships.getFamiliesForPerson(mom2)).single;
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
        familyId: target.id,
      );
      expect(
        (await people.getChildrenForFamily(target.id)).single.childId,
        kid,
      );
    });

    test('a family from another tree is rejected', () async {
      final now = DateTime.now();
      await db.into(db.familyTrees).insert(
            FamilyTreesCompanion.insert(
              id: 'other-tree',
              treeName: 'Other',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');
      final foreignFamilyId = await people.createFamily(
        treeId: 'other-tree',
        husbandId: dad,
      );

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: dad,
          childId: kid,
          familyId: foreignFamilyId,
        ),
        throwsArgumentError,
      );
    });

    test('adoption and step parentage are recorded, not invented', () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
        relationshipType: 'adopted',
      );

      final edge = (await relationships.getParentChildRelationships(treeId))
          .firstWhere((e) => e.childId == kid);
      expect(edge.relationshipType, 'adopted');
    });

    test('a person with no recorded parents simply has none', () async {
      final orphan = await addPerson(firstName: 'Orphan');

      expect(await relationships.getParents(orphan), isEmpty);
      expect(await relationships.getFamiliesForPerson(orphan), isEmpty);
    });

    test('a child may have more than two parents across families', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final adoptiveDad = await addPerson(firstName: 'AdoptiveDad');
      final adoptiveMom = await addPerson(firstName: 'AdoptiveMom', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: adoptiveDad,
        personBId: adoptiveMom,
      );
      final birthFamilyId = (await relationships.getFamiliesForPerson(mom)).single;
      final adoptiveFamilyId =
          (await relationships.getFamiliesForPerson(adoptiveMom)).single;

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
        familyId: birthFamilyId.id,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: adoptiveDad,
        childId: kid,
        familyId: adoptiveFamilyId.id,
        relationshipType: 'adopted',
      );

      expect(await relationships.getParents(kid), hasLength(4));
      expect(await db.select(db.familyChildrenV2).get(), hasLength(2));
    });

    test('the only parent is not a co-parent, so removal needs no flag',
        () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      expect(
        await relationships.removeParentChildRelationship(
          treeId: treeId,
          parentId: dad,
          childId: kid,
        ),
        1,
      );
    });

    test('removing one parent of a couple is refused unless acknowledged',
        () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      await expectLater(
        relationships.removeParentChildRelationship(
          treeId: treeId,
          parentId: dad,
          childId: kid,
        ),
        throwsStateError,
      );

      expect(
        await relationships.removeParentChildRelationship(
          treeId: treeId,
          parentId: dad,
          childId: kid,
          removeCoParent: true,
        ),
        1,
      );
      expect(await relationships.getParents(kid), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('getters stay coherent', () {
    test('a three-generation tree reads back consistently', () async {
      final grandpa = await addPerson(firstName: 'Grandpa');
      final grandma = await addPerson(firstName: 'Grandma', gender: 'F');
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');
      final sibling = await addPerson(firstName: 'Sibling');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: grandpa,
        personBId: grandma,
      );
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final grandParentFamilyId =
          (await relationships.getFamiliesForPerson(grandma)).single;
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: grandpa,
        childId: dad,
        familyId: grandParentFamilyId.id,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: sibling,
      );

      expect((await relationships.getParents(dad)).map((p) => p.id).toSet(),
          {grandpa, grandma});
      expect((await relationships.getChildren(dad)).map((p) => p.id).toSet(),
          {kid, sibling});
      expect((await relationships.getSiblings(kid)).single.id, sibling);
      expect(await relationships.getSpouses(grandpa).then((s) => s.single.id),
          grandma);
      expect(await relationships.getFamiliesForPerson(dad), hasLength(1));
      expect(
        (await relationships.getPartnerships(treeId)),
        hasLength(2),
      );
      expect(
        (await relationships.getParentChildRelationships(treeId)),
        hasLength(6),
        reason: 'dad has two parents, kid and sibling two each',
      );
    });

    test('every getter hides a deleted person', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      await people.deletePerson(dad);

      expect((await relationships.getParents(kid)).map((p) => p.id), [mom]);
      expect(await relationships.getChildren(dad), isEmpty);
      expect(await relationships.getSpouses(dad), isEmpty);
      expect(await relationships.getSiblings(dad), isEmpty);
      expect(await relationships.getFamiliesForPerson(dad), isEmpty);
      expect(await relationships.getPartnerships(treeId), hasLength(1));
      expect(
        (await relationships.getPartnerships(treeId)).single.partnerIds,
        [mom],
      );
    });
  });
}

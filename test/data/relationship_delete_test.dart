// Regression tests for relationship removal, reworked in Phase 1.
//
// The old `RelationshipRepository.deleteRelationship(String)` accepted one
// opaque id that could be either a `families_v2` row or a `family_children_v2`
// link, and it deleted a family without clearing its child links — which made
// every "remove this marriage" call fail with an FK violation as soon as the
// couple had children. It is now two explicit, typed, soft-delete operations.

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
  }) {
    return repository.addPerson(
      treeId: treeId,
      firstName: firstName,
      gender: gender,
    );
  }

  Future<({String dad, String mom, String kid, String familyId, String linkId})>
      familyWithChild() async {
    final dad = await addPerson(firstName: 'Dad');
    final mom = await addPerson(firstName: 'Mom', gender: 'F');
    final kid = await addPerson(firstName: 'Kid');
    await relationships.addSpouseRelationship(
      treeId: treeId,
      personAId: dad,
      personBId: mom,
    );
    final familyId = (await repository.getFamiliesForPerson(dad)).single.id;
    await repository.addChildToFamily(familyId: familyId, childId: kid);
    final linkId = (await repository.getChildrenForFamily(familyId)).single.id;
    return (dad: dad, mom: mom, kid: kid, familyId: familyId, linkId: linkId);
  }

  group('removing a child link', () {
    test('soft-deletes the link and keeps the family', () async {
      final family = await familyWithChild();

      expect(await relationships.removeParentChildLink(family.linkId), 1);

      expect(
        (await db.select(db.familyChildrenV2).get()).single.isDeleted,
        isTrue,
      );
      expect((await db.select(db.familiesV2).get()).single.isDeleted, isFalse);
      expect(await relationships.getChildren(family.dad), isEmpty);
    });

    test('is idempotent and reports nothing removed the second time', () async {
      final family = await familyWithChild();

      expect(await relationships.removeParentChildLink(family.linkId), 1);
      expect(await relationships.removeParentChildLink(family.linkId), 0);
    });

    test('reports 0 for an unknown link', () async {
      expect(await relationships.removeParentChildLink('does-not-exist'), 0);
    });

    test('re-adding the same parent-child link restores it', () async {
      final family = await familyWithChild();
      await relationships.removeParentChildLink(family.linkId);
      expect(await relationships.getChildren(family.dad), isEmpty);

      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: family.dad,
        childId: family.kid,
      );

      expect(
        (await relationships.getChildren(family.dad)).single.id,
        family.kid,
      );
      // Restored, not duplicated: UNIQUE(family_id, child_id) still holds.
      expect(await db.select(db.familyChildrenV2).get(), hasLength(1));
    });
  });

  group('dissolving a family', () {
    test('refuses while the family still has child links', () async {
      final family = await familyWithChild();

      await expectLater(
        relationships.dissolveFamily(family.familyId),
        throwsStateError,
      );

      expect((await db.select(db.familiesV2).get()).single.isDeleted, isFalse);
      expect(
        (await db.select(db.familyChildrenV2).get()).single.isDeleted,
        isFalse,
      );
      expect(await relationships.getSpouses(family.mom), isNotEmpty);
    });

    test('dissolves the family and the child links when asked explicitly',
        () async {
      final family = await familyWithChild();

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
      expect(await relationships.getSpouses(family.dad), isEmpty);
      expect(await relationships.getChildren(family.dad), isEmpty);
      // People are untouched.
      expect((await repository.getPersonById(family.kid))!.isDeleted, isFalse);
      expect((await repository.getPersonById(family.mom))!.isDeleted, isFalse);
    });

    test('a childless family dissolves without extra flags', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final familyId = (await repository.getFamiliesForPerson(dad)).single.id;

      expect(await relationships.dissolveFamily(familyId), 1);
      expect(await relationships.getSpouses(dad), isEmpty);
    });

    test('is idempotent', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final familyId = (await repository.getFamiliesForPerson(dad)).single.id;

      expect(await relationships.dissolveFamily(familyId), 1);
      expect(await relationships.dissolveFamily(familyId), 0);
    });

    test('an unknown family is reported', () async {
      await expectLater(
        relationships.dissolveFamily('does-not-exist'),
        throwsArgumentError,
      );
    });
  });

  group('adding relationships validates its input', () {
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

    test('a person cannot be their own spouse', () async {
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

    test('an unknown person cannot be linked', () async {
      final id = await addPerson(firstName: 'Real');

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: 'ghost',
          childId: id,
        ),
        throwsArgumentError,
      );
      await expectLater(
        relationships.addSpouseRelationship(
          treeId: treeId,
          personAId: id,
          personBId: 'ghost',
        ),
        throwsArgumentError,
      );
    });

    test('a removed person cannot be linked', () async {
      final real = await addPerson(firstName: 'Real');
      final gone = await addPerson(firstName: 'Gone');
      await repository.deletePerson(gone);

      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: gone,
          childId: real,
        ),
        throwsArgumentError,
      );
    });

    test('linking the same pair twice is a no-op', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');

      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
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
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      expect(await db.select(db.familiesV2).get(), hasLength(1));
      expect(await db.select(db.familyChildrenV2).get(), hasLength(1));
    });

    test('a parent with several families must name the family for a new child',
        () async {
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
      expect(await repository.getFamiliesForPerson(dad), hasLength(2));

      // Ambiguous: refuse rather than silently attaching to an arbitrary
      // family.
      await expectLater(
        relationships.addParentChildRelationship(
          treeId: treeId,
          parentId: dad,
          childId: kid,
        ),
        throwsStateError,
      );

      final target = (await repository.getFamiliesForPerson(mom2)).single.id;
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
        familyId: target,
      );

      expect(
        (await repository.getChildrenForFamily(target)).single.childId,
        kid,
      );
    });
  });
}

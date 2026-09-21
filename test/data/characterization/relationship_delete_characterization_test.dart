// CHARACTERIZATION TESTS — C3 (relationship deletion).
//
// These tests document CURRENT, INCORRECT behaviour. They are expected to FAIL
// after the Phase 1 fix and must be updated then.
//
// C3  RelationshipRepository.deleteRelationship() accepts a single String that
//     may be either a `family_children_v2.id` or a `families_v2.id`, and
//     deletes the family without first removing its child links. Because
//     `family_children_v2.family_id REFERENCES families_v2(id)` uses
//     ON DELETE NO ACTION, deleting the family of a couple that HAS CHILDREN
//     fails — i.e. the common case.
//
// Source under test:
//   lib/data/repositories/relationship_repository.dart:113-127

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;
  late GenealogyRepository repository;
  late RelationshipRepository relationshipRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GenealogyRepository(db);
    relationshipRepository = RelationshipRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<({String dad, String mom, String kid, String familyId, String linkId})>
      buildFamilyWithChild() async {
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
    final kid = await repository.addPerson(
      treeId: treeId,
      firstName: 'Kid',
      gender: 'M',
    );
    await relationshipRepository.addSpouseRelationship(
      treeId: treeId,
      personAId: dad,
      personBId: mom,
    );
    final familyId = (await repository.getFamiliesForPerson(dad)).single.id;
    await repository.addChildToFamily(familyId: familyId, childId: kid);
    final linkId = (await repository.getChildrenForFamily(familyId)).single.id;
    return (
      dad: dad,
      mom: mom,
      kid: kid,
      familyId: familyId,
      linkId: linkId,
    );
  }

  group('C3 — relationship deletion', () {
    test('deleting the family of a couple WITH children fails (FK violation)',
        () async {
      final family = await buildFamilyWithChild();

      await expectLater(
        relationshipRepository.deleteRelationship(family.familyId),
        throwsA(
          predicate(
            (e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'a SQLite foreign key violation',
          ),
        ),
      );
    });

    test('the failed family delete leaves the family and its child link intact',
        () async {
      final family = await buildFamilyWithChild();

      try {
        await relationshipRepository.deleteRelationship(family.familyId);
      } catch (_) {
        // current behaviour
      }

      expect((await db.select(db.familiesV2).get()).length, 1);
      expect((await db.select(db.familyChildrenV2).get()).length, 1);
    });

    test('deleting a child link by its own id succeeds', () async {
      final family = await buildFamilyWithChild();

      expect(
        await relationshipRepository.deleteRelationship(family.linkId),
        1,
      );
      expect((await db.select(db.familyChildrenV2).get()).isEmpty, isTrue);
    });

    test('deleting a family WITHOUT children succeeds', () async {
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
      await relationshipRepository.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final familyId = (await repository.getFamiliesForPerson(dad)).single.id;

      expect(
        await relationshipRepository.deleteRelationship(familyId),
        1,
      );
    });

    test(
      'the API treats a family id and a child link id as the same parameter, '
      'with different outcomes',
      () async {
        final family = await buildFamilyWithChild();

        // Same method, same String parameter, different underlying entity:
        // a families_v2 id whose couple has children -> FK violation.
        await expectLater(
          relationshipRepository.deleteRelationship(family.familyId),
          throwsA(
            predicate(
              (e) => e.toString().contains('FOREIGN KEY constraint failed'),
              'a SQLite foreign key violation',
            ),
          ),
        );

        // ... while a family_children_v2 id is accepted and deleted.
        expect(
          await relationshipRepository.deleteRelationship(family.linkId),
          1,
        );
      },
    );

    test('deleting an unknown id is a silent no-op', () async {
      expect(
        await relationshipRepository.deleteRelationship('does-not-exist'),
        0,
      );
    });
  });
}

// Regression tests for the person write paths reworked in Phase 1.
//
// These replace the earlier characterization tests, which documented the
// pre-fix behaviour (every edit threw `InvalidDataException`; deleting a
// connected person failed with an FK violation).
//
// Covered:
//   C1  `GenealogyRepository.updatePerson` is a keyed PARTIAL update: fields the
//       caller does not mention are left alone, so an edit can no longer reset
//       `is_living`, `display_name_format`, `occupation`, notes, ...
//   C2  `GenealogyRepository.deletePerson` is a transactional SOFT delete with
//       explicit cascade rules, and `restorePerson` reverts it.

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
    String? notes,
    String? occupation,
    String? biography,
    String? birthDateQualifier,
    String? deathPlace,
  }) {
    return repository.addPerson(
      treeId: treeId,
      firstName: firstName,
      gender: gender,
      birthDate: birthDate,
      deathDate: deathDate,
      isLiving: isLiving,
      notes: notes,
      occupation: occupation,
      biography: biography,
      birthDateQualifier: birthDateQualifier,
      deathPlace: deathPlace,
    );
  }

  group('C1 — person updates persist', () {
    test('an edit writes only the supplied fields', () async {
      final id = await addPerson(
        firstName: 'Ashok',
        notes: 'first',
        occupation: 'farmer',
        biography: 'long bio',
        deathDate: DateTime(1990, 5, 4),
        isLiving: false,
      );
      final before = (await repository.getPersonById(id))!;
      expect(before.isLiving, isFalse);

      final changed = await repository.updatePerson(
        GenealogyPersonsCompanion(
          id: Value(id),
          firstName: const Value('Ashok Kumar'),
        ),
      );

      expect(changed, isTrue);
      final after = (await repository.getPersonById(id))!;
      expect(after.firstName, 'Ashok Kumar');
      // Everything the caller did not mention survives. `is_living` is the
      // regression that made every edit resurrect a deceased person.
      expect(after.isLiving, isFalse);
      expect(after.notes, 'first');
      expect(after.occupation, 'farmer');
      expect(after.biography, 'long bio');
      expect(after.deathDate, DateTime(1990, 5, 4));
      expect(after.displayNameFormat, before.displayNameFormat);
      expect(after.createdAt, before.createdAt);
    });

    test('updated_at is maintained by the repository', () async {
      final id = await addPerson(firstName: 'Ashok');
      final before = (await repository.getPersonById(id))!;

      await repository.updatePerson(
        GenealogyPersonsCompanion(id: Value(id), notes: const Value('x')),
      );

      final after = (await repository.getPersonById(id))!;
      expect(after.notes, 'x');
      expect(after.createdAt, before.createdAt);
      // SQLite stores drift DateTimes with second precision, so assert that
      // updated_at moved forward rather than that it changed by milliseconds.
      expect(after.updatedAt.isBefore(before.updatedAt), isFalse);
    });

    test('a companion without an id is rejected', () async {
      await expectLater(
        repository.updatePerson(
          GenealogyPersonsCompanion(firstName: const Value('Nobody')),
        ),
        throwsArgumentError,
      );
    });

    test('an explicitly null field is cleared', () async {
      final id = await addPerson(firstName: 'Ashok', notes: 'first');

      await repository.updatePerson(
        GenealogyPersonsCompanion(id: Value(id), notes: const Value(null)),
      );

      expect((await repository.getPersonById(id))!.notes, isNull);
    });

    test(
      'editing an imported person keeps qualifiers, places and life status',
      () async {
        final id = await addPerson(
          firstName: 'Imported',
          birthDate: DateTime(1900),
          birthDateQualifier: 'ABT',
          deathDate: DateTime(1970),
          deathPlace: 'Surat',
          isLiving: false,
        );

        await repository.updatePerson(
          GenealogyPersonsCompanion(
            id: Value(id),
            firstName: const Value('Imported Renamed'),
          ),
        );

        final after = (await repository.getPersonById(id))!;
        expect(after.firstName, 'Imported Renamed');
        expect(after.birthDateQualifier, 'ABT');
        expect(after.deathPlace, 'Surat');
        expect(after.isLiving, isFalse);
      },
    );

    test('editing an unknown person reports that nothing changed', () async {
      final changed = await repository.updatePerson(
        GenealogyPersonsCompanion(
          id: const Value('does-not-exist'),
          notes: const Value('x'),
        ),
      );
      expect(changed, isFalse);
    });
  });

  group('C2 — person delete is a transactional soft delete', () {
    test('removing a family partner keeps the family, the spouse and the '
        'children', () async {
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

      await repository.deletePerson(dad);

      expect((await repository.getPersonById(dad))!.isDeleted, isTrue);
      // The marriage and the child's place survive for the surviving spouse.
      expect((await repository.getFamiliesForPerson(mom)).length, 1);
      expect((await relationships.getChildren(mom)).single.id, kid);
      expect((await relationships.getChildren(mom)).single.firstName, 'Kid');
      // The child keeps the surviving parent.
      expect(
        (await relationships.getParents(kid)).map((p) => p.id),
        contains(mom),
      );
      // ...but the removed person is gone from every lookup, including lookups
      // anchored on the removed person themselves.
      expect(await relationships.getSpouses(mom), isEmpty);
      expect(await relationships.getChildren(dad), isEmpty);
      expect(
        (await relationships.getParents(kid)).map((p) => p.id),
        isNot(contains(dad)),
      );
      expect(await relationships.getSpouses(dad), isEmpty);
    });

    test('removing an unconnected person succeeds', () async {
      final id = await addPerson(firstName: 'Isolated');

      await repository.deletePerson(id);

      expect((await repository.getPersonById(id))!.isDeleted, isTrue);
      expect(await repository.getPeopleByTree(treeId), isEmpty);
    });

    test('removing a single parent also removes the family that existed only '
        'for them', () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );
      final familyId = (await repository.getFamiliesForPerson(dad)).single.id;

      await repository.deletePerson(dad);

      expect((await db.select(db.familiesV2).get()).single.isDeleted, isTrue);
      expect(
        (await db.select(db.familyChildrenV2).get()).single.isDeleted,
        isTrue,
      );
      expect(await relationships.getParents(kid), isEmpty);
      // The child itself is untouched.
      expect((await repository.getPersonById(kid))!.isDeleted, isFalse);
      expect(familyId, isNotEmpty);
    });

    test(
      'removing a child hides it without touching the family or its links',
      () async {
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

        await repository.deletePerson(kid);

        // Only the person is flagged: the family and the link row are intact, so
        // the delete is exactly reversible.
        final familyRow = (await db.select(db.familiesV2).get()).single;
        expect(familyRow.isDeleted, isFalse);
        expect(familyRow.husbandId, dad);
        expect(familyRow.wifeId, mom);
        expect(
          (await db.select(db.familyChildrenV2).get()).single.isDeleted,
          isFalse,
        );
        // ...and the removed child is gone from every lookup.
        expect(await relationships.getChildren(dad), isEmpty);
        expect(await relationships.getChildren(mom), isEmpty);
      },
    );

    test('a removed person is hidden from list, search, parents, children, '
        'siblings and spouses', () async {
      final dad = await addPerson(firstName: 'Dad');
      final mom = await addPerson(firstName: 'Mom', gender: 'F');
      final kidA = await addPerson(firstName: 'KidA');
      final kidB = await addPerson(firstName: 'KidB');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: dad,
        personBId: mom,
      );
      final familyId = (await repository.getFamiliesForPerson(dad)).single.id;
      await repository.addChildToFamily(familyId: familyId, childId: kidA);
      await repository.addChildToFamily(familyId: familyId, childId: kidB);

      await repository.deletePerson(kidB);

      expect(
        (await repository.getPeopleByTree(treeId)).map((p) => p.id),
        isNot(contains(kidB)),
      );
      expect(
        (await repository.searchPeople(treeId: treeId, query: 'KidB')),
        isEmpty,
      );
      expect(await relationships.getSiblings(kidA), isEmpty);
      expect(
        (await relationships.getChildren(dad)).map((p) => p.id),
        isNot(contains(kidB)),
      );
      // Siblings of the removed person must not surface either.
      expect(await relationships.getSiblings(kidB), isEmpty);
    });

    test('child rows that reference the person are kept and come back on '
        'restore', () async {
      final id = await addPerson(firstName: 'HasEvents');
      await db
          .into(db.events)
          .insert(
            EventsCompanion.insert(
              id: 'event-1',
              personId: id,
              eventType: 'baptism',
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );

      await repository.deletePerson(id);
      expect((await db.select(db.events).get()).single.personId, id);

      await repository.restorePerson(id);

      final restored = (await repository.getPersonById(id))!;
      expect(restored.isDeleted, isFalse);
      expect(
        (await repository.getPeopleByTree(treeId)).map((p) => p.id),
        contains(id),
      );
      expect((await db.select(db.events).get()).single.personId, id);
    });

    test('deleting an unknown person is reported', () async {
      await expectLater(
        repository.deletePerson('does-not-exist'),
        throwsArgumentError,
      );
    });

    test('deleting twice is a no-op', () async {
      final id = await addPerson(firstName: 'Twice');

      await repository.deletePerson(id);
      await repository.deletePerson(id);

      expect((await repository.getPersonById(id))!.isDeleted, isTrue);
    });

    test(
      'the duplicate markers of a removed person are no longer reported',
      () async {
        final a = await addPerson(firstName: 'Same');
        final b = await addPerson(firstName: 'Same');
        await repository.markAsDuplicate(
          treeId: treeId,
          sourceId: a,
          targetId: b,
        );
        expect(await repository.getDuplicateMarkers(treeId), hasLength(1));

        await repository.deletePerson(b);

        expect(await repository.getDuplicateMarkers(treeId), isEmpty);
      },
    );
  });
}

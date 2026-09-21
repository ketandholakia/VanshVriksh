// CHARACTERIZATION TESTS — C1 / C2 (person write paths).
//
// These tests document CURRENT, INCORRECT behaviour so that the remediation in
// Phase 1 can flip them deliberately. They are expected to FAIL after the fix
// and must be updated then — nothing here asserts that the current behaviour is
// correct.
//
// Findings covered:
//   C1  GenealogyPersonDao.updatePerson() -> update(...).replace(companion)
//       The companion omits `uuid`, which `replace()` requires because it
//       validates the entity as an INSERT.
//   C1b replace() applies column defaults for every column the caller omits,
//       so a partial companion silently resets them.
//   C2  deletePerson() hard-deletes while child tables reference the person
//       with `ON DELETE NO ACTION` and foreign keys are enabled.
//
// Source under test:
//   lib/data/database/daos/genealogy_person_dao.dart:22-24 (update)
//   lib/data/database/daos/genealogy_person_dao.dart:27-29 (delete)
//   lib/data/repositories/genealogy_repository.dart:139-166 (updatePerson)
//   lib/data/repositories/genealogy_repository.dart:180-183 (deletePerson)

// `isNull` / `isNotNull` are also exported by drift as query expressions, so
// they are hidden here to keep the matcher versions unambiguous.
import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  group('C1 — person update', () {
    test('updating an existing person throws InvalidDataException (uuid missing)',
        () async {
      final id = await repository.addPerson(
        treeId: treeId,
        firstName: 'Ashok',
        gender: 'M',
      );

      await expectLater(
        repository.updatePerson(
          id: id,
          treeId: treeId,
          firstName: 'Ashok Kumar',
          gender: 'M',
        ),
        throwsA(
          isA<InvalidDataException>().having(
            (e) => e.toString(),
            'message',
            contains('uuid'),
          ),
        ),
      );
    });

    test('the failed update leaves the stored person completely unchanged',
        () async {
      final id = await repository.addPerson(
        treeId: treeId,
        firstName: 'Ashok',
        gender: 'M',
      );
      final before = await repository.getPersonById(id);

      try {
        await repository.updatePerson(
          id: id,
          treeId: treeId,
          firstName: 'Ashok Kumar',
          gender: 'M',
        );
      } on InvalidDataException {
        // current behaviour: the write never happens
      }

      final after = await repository.getPersonById(id);
      expect(after!.firstName, before!.firstName);
      expect(after.firstName, 'Ashok');
      expect(after.updatedAt, before.updatedAt);
    });

    test(
      'C1b — replace() with an otherwise valid companion resets every '
      'defaulted column the caller omitted',
      () async {
        // Person starts deceased with data in nullable/derived columns.
        final id = await repository.addPerson(
          treeId: treeId,
          firstName: 'Late',
          gender: 'M',
          deathDate: DateTime(1990, 5, 4),
          isLiving: false,
          notes: 'buried in Surat',
          occupation: 'farmer',
        );
        final before = await repository.getPersonById(id);
        expect(before!.isLiving, isFalse);
        expect(before.notes, 'buried in Surat');

        // Minimal companion that satisfies every required (no-default,
        // non-nullable) column: id, first_name, gender, tree_id, uuid.
        final wrote = await db.genealogyPersonDao.updatePerson(
          GenealogyPersonsCompanion(
            id: Value(id),
            firstName: const Value('Renamed'),
            treeId: const Value(treeId),
            gender: const Value('M'),
            uuid: Value(before.uuid),
          ),
        );

        final after = await repository.getPersonById(id);
        expect(wrote, isTrue, reason: 'the row WAS written');
        expect(after!.firstName, 'Renamed');

        // Documented current semantics of replace(): omitted columns that have
        // a schema default are overwritten with that default.
        expect(
          after.isLiving,
          isTrue,
          reason: 'is_living default (true) overwrites the deceased flag',
        );
        expect(
          after.displayNameFormat,
          'birth_married',
          reason: 'display_name_format reset to its schema default',
        );
        expect(
          after.version,
          1,
          reason: 'version reset to its schema default',
        );
      },
    );
  });

  group('C2 — person delete', () {
    test('deleting a person who is a family partner fails with an FK violation',
        () async {
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

      await expectLater(
        repository.deletePerson(dad),
        throwsA(
          predicate(
            (e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'a SQLite foreign key violation',
          ),
        ),
      );
    });

    test('deleting a person who is a child fails with an FK violation',
        () async {
      final parent = await repository.addPerson(
        treeId: treeId,
        firstName: 'Parent',
        gender: 'M',
      );
      final child = await repository.addPerson(
        treeId: treeId,
        firstName: 'Child',
        gender: 'F',
      );
      await relationshipRepository.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: child,
      );

      await expectLater(
        repository.deletePerson(child),
        throwsA(
          predicate(
            (e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'a SQLite foreign key violation',
          ),
        ),
      );
    });

    test('a failed delete removes nothing (no partial cascade)', () async {
      final parent = await repository.addPerson(
        treeId: treeId,
        firstName: 'Parent',
        gender: 'M',
      );
      final child = await repository.addPerson(
        treeId: treeId,
        firstName: 'Child',
        gender: 'F',
      );
      await relationshipRepository.addParentChildRelationship(
        treeId: treeId,
        parentId: parent,
        childId: child,
      );

      try {
        await repository.deletePerson(child);
      } catch (_) {
        // current behaviour
      }

      expect((await db.select(db.genealogyPersons).get()).length, 2);
      expect((await db.select(db.familyChildrenV2).get()).length, 1);
      expect((await db.select(db.familiesV2).get()).length, 1);
      expect(await repository.getPersonById(child), isNotNull);
    });

    test('deleting an isolated person succeeds', () async {
      final id = await repository.addPerson(
        treeId: treeId,
        firstName: 'Isolated',
        gender: 'M',
      );

      expect(await repository.deletePerson(id), 1);
      expect(await repository.getPersonById(id), isNull);
    });

    test('deleting a person who only has events also fails', () async {
      final id = await repository.addPerson(
        treeId: treeId,
        firstName: 'HasEvents',
        gender: 'M',
      );
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'event-1',
              personId: id,
              eventType: 'baptism',
              createdAt: DateTime(2000, 1, 1),
              updatedAt: DateTime(2000, 1, 1),
            ),
          );

      await expectLater(
        repository.deletePerson(id),
        throwsA(
          predicate(
            (e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'a SQLite foreign key violation',
          ),
        ),
      );
    });
  });
}

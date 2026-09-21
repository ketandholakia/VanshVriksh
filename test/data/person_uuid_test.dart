// Phase 2: the person UUID lifecycle.
//
// Decision C (retain internal): `genealogy_persons.uuid` is a stable identity
// assigned once at insert and never rewritten — but no application code looks
// anyone up by it. These tests pin that contract: generation, uniqueness,
// survival across update / soft delete / restore / merge, and assignment on
// the Phase 1A composite path and the GEDCOM import path.
//
// Deliberately no `getPersonByUuid` API or test exists: there is no consumer
// for it, and the phase forbids speculative lookup APIs.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/models/person_save_data.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/services/person_save_service.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_importer.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_parser.dart';

import '../support/test_database.dart';
import 'domain_invariants_test.dart' as check;

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;
  late GenealogyRepository people;
  late PersonSaveService save;

  setUp(() async {
    db = await createTestDatabase();
    people = GenealogyRepository(db);
    save = PersonSaveService(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  group('uuid generation', () {
    test('every new person gets a uuid distinct from its row id', () async {
      final id = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'male',
      );

      final person = (await people.getPersonById(id))!;
      expect(person.uuid.isNotEmpty, isTrue);
      expect(person.uuid, isNot(id));
    });

    test('uuids are unique across people', () async {
      final ids = <String>[];
      for (final name in ['A', 'B', 'C', 'D']) {
        ids.add(
          await people.addPerson(
            treeId: treeId,
            firstName: name,
            gender: 'male',
          ),
        );
      }

      final uuids = [
        for (final id in ids) (await people.getPersonById(id))!.uuid,
      ];
      expect(uuids.toSet(), hasLength(ids.length));
    });

    test('the composite save path assigns a uuid too', () async {
      final child = await people.addPerson(
        treeId: treeId,
        firstName: 'Child',
        gender: 'male',
      );
      final parent = await save.createPersonAsParent(
        treeId: treeId,
        person: const PersonSaveData(firstName: 'Dad', gender: 'male'),
        childId: child,
      );

      final created = (await people.getPersonById(parent))!;
      expect(created.uuid.isNotEmpty, isTrue);
      expect(created.uuid, isNot(parent));
    });
  });

  // ---------------------------------------------------------------------------
  group('uuid stability', () {
    test('ordinary updates never rewrite the uuid', () async {
      final id = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'male',
      );
      final before = (await people.getPersonById(id))!.uuid;

      await people.updatePerson(
        GenealogyPersonsCompanion(
          id: Value(id),
          firstName: const Value('Rama'),
          biography: const Value('updated'),
          notes: const Value('updated'),
          isPrivate: const Value(true),
        ),
      );

      expect((await people.getPersonById(id))!.uuid, before);
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('soft delete and restore preserve the uuid', () async {
      final id = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'male',
      );
      final before = (await people.getPersonById(id))!.uuid;

      await people.deletePerson(id);
      expect((await people.getPersonById(id))!.uuid, before);

      await people.restorePerson(id);
      expect((await people.getPersonById(id))!.uuid, before);
      expect(await check.violatedInvariants(db), isEmpty);
    });

    test('merge keeps both the survivor and the duplicate uuid', () async {
      final survivor = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'male',
      );
      final duplicate = await people.addPerson(
        treeId: treeId,
        firstName: 'Ram',
        gender: 'male',
      );
      final survivorUuid = (await people.getPersonById(survivor))!.uuid;
      final duplicateUuid = (await people.getPersonById(duplicate))!.uuid;
      expect(survivorUuid, isNot(duplicateUuid));

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      final afterSurvivor = (await people.getPersonById(survivor))!;
      expect(afterSurvivor.uuid, survivorUuid);
      expect(afterSurvivor.mergedIntoId, isNull);

      final retired = (await people.getPersonById(duplicate))!;
      expect(retired.uuid, duplicateUuid);
      expect(retired.mergedIntoId, survivor);
      expect(await check.violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('uuid on the import path', () {
    test('gedcom import assigns a usable uuid to every person', () async {
      const gedcom = '''
0 @I1@ INDI
1 NAME John /Doe/
1 SEX M
0 @I2@ INDI
1 NAME Jane /Doe/
1 SEX F
0 @F1@ FAM
1 HUSB @I1@
1 WIFE @I2@
''';
      final nodes = GedcomParser.parseLines(gedcom.split('\n'));
      await GedcomImporter(db).importGedcom(nodes, treeId);

      final persons = await people.getPeopleByTree(treeId);
      expect(persons, hasLength(2));
      for (final person in persons) {
        expect(person.uuid.isNotEmpty, isTrue);
      }
      final uuids = persons.map((p) => p.uuid).toSet();
      expect(uuids, hasLength(2));
      expect(await check.violatedInvariants(db), isEmpty);
    });
  });
}

// The GEDCOM exporter, exercised primarily as a round trip: export a tree
// from a source database, import the produced file into a fresh one, and
// assert the family structure came out the other side.
//
// The exporter's output must be deterministic (same data, byte-identical
// file), standards-shaped (HEAD/CHAR/TRLR, `DD MMM YYYY` dates, CONT-folded
// notes) and honest about what it preserves.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/core/constants/app_constants.dart';
import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/models/person_save_data.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';
import 'package:vanshvriksh/data/services/person_save_service.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_exporter.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_importer.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_parser.dart';

import '../../support/test_database.dart';

void main() {
  const treeId = AppConstants.defaultTreeId;

  late AppDatabase db;
  late GenealogyRepository people;
  late PersonSaveService saves;

  setUp(() async {
    db = await createTestDatabase();
    people = GenealogyRepository(db);
    saves = PersonSaveService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> personName({
    required String firstName,
    String? lastName,
    String gender = 'male',
    DateTime? birthDate,
    String? birthDateQualifier,
    String? birthPlace,
    String? notes,
  }) {
    return people.addPerson(
      treeId: treeId,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      birthDate: birthDate,
      birthDateQualifier: birthDateQualifier,
      birthPlace: birthPlace,
      notes: notes,
    );
  }

  /// Export [db], import the result into a fresh database, return it.
  Future<AppDatabase> roundTrip() async {
    final gedcom = await GedcomExporter().exportTree(db, treeId);
    final target = await createTestDatabase();
    final nodes = GedcomParser.parseLines(const LineSplitter().convert(gedcom));
    await GedcomImporter(target).importGedcom(nodes, treeId);
    addTearDown(target.close);
    return target;
  }

  test('produces a well-formed document', () async {
    await personName(firstName: 'Solo');
    final gedcom = await GedcomExporter().exportTree(db, treeId);

    expect(gedcom, startsWith('0 HEAD\r\n'));
    expect(gedcom, contains('1 GEDC\r\n2 VERS 5.5.1\r\n2 FORM LINEAGE-LINKED'));
    expect(gedcom, contains('1 CHAR UTF-8'));
    expect(gedcom, contains('1 SOUR VANSHVRIKSH'));
    expect(gedcom, endsWith('0 TRLR\r\n'));
    expect(gedcom, contains('0 @I1@ INDI'));
  });

  test('an empty tree exports only the envelope', () async {
    final gedcom = await GedcomExporter().exportTree(db, treeId);
    expect(gedcom, isNot(contains(' INDI')));
    expect(gedcom, isNot(contains(' FAM')));
  });

  test('round-trips a couple with a child, dates and places', () async {
    final father = await personName(
      firstName: 'Ramanbhai',
      lastName: 'Patel',
      gender: 'male',
      birthDate: DateTime(1920, 3, 15),
      birthPlace: 'Surat, India',
    );
    final mother = await personName(
      firstName: 'Maniben',
      lastName: 'Patel',
      gender: 'female',
    );
    // The couple first, so the child joins one family with both parents.
    await RelationshipRepository(db).addSpouseRelationship(
      treeId: treeId,
      personAId: father,
      personBId: mother,
    );
    await saves.createPersonAsChild(
      treeId: treeId,
      person: PersonSaveData(
        firstName: 'Kirit',
        gender: 'male',
        lastName: 'Patel',
      ),
      parentId: father,
      coParentIds: [mother],
    );

    final target = await roundTrip();

    final imported = await target.select(target.genealogyPersons).get();
    expect(imported, hasLength(3));

    final importedFather = imported.firstWhere(
      (person) => person.firstName == 'Ramanbhai',
    );
    expect(importedFather.lastName, 'Patel');
    expect(importedFather.gender, 'male');
    expect(importedFather.birthDate, DateTime(1920, 3, 15));
    expect(importedFather.birthPlace, 'Surat, India');

    // The couple: one family, canonically slotted.
    final families = await target.select(target.familiesV2).get();
    expect(families, hasLength(1));
    expect(families.single.husbandId, importedFather.id);
    expect(
      families.single.wifeId,
      imported.firstWhere((person) => person.firstName == 'Maniben').id,
    );

    // The child hangs under that family.
    final links = await target.select(target.familyChildrenV2).get();
    expect(links, hasLength(1));
    expect(links.single.familyId, families.single.id);
    expect(
      imported
          .firstWhere((person) => person.id == links.single.childId)
          .firstName,
      'Kirit',
    );
  });

  test('round-trips qualifiers and year-only dates', () async {
    await personName(
      firstName: 'Approx',
      birthDate: DateTime(1870, 5, 1),
      birthDateQualifier: 'ABT',
    );
    await personName(firstName: 'YearOnly', birthDate: DateTime(1900));

    final gedcom = await GedcomExporter().exportTree(db, treeId);
    expect(gedcom, contains('2 DATE ABT MAY 1870'));
    expect(gedcom, contains('2 DATE 1900'));

    final target = await roundTrip();
    final imported = await target.select(target.genealogyPersons).get();

    final approx = imported.firstWhere(
      (person) => person.firstName == 'Approx',
    );
    expect(approx.birthDate, DateTime(1870, 5, 1));
    expect(approx.birthDateQualifier, 'ABT');

    final yearOnly = imported.firstWhere(
      (person) => person.firstName == 'YearOnly',
    );
    expect(yearOnly.birthDate, DateTime(1900));
  });

  test('round-trips multi-line notes through CONT', () async {
    await personName(firstName: 'Noted', notes: 'line one\nline two');

    final gedcom = await GedcomExporter().exportTree(db, treeId);
    expect(gedcom, contains('1 NOTE line one'));
    expect(gedcom, contains('2 CONT line two'));

    final target = await roundTrip();
    final imported = await target.select(target.genealogyPersons).get();
    expect(
      imported.firstWhere((person) => person.firstName == 'Noted').notes,
      'line one\nline two',
    );
  });

  test('round-trips remarriage as two families', () async {
    final person = await personName(firstName: 'Twice Married', gender: 'male');
    await people.createFamily(
      treeId: treeId,
      husbandId: person,
      wifeId: await personName(firstName: 'First Wife', gender: 'female'),
    );
    await people.createFamily(
      treeId: treeId,
      husbandId: person,
      wifeId: await personName(firstName: 'Second Wife', gender: 'female'),
    );

    final gedcom = await GedcomExporter().exportTree(db, treeId);
    expect(gedcom, contains('0 @F1@ FAM'));
    expect(gedcom, contains('0 @F2@ FAM'));
    // Two families, each with two partners: four FAMS lines in total.
    expect('1 FAMS'.allMatches(gedcom), hasLength(4));

    final target = await roundTrip();
    final imported = await target.select(target.genealogyPersons).get();
    final families = await target.select(target.familiesV2).get();
    expect(families, hasLength(2));
    final widower = imported.firstWhere(
      (person) => person.firstName == 'Twice Married',
    );
    expect(families.every((family) => family.husbandId == widower.id), isTrue);
  });

  test('round-trips a single-parent family', () async {
    final mother = await personName(firstName: 'Solo Mother', gender: 'female');
    await saves.createPersonAsChild(
      treeId: treeId,
      person: PersonSaveData(firstName: 'Solo Kid', gender: 'male'),
      parentId: mother,
    );

    final target = await roundTrip();
    final families = await target.select(target.familiesV2).get();
    expect(families, hasLength(1));
    expect(
      families.single.wifeId,
      isNotNull,
      reason: 'female-recorded single parent takes the wife slot',
    );
    expect(families.single.husbandId, isNull);
  });

  test('export is deterministic', () async {
    final father = await personName(firstName: 'A', lastName: 'Patel');
    await saves.createPersonAsChild(
      treeId: treeId,
      person: PersonSaveData(firstName: 'B', lastName: 'Patel', gender: 'male'),
      parentId: father,
    );

    final first = await GedcomExporter().exportTree(db, treeId);
    final second = await GedcomExporter().exportTree(db, treeId);
    expect(first, second);
  });

  test('carries the stable uuid as _UID', () async {
    await personName(firstName: 'Identified');
    final gedcom = await GedcomExporter().exportTree(db, treeId);
    expect(gedcom, matches(RegExp(r'1 _UID [0-9a-f-]{36}')));
  });
}

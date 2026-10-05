import 'package:flutter_test/flutter_test.dart';
import 'package:vanshvriksh/core/constants/app_constants.dart';
import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_parser.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_importer.dart';

import '../../support/test_database.dart';

void main() {
  group('GedcomImporter', () {
    late AppDatabase db;

    setUp(() async {
      db = await createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('imports persons and families', () async {
      final lines = [
        '0 @I1@ INDI',
        '1 NAME John /Doe/',
        '1 SEX M',
        '1 BIRT',
        '2 DATE 1900',
        '0 @I2@ INDI',
        '1 NAME Jane /Smith/',
        '1 SEX F',
        '0 @F1@ FAM',
        '1 HUSB @I1@',
        '1 WIFE @I2@',
      ];

      final nodes = GedcomParser.parseLines(lines);
      final importer = GedcomImporter(db);

      await importer.importGedcom(nodes, AppConstants.defaultTreeId);

      final persons = await db.select(db.genealogyPersons).get();
      expect(persons.length, 2);

      final john = persons.firstWhere((p) => p.firstName == 'John');
      expect(john.lastName, 'Doe');
      expect(john.gender, 'male');
      expect(john.birthDate?.year, 1900);

      final families = await db.select(db.familiesV2).get();
      expect(families.length, 1);
      expect(families.first.husbandId, john.id);
    });

    test('reports what it imported', () async {
      final lines = [
        '0 @I1@ INDI',
        '1 NAME John /Doe/',
        '0 @I2@ INDI',
        '1 NAME Jane /Smith/',
        '0 @F1@ FAM',
        '1 HUSB @I1@',
        '1 WIFE @I2@',
        '1 CHIL @I3@',
      ];
      // I3 is referenced but never defined, so the child link is dropped.
      final result = await GedcomImporter(db).importGedcom(
        GedcomParser.parseLines(lines),
        AppConstants.defaultTreeId,
      );

      expect(result.people, 2);
      expect(result.families, 1);
      expect(result.childLinks, 0);
      expect(result.warnings, isNotEmpty);
    });

    test('refuses a file with no GEDCOM records', () async {
      final nodes = GedcomParser.parseLines(const [
        'random text',
        'not a gedcom',
      ]);
      await expectLater(
        GedcomImporter(db).importGedcom(nodes, AppConstants.defaultTreeId),
        throwsFormatException,
      );
    });

    test(
      'skips records without cross-reference ids instead of crashing',
      () async {
        final nodes = GedcomParser.parseLines(const [
          '0 HEAD',
          '0 INDI',
          '1 NAME Orphan /NoXref/',
          '0 @I1@ INDI',
          '1 NAME Proper /Person/',
        ]);
        final result = await GedcomImporter(
          db,
        ).importGedcom(nodes, AppConstants.defaultTreeId);

        expect(result.people, 1);
        expect(result.warnings, isNotEmpty);
        final persons = await db.select(db.genealogyPersons).get();
        expect(persons.map((p) => p.firstName), ['Proper']);
      },
    );
  });
}

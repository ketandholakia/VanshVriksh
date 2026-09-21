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
  });
}

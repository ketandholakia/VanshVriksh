// Person bonds (the genogram's relationship dynamics) and the chart PNG
// exporter.
//
// Bond rules: canonical pair storage (argument order does not matter),
// re-adding retypes instead of duplicating, self/cross-tree/unknown-type all
// refused, removal removes exactly one row. The PNG exporter must produce a
// real PNG file (magic bytes) for a non-empty layout and refuse an empty one.

import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';
import 'package:vanshvriksh/features/settings/app_settings_provider.dart';
import 'package:vanshvriksh/features/tree/ancestor_tree_layout.dart';
import 'package:vanshvriksh/features/tree/chart_image_exporter.dart';

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

  Future<String> addPerson(String firstName, {String gender = 'M'}) =>
      people.addPerson(treeId: treeId, firstName: firstName, gender: gender);

  group('person bonds', () {
    test('stores the pair canonically, whichever order is given', () async {
      final a = await addPerson('Alice', gender: 'F');
      final b = await addPerson('Bob');

      await relationships.addPersonBond(
        treeId: treeId,
        personAId: b,
        personBId: a,
        bondType: 'close',
      );
      // Re-adding the same pair in the other order retypes, not duplicates.
      await relationships.addPersonBond(
        treeId: treeId,
        personAId: a,
        personBId: b,
        bondType: 'conflict',
      );

      final bonds = await relationships.getBondsForTree(treeId);
      expect(bonds, hasLength(1));
      expect(bonds.single.bondType, 'conflict');
      expect(bonds.single.personAId, a.compareTo(b) <= 0 ? a : b);
    });

    test('refuses self bonds, unknown types and cross-tree pairs', () async {
      final a = await addPerson('Alice');

      expect(
        () => relationships.addPersonBond(
          treeId: treeId,
          personAId: a,
          personBId: a,
          bondType: 'close',
        ),
        throwsArgumentError,
      );
      final bob = await addPerson('Bob');
      expect(
        () => relationships.addPersonBond(
          treeId: treeId,
          personAId: a,
          personBId: bob,
          bondType: 'soulmates',
        ),
        throwsArgumentError,
      );
    });

    test('removes exactly one row and is a no-op for absent pairs', () async {
      final a = await addPerson('Alice');
      final b = await addPerson('Bob');
      await relationships.addPersonBond(
        treeId: treeId,
        personAId: a,
        personBId: b,
        bondType: 'estranged',
      );

      expect(
        await relationships.removePersonBond(personAId: b, personBId: a),
        1,
      );
      expect(
        await relationships.removePersonBond(personAId: a, personBId: b),
        0,
      );
      expect(await relationships.getBondsForTree(treeId), isEmpty);
    });
  });

  group('chart PNG exporter', () {
    test('produces a real PNG for a small layout', () async {
      final outputDir = await Directory.systemTemp.createTemp('vvchart');
      final layout = computeAncestorTreeLayout(
        focusId: 'me',
        fatherOf: const {'me': 'dad'},
        motherOf: const {'me': 'mom'},
        maxGenerations: 4,
        cardSize: const Size(156, 72),
      );
      final person = _chartPerson('me', 'Test', 'Person');

      final file = await renderLayoutPng(
        layout: layout,
        people: {
          'me': person,
          'dad': _chartPerson('dad', 'Father', 'Person'),
          'mom': _chartPerson('mom', 'Mother', 'Person'),
        },
        rootId: 'me',
        dateFormat: DateDisplayFormat.yearOnly,
        fileNamePrefix: 'test_chart',
        outputDirectory: outputDir,
      );

      final bytes = await file.readAsBytes();
      // PNG magic: 89 50 4E 47.
      expect(bytes.take(4), [0x89, 0x50, 0x4E, 0x47]);
      expect(bytes.length, greaterThan(1000));
      expect(file.path, contains('test_chart'));
      await outputDir.delete(recursive: true);
    });

    test('refuses an empty layout', () async {
      await expectLater(
        renderChartPng(
          canvasSize: Size.zero,
          dateFormat: DateDisplayFormat.yearOnly,
          paint: (_, _) {},
        ),
        throwsStateError,
      );
    });
  });
}

GenealogyPerson _chartPerson(String id, String first, String last) {
  final now = DateTime(2000);
  return GenealogyPerson(
    id: id,
    uuid: 'uuid-$id',
    treeId: 'default-tree',
    firstName: first,
    lastName: last,
    gender: 'male',
    birthDate: DateTime(1920),
    isLiving: false,
    displayNameFormat: 'birth_married',
    isPrivate: false,
    privacyLevel: 0,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('updatePerson on an existing person (auditor dispute: C1)', () async {
    final repo = GenealogyRepository(db);
    final treeId = 'tree-1';

    final id = await repo.addPerson(
      treeId: treeId,
      firstName: 'Ashok',
      gender: 'M',
    );

    String? error;
    try {
      await repo.updatePerson(
        id: id,
        treeId: treeId,
        firstName: 'Ashok Kumar',
        gender: 'M',
      );
    } catch (e) {
      error = e.toString();
    }

    final after = await repo.getPersonById(id);
    // ignore: avoid_print
    print('updatePerson error: $error');
    // ignore: avoid_print
    print('name after update: ${after?.firstName}');
  });

  test('deletePerson for a connected person (auditor dispute: FK)', () async {
    final repo = GenealogyRepository(db);
    final relRepo = RelationshipRepository(db);
    final treeId = 'tree-1';

    final parent = await repo.addPerson(treeId: treeId, firstName: 'P', gender: 'M');
    final child = await repo.addPerson(treeId: treeId, firstName: 'C', gender: 'F');
    await relRepo.addParentChildRelationship(treeId: treeId, parentId: parent, childId: child);

    String? deleteError;
    try {
      await repo.deletePerson(parent);
    } catch (e) {
      deleteError = e.toString();
    }
    // ignore: avoid_print
    print('deletePerson(connected parent) error: $deleteError');

    String? deleteError2;
    try {
      await repo.deletePerson(child);
    } catch (e) {
      deleteError2 = e.toString();
    }
    // ignore: avoid_print
    print('deletePerson(connected child) error: $deleteError2');
  });
}

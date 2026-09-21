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

  Future<String> addPerson({
    required String firstName,
    String? lastName,
    String gender = 'male',
    DateTime? birthDate,
    String? biography,
    String? notes,
  }) {
    return repository.addPerson(
      treeId: treeId,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      birthDate: birthDate,
      biography: biography,
      notes: notes,
    );
  }

  test('merges two people and soft-deletes the duplicate', () async {
    final survivorId = await addPerson(
      firstName: 'John',
      lastName: 'Doe',
      gender: 'male',
      birthDate: DateTime(1950, 1, 1),
      notes: 'original notes',
    );
    final duplicateId = await addPerson(
      firstName: 'John',
      lastName: 'Doe',
      gender: 'male',
      birthDate: DateTime(1952, 6, 15),
      biography: 'born in Springfield',
    );

    await repository.mergePeople(survivorId: survivorId, duplicateId: duplicateId);

    final survivor = (await repository.getPersonById(survivorId))!;
    final duplicate = (await repository.getPersonById(duplicateId))!;

    expect(survivor.isDeleted, isFalse);
    expect(survivor.mergedIntoId, isNull);
    expect(survivor.notes, 'original notes');
    expect(survivor.biography, 'born in Springfield');
    expect(survivor.birthDate, DateTime(1950, 1, 1));

    expect(duplicate.isDeleted, isTrue);
    expect(duplicate.mergedIntoId, survivorId);

    final people = await repository.getPeopleByTree(treeId);
    expect(people.length, 1);
  });

  test('prefers the secondary source when requested', () async {
    final survivorId = await addPerson(
      firstName: 'Jane',
      gender: 'female',
      birthDate: DateTime(1980, 3, 5),
    );
    final duplicateId = await addPerson(
      firstName: 'Jane',
      gender: 'female',
      birthDate: DateTime(1975, 11, 20),
    );

    await repository.mergePeople(
      survivorId: survivorId,
      duplicateId: duplicateId,
      preferredBirthDateSource: 'secondary',
    );

    final survivor = (await repository.getPersonById(survivorId))!;
    expect(survivor.birthDate, DateTime(1975, 11, 20));
  });

  test('reassigns parent-child links to the survivor', () async {
    final parentId = await addPerson(firstName: 'Robert', gender: 'male');
    final child1Id = await addPerson(firstName: 'Amy', gender: 'female');
    final child2Id = await addPerson(firstName: 'Amy', gender: 'female');

    await relationshipRepository.addParentChildRelationship(
      treeId: treeId,
      parentId: parentId,
      childId: child1Id,
    );
    await relationshipRepository.addParentChildRelationship(
      treeId: treeId,
      parentId: parentId,
      childId: child2Id,
    );

    await repository.mergePeople(survivorId: child2Id, duplicateId: child1Id);

    final links = await db.select(db.familyChildrenV2).get();
    expect(links.length, 1);
    expect(links.single.childId, child2Id);

    final relationships = await relationshipRepository.getRelationshipsByTree(treeId);
    final parentChild = relationships
        .where((r) => r.relationshipType == 'parent_child')
        .toList();
    expect(parentChild.length, 1);
    expect(parentChild.single.personId, parentId);
    expect(parentChild.single.relatedPersonId, child2Id);
  });

  test('reassigns spouse families to the survivor', () async {
    final husbandId = await addPerson(firstName: 'David', gender: 'male');
    final wifeId = await addPerson(firstName: 'Sara', gender: 'female');
    final replacementId = await addPerson(firstName: 'Sara', gender: 'female');

    await relationshipRepository.addSpouseRelationship(
      treeId: treeId,
      personAId: husbandId,
      personBId: wifeId,
    );

    final preview = await repository.getMergePreview(
      survivorId: replacementId,
      duplicateId: wifeId,
    );
    expect(preview.relationshipCount, 1);

    await repository.mergePeople(survivorId: replacementId, duplicateId: wifeId);

    final family = (await db.select(db.familiesV2).get()).single;
    expect(family.husbandId, husbandId);
    expect(family.wifeId, replacementId);

    final relationships = await relationshipRepository.getRelationshipsByTree(treeId);
    final spouses = relationships
        .where((r) => r.relationshipType == 'spouse')
        .toList();
    expect(spouses.length, 1);
    expect(spouses.single.personId, husbandId);
    expect(spouses.single.relatedPersonId, replacementId);
  });

  test('rejects merging a person into themselves', () async {
    final personId = await addPerson(firstName: 'Solo', gender: 'male');

    await expectLater(
      repository.mergePeople(survivorId: personId, duplicateId: personId),
      throwsArgumentError,
    );
  });
}

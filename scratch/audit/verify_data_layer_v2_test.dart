import 'package:drift/drift.dart';
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

  test('schema introspection: tables, indexes, foreign keys', () async {
    final tables = await db
        .customSelect("SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name")
        .get();
    // ignore: avoid_print
    print('--- TABLES (${tables.length}) ---');
    for (final t in tables) {
      // ignore: avoid_print
      print('${t.data['name']}: ${t.data['sql']}');
    }

    final indexes = await db
        .customSelect("SELECT name, tbl_name, sql FROM sqlite_master WHERE type='index' ORDER BY name")
        .get();
    // ignore: avoid_print
    print('--- INDEXES (${indexes.length}) ---');
    for (final i in indexes) {
      // ignore: avoid_print
      print('${i.data['name']} on ${i.data['tbl_name']}: ${i.data['sql']}');
    }

    final fks = await db.customSelect('PRAGMA foreign_key_list(genealogy_persons)').get();
    // ignore: avoid_print
    print('--- FK on genealogy_persons (${fks.length}) ---');
    for (final f in fks) {
      // ignore: avoid_print
      print(f.data.toString());
    }
  });

  test('C3: deleteRelationship against a family that has children', () async {
    final repo = GenealogyRepository(db);
    final relRepo = RelationshipRepository(db);
    const treeId = 'tree-1';

    final dad = await repo.addPerson(treeId: treeId, firstName: 'Dad', gender: 'M');
    final mom = await repo.addPerson(treeId: treeId, firstName: 'Mom', gender: 'F');
    final kid = await repo.addPerson(treeId: treeId, firstName: 'Kid', gender: 'M');

    await relRepo.addSpouseRelationship(treeId: treeId, personAId: dad, personBId: mom);
    final families = await repo.getFamiliesForPerson(dad);
    final familyId = families.first.id;

    await repo.addChildToFamily(familyId: familyId, childId: kid);

    String? spouseDeleteError;
    try {
      await relRepo.deleteRelationship(familyId);
    } catch (e) {
      spouseDeleteError = e.toString();
    }
    // ignore: avoid_print
    print('C3 deleteRelationship(family_with_children) -> $spouseDeleteError');

    // Now delete the child link itself (should succeed)
    final links = await repo.getChildrenForFamily(familyId);
    final linkId = links.first.id;
    int? linkDeleted;
    String? linkDeleteError;
    try {
      linkDeleted = await relRepo.deleteRelationship(linkId);
    } catch (e) {
      linkDeleteError = e.toString();
    }
    // ignore: avoid_print
    print('C3 deleteRelationship(child_link) -> deleted=$linkDeleted error=$linkDeleteError');
  });

  test('tree deletion: does deleting the tree orphan people silently?', () async {
    final repo = GenealogyRepository(db);
    await db.into(db.familyTrees).insert(
          FamilyTreesCompanion.insert(
            id: 'tree-1',
            treeName: 'My Family',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await repo.addPerson(treeId: 'tree-1', firstName: 'Orphan', gender: 'M');

    final deleted = await (db.delete(db.familyTrees)..where((t) => t.id.equals('tree-1'))).go();
    final peopleLeft = await repo.getPeopleByTree('tree-1');
    // ignore: avoid_print
    print('tree rows deleted=$deleted, people still pointing at deleted tree=${peopleLeft.length}');
  });

  test('events/media/notes FK graph for person-scoped rows', () async {
    for (final table in ['events', 'media_items', 'research_notes', 'surname_events', 'todos']) {
      final fks = await db.customSelect('PRAGMA foreign_key_list($table)').get();
      // ignore: avoid_print
      print('FK on $table: ${fks.map((r) => r.data).toList()}');
    }
  });
}

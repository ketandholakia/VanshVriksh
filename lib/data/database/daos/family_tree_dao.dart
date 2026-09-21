import 'package:drift/drift.dart';

import '../app_database.dart';

class FamilyTreeDao {
  FamilyTreeDao(this._database);

  final AppDatabase _database;

  Future<void> createFamilyTree(FamilyTreesCompanion tree) {
    return _database.into(_database.familyTrees).insert(tree);
  }

  Future<bool> updateFamilyTree(FamilyTreesCompanion tree) {
    return _database.update(_database.familyTrees).replace(tree);
  }

  Future<FamilyTree?> getFamilyTreeById(String treeId) {
    return (_database.select(
      _database.familyTrees,
    )..where((tbl) => tbl.id.equals(treeId))).getSingleOrNull();
  }

  Stream<List<FamilyTree>> watchAllFamilyTrees() {
    return (_database.select(
      _database.familyTrees,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.treeName)])).watch();
  }

  Future<List<FamilyTree>> getAllFamilyTrees() {
    return (_database.select(
      _database.familyTrees,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.treeName)])).get();
  }

  Future<int> deleteFamilyTree(String treeId) {
    return (_database.delete(
      _database.familyTrees,
    )..where((tbl) => tbl.id.equals(treeId))).go();
  }

  Future<void> ensureDefaultFamilyTree({
    required String treeId,
    required String treeName,
  }) async {
    final existingTree = await getFamilyTreeById(treeId);
    if (existingTree != null) {
      return;
    }

    final now = DateTime.now();
    await createFamilyTree(
      FamilyTreesCompanion.insert(
        id: treeId,
        treeName: treeName,
        description: const Value('Default family tree'),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

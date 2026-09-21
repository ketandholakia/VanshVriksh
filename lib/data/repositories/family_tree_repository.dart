import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../database/daos/family_tree_dao.dart';

class FamilyTreeRepository {
  FamilyTreeRepository(this._database);

  final AppDatabase _database;
  FamilyTreeDao get _familyTreeDao => FamilyTreeDao(_database);

  Future<void> ensureDefaultTree() {
    return _familyTreeDao.ensureDefaultFamilyTree(
      treeId: AppConstants.defaultTreeId,
      treeName: 'My Family',
    );
  }

  Future<void> addFamilyTree({
    required String treeName,
    String? description,
  }) {
    final now = DateTime.now();
    return _familyTreeDao.createFamilyTree(
      FamilyTreesCompanion.insert(
        id: IdGenerator.newId(),
        treeName: treeName.trim(),
        description: Value(description?.trim()),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> updateFamilyTree({
    required String id,
    required String treeName,
    String? description,
    String? rootPersonId,
    required DateTime createdAt,
  }) {
    final now = DateTime.now();
    return _familyTreeDao.updateFamilyTree(
      FamilyTreesCompanion(
        id: Value(id),
        treeName: Value(treeName.trim()),
        description: Value(description?.trim()),
        rootPersonId: Value(rootPersonId),
        createdAt: Value(createdAt),
        updatedAt: Value(now),
      ),
    );
  }

  Future<FamilyTree?> getFamilyTreeById(String treeId) {
    return _familyTreeDao.getFamilyTreeById(treeId);
  }

  Stream<List<FamilyTree>> watchAllFamilyTrees() {
    return _familyTreeDao.watchAllFamilyTrees();
  }

  Future<List<FamilyTree>> getAllFamilyTrees() {
    return _familyTreeDao.getAllFamilyTrees();
  }

  Future<int> deleteFamilyTree(String treeId) {
    return _familyTreeDao.deleteFamilyTree(treeId);
  }
}

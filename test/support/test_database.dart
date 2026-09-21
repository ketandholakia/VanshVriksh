import 'package:drift/native.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/family_tree_repository.dart';

/// An in-memory database in the same state the app has after startup.
///
/// `genealogy_persons.tree_id` and `families_v2.tree_id` are mandatory foreign
/// keys into `family_trees`, so a person or family cannot exist before the tree
/// that owns it. Production guarantees this in `VanshVrikshApp` by calling
/// `ensureDefaultTree()` during initialisation; tests have to do the same, which
/// is why every database test should build its database through this helper.
Future<AppDatabase> createTestDatabase() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  // Opening the connection runs onCreate (createAll).
  await db.customStatement('SELECT 1');
  await FamilyTreeRepository(db).ensureDefaultTree();
  return db;
}

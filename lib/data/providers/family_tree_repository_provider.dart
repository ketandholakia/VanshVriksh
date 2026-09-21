import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/family_tree_repository.dart';
import 'database_provider.dart';

final familyTreeRepositoryProvider = Provider<FamilyTreeRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return FamilyTreeRepository(database);
});

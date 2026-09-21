import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/genealogy_repository.dart';
import 'database_provider.dart';

final genealogyRepositoryProvider = Provider<GenealogyRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return GenealogyRepository(database);
});

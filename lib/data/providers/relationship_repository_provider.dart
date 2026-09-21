import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/relationship_repository.dart';
import 'database_provider.dart';

final relationshipRepositoryProvider = Provider<RelationshipRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return RelationshipRepository(database);
});

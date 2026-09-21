import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/research_notes_repository.dart';
import 'database_provider.dart';

final researchNotesRepositoryProvider =
    Provider<ResearchNotesRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ResearchNotesRepository(database);
});

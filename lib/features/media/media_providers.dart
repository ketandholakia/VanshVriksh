import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/providers/media_repository_provider.dart';

final mediaByPersonProvider = StreamProvider.family<List<MediaItem>, String>((
  ref,
  personId,
) {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.watchMediaByPerson(personId);
});

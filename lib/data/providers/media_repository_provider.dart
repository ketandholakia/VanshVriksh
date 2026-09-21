import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/media_repository.dart';
import 'database_provider.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return MediaRepository(database);
});

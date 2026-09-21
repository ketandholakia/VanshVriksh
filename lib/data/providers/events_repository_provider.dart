import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/events_repository.dart';
import 'database_provider.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return EventsRepository(database);
});

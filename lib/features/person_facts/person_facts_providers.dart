import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/providers/events_repository_provider.dart';
import '../../data/providers/research_notes_repository_provider.dart';

final eventsByPersonProvider =
    StreamProvider.family<List<Event>, String>((ref, personId) {
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.watchEventsForPerson(personId).map((events) {
    final sorted = [...events];
    sorted.sort((a, b) {
      final aSort = a.dateSort;
      final bSort = b.dateSort;

      if (aSort == null && bSort == null) {
        return b.createdAt.compareTo(a.createdAt);
      }

      if (aSort == null) return 1;
      if (bSort == null) return -1;

      final dateComparison = aSort.compareTo(bSort);
      if (dateComparison != 0) return dateComparison;

      return b.createdAt.compareTo(a.createdAt);
    });

    return sorted;
  });
});

final researchNotesByPersonProvider =
    StreamProvider.family<List<ResearchNote>, String>((ref, personId) {
  final repository = ref.watch(researchNotesRepositoryProvider);
  return repository.watchNotesForPerson(personId).map((notes) {
    final sorted = [...notes];
    sorted.sort((a, b) {
      final aSort = a.noteDateSort;
      final bSort = b.noteDateSort;

      if (aSort == null && bSort == null) {
        return b.createdAt.compareTo(a.createdAt);
      }

      if (aSort == null) return 1;
      if (bSort == null) return -1;

      final dateComparison = aSort.compareTo(bSort);
      if (dateComparison != 0) return dateComparison;

      return b.createdAt.compareTo(a.createdAt);
    });

    return sorted;
  });
});

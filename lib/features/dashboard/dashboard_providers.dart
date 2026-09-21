import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/relationship_repository_provider.dart';
import '../people/people_providers.dart';
import 'birthday_models.dart';
import 'dashboard_models.dart';

final relationshipsByTreeProvider = StreamProvider<List<Relationship>>((ref) {
  final repository = ref.watch(relationshipRepositoryProvider);
  return repository.watchRelationshipsByTree(AppConstants.defaultTreeId);
});

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final peopleAsync = ref.watch(peopleListProvider);
  final relationshipsAsync = ref.watch(relationshipsByTreeProvider);

  return peopleAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (people) {
      return relationshipsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        data: (relationships) {
          final membersWithPhotos = people.where((person) {
            final path = person.profilePhotoPath;
            return path != null && path.trim().isNotEmpty;
          }).length;

          final livingMembers = people
              .where((person) => person.isLiving)
              .length;
          final deceasedMembers = people
              .where((person) => !person.isLiving)
              .length;

          return AsyncValue.data(
            DashboardStats(
              totalMembers: people.length,
              totalRelationships: relationships.length,
              membersWithPhotos: membersWithPhotos,
              missingPhotos: people.length - membersWithPhotos,
              livingMembers: livingMembers,
              deceasedMembers: deceasedMembers,
              upcomingBirthdays: _countUpcomingBirthdays(people),
            ),
          );
        },
      );
    },
  );
});

final upcomingBirthdaysProvider = Provider<List<UpcomingBirthday>>((ref) {
  final peopleAsync = ref.watch(peopleListProvider);

  return peopleAsync.maybeWhen(
    data: (people) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final birthdays = <UpcomingBirthday>[];

      for (final person in people) {
        final birthDate = person.birthDate;
        if (birthDate == null) continue;
        if (!person.isLiving) continue;

        var nextBirthday = _safeBirthday(today.year, birthDate.month, birthDate.day);
        if (nextBirthday.isBefore(todayDate)) {
          nextBirthday = _safeBirthday(
            today.year + 1,
            birthDate.month,
            birthDate.day,
          );
        }

        final daysLeft = nextBirthday.difference(todayDate).inDays;
        if (daysLeft > 60) continue;

        final ageTurning = nextBirthday.year - birthDate.year;

        birthdays.add(
          UpcomingBirthday(
            person: person,
            nextBirthday: nextBirthday,
            daysLeft: daysLeft,
            ageTurning: ageTurning,
          ),
        );
      }

      birthdays.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
      return birthdays;
    },
    orElse: () => [],
  );
});

int _countUpcomingBirthdays(List<GenealogyPerson> people) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  var count = 0;

  for (final person in people) {
    final birthDate = person.birthDate;
    if (birthDate == null) continue;
    if (!person.isLiving) continue;

    var nextBirthday = _safeBirthday(today.year, birthDate.month, birthDate.day);

    if (nextBirthday.isBefore(todayDate)) {
      nextBirthday = _safeBirthday(today.year + 1, birthDate.month, birthDate.day);
    }

    final daysLeft = nextBirthday.difference(todayDate).inDays;
    if (daysLeft <= 60) {
      count++;
    }
  }

  return count;
}

/// Builds a birthday DateTime without throwing on Feb 29 in non-leap years
/// (the day is clamped to the last day of the month).
DateTime _safeBirthday(int year, int month, int day) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > daysInMonth ? daysInMonth : day);
}

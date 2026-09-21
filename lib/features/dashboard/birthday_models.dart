import '../../data/database/app_database.dart';

class UpcomingBirthday {
  const UpcomingBirthday({
    required this.person,
    required this.nextBirthday,
    required this.daysLeft,
    required this.ageTurning,
  });

  final GenealogyPerson person;
  final DateTime nextBirthday;
  final int daysLeft;
  final int? ageTurning;
}

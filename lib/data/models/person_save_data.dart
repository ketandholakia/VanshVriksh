/// Immutable input for creating a person through [PersonSaveService].
///
/// This carries exactly the person fields a form collects: no generated id,
/// no UUID, no timestamps, no persistence-only flags such as `mergedIntoId`.
/// The service (via `GenealogyRepository`) assigns identity and timestamps at
/// write time, so callers cannot smuggle them in.
class PersonSaveData {
  const PersonSaveData({
    required this.firstName,
    required this.gender,
    this.middleName,
    this.lastName,
    this.birthSurname,
    this.marriedSurname,
    this.prefix,
    this.suffix,
    this.nickname,
    this.birthDate,
    this.birthPlace,
    this.currentPlace,
    this.deathDate,
    this.biography,
    this.notes,
    this.isPrivate = false,
    this.isLiving = true,
  });

  final String firstName;
  final String gender;
  final String? middleName;
  final String? lastName;
  final String? birthSurname;
  final String? marriedSurname;
  final String? prefix;
  final String? suffix;
  final String? nickname;
  final DateTime? birthDate;
  final String? birthPlace;
  final String? currentPlace;
  final DateTime? deathDate;
  final String? biography;
  final String? notes;
  final bool isPrivate;
  final bool isLiving;
}

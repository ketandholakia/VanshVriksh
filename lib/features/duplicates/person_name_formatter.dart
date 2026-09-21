import '../../data/database/app_database.dart';
import '../../core/extensions/genealogy_person_extensions.dart';

String displayPersonName(GenealogyPerson person) {
  final parts = <String>[
    if ((person.prefix ?? '').trim().isNotEmpty) person.prefix!.trim(),
    if (person.firstName.trim().isNotEmpty) person.firstName.trim(),
    if ((person.middleName ?? '').trim().isNotEmpty) person.middleName!.trim(),
    if ((person.lastName ?? '').trim().isNotEmpty) person.lastName!.trim(),
    if ((person.suffix ?? '').trim().isNotEmpty) person.suffix!.trim(),
  ];

  return parts.isEmpty ? person.fullName : parts.join(' ');
}

String? displayPersonNameOrNull(GenealogyPerson? person) {
  if (person == null) return null;
  return displayPersonName(person);
}

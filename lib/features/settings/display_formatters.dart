import 'package:intl/intl.dart';

import '../../data/database/app_database.dart';
import 'app_settings_provider.dart';

String formatDateForDisplay(
  DateTime? date,
  DateDisplayFormat format, {
  bool hideYear = false,
}) {
  if (date == null) return 'Not added';

  if (hideYear) {
    return switch (format) {
      DateDisplayFormat.fullDate => DateFormat('dd MMM').format(date),
      DateDisplayFormat.monthYear => DateFormat('MMM').format(date),
      DateDisplayFormat.yearOnly => DateFormat('dd MMM').format(date),
    };
  }

  return switch (format) {
    DateDisplayFormat.fullDate => DateFormat('dd-MM-yyyy').format(date),
    DateDisplayFormat.monthYear => DateFormat('MMM yyyy').format(date),
    DateDisplayFormat.yearOnly => date.year.toString(),
  };
}

String formatLifespanForDisplay(
  DateTime? birthDate,
  DateTime? deathDate,
  DateDisplayFormat format, {
  bool isLiving = false,
  bool hideYearsForLiving = false,
}) {
  final hideYear = isLiving && hideYearsForLiving;
  final today = DateTime.now();
  final birth = birthDate == null
      ? null
      : formatDateForDisplay(birthDate, format, hideYear: hideYear);
  final death = deathDate == null
      ? null
      : formatDateForDisplay(deathDate, format, hideYear: false);

  if (birth == null && death == null) {
    return isLiving && hideYearsForLiving ? 'Living' : 'Not available';
  }

  if (birth != null && death != null) {
    return '$birth - $death';
  }

  if (birth != null) {
    if (isLiving) {
      final age = _calculateAge(birthDate!, today);
      return 'Born $birth (Age: $age)';
    }

    return 'Born $birth';
  }

  return 'Died $death';
}

int _calculateAge(DateTime birthDate, DateTime referenceDate) {
  var age = referenceDate.year - birthDate.year;
  final hadBirthdayThisYear =
      referenceDate.month > birthDate.month ||
      (referenceDate.month == birthDate.month &&
          referenceDate.day >= birthDate.day);
  if (!hadBirthdayThisYear) {
    age -= 1;
  }
  return age;
}

String relationshipParentLabel(
  GenealogyPerson person,
  RelationshipLabelStyle style,
) {
  if (style == RelationshipLabelStyle.neutral) {
    return 'Parent';
  }

  switch (person.gender) {
    case 'male':
      return 'Father';
    case 'female':
      return 'Mother';
    default:
      return 'Parent';
  }
}

String relationshipSpouseLabel(
  GenealogyPerson person,
  RelationshipLabelStyle style,
) {
  if (style == RelationshipLabelStyle.neutral) {
    return 'Spouse';
  }

  switch (person.gender) {
    case 'male':
      return 'Husband';
    case 'female':
      return 'Wife';
    default:
      return 'Spouse';
  }
}

String relationDisplayLabel(
  String relationKind,
  RelationshipLabelStyle style, {
  String? gender,
}) {
  if (style == RelationshipLabelStyle.neutral) {
    return switch (relationKind) {
      'parent' => 'Parent',
      'spouse' => 'Spouse',
      'child' => gender == 'female' ? 'Daughter' : 'Son',
      _ => 'Relation',
    };
  }

  return switch (relationKind) {
    'parent' => gender == 'female' ? 'Mother' : 'Father',
    'spouse' => gender == 'female' ? 'Wife' : 'Husband',
    'child' => gender == 'female' ? 'Daughter' : 'Son',
    _ => 'Relation',
  };
}

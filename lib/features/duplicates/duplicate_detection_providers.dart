import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../core/extensions/genealogy_person_extensions.dart';

class DuplicateMergePreview {
  const DuplicateMergePreview({
    required this.eventCount,
    required this.noteCount,
    required this.mediaCount,
    required this.relationshipCount,
  });

  final int eventCount;
  final int noteCount;
  final int mediaCount;
  final int relationshipCount;
}

class DuplicateCandidate {
  const DuplicateCandidate({
    required this.primary,
    required this.duplicate,
    required this.score,
    required this.reason,
    required this.matchDetails,
    required this.preview,
    required this.isMarked,
  });

  final GenealogyPerson primary;
  final GenealogyPerson duplicate;
  final int score;
  final String reason;
  final List<String> matchDetails;
  final DuplicateMergePreview preview;
  final bool isMarked;
}

final duplicateCandidatesProvider = FutureProvider<List<DuplicateCandidate>>((
  ref,
) async {
  final repository = ref.watch(genealogyRepositoryProvider);
  final people = await repository.getPeopleByTree(AppConstants.defaultTreeId);
  final markers = await repository.getDuplicateMarkers(
    AppConstants.defaultTreeId,
  );
  final candidates = <DuplicateCandidate>[];

  for (var i = 0; i < people.length; i++) {
    for (var j = i + 1; j < people.length; j++) {
      final a = people[i];
      final b = people[j];
      final match = _scoreDuplicate(a, b);
      if (match == null) continue;
      final preview = await repository.getMergePreview(
        survivorId: match.primary.id,
        duplicateId: match.duplicate.id,
      );
      final isMarked = markers.any((marker) {
        final ids = [marker.personAId, marker.personBId]..sort();
        final pair = [a.id, b.id]..sort();
        return ids[0] == pair[0] && ids[1] == pair[1];
      });
      candidates.add(
        DuplicateCandidate(
          primary: match.primary,
          duplicate: match.duplicate,
          score: match.score,
          reason: match.reason,
          matchDetails: match.matchDetails,
          preview: preview,
          isMarked: isMarked,
        ),
      );
    }
  }

  candidates.sort((a, b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return _displayName(a.primary).compareTo(_displayName(b.primary));
  });

  return candidates;
});

DuplicateCandidate? _scoreDuplicate(GenealogyPerson a, GenealogyPerson b) {
  final nameA = _normalizedName(a);
  final nameB = _normalizedName(b);
  final fullNameMatch = nameA.isNotEmpty && nameA == nameB;
  final nameDistance = _levenshtein(nameA, nameB);
  final nameSimilarity = _similarity(nameA, nameB);
  final structuredA = _structuredKey(a);
  final structuredB = _structuredKey(b);
  final structuredMatch = structuredA == structuredB && structuredA.isNotEmpty;
  final structuredSimilarity = _similarity(structuredA, structuredB);

  final birthYearA = a.birthDate?.year;
  final birthYearB = b.birthDate?.year;
  final deathYearA = a.deathDate?.year;
  final deathYearB = b.deathDate?.year;

  final sameBirthYear =
      birthYearA != null && birthYearB != null && birthYearA == birthYearB;
  final closeBirthYear =
      birthYearA != null &&
      birthYearB != null &&
      (birthYearA - birthYearB).abs() <= 1;
  final sameDeathYear =
      deathYearA != null && deathYearB != null && deathYearA == deathYearB;
  final closeDeathYear =
      deathYearA != null &&
      deathYearB != null &&
      (deathYearA - deathYearB).abs() <= 1;
  final sameLastName =
      _normalizedText(a.lastName) == _normalizedText(b.lastName) &&
      _normalizedText(a.lastName).isNotEmpty;

  final score = _duplicateScore(
    fullNameMatch: fullNameMatch,
    nameSimilarity: nameSimilarity,
    nameDistance: nameDistance,
    structuredMatch: structuredMatch,
    structuredSimilarity: structuredSimilarity,
    sameBirthYear: sameBirthYear,
    closeBirthYear: closeBirthYear,
    sameDeathYear: sameDeathYear,
    closeDeathYear: closeDeathYear,
    sameLastName: sameLastName,
  );

  if (score < 62) return null;

  final reason = _duplicateReason(
    fullNameMatch: fullNameMatch,
    nameSimilarity: nameSimilarity,
    structuredMatch: structuredMatch,
    structuredSimilarity: structuredSimilarity,
    sameBirthYear: sameBirthYear,
    closeBirthYear: closeBirthYear,
    sameDeathYear: sameDeathYear,
    closeDeathYear: closeDeathYear,
    sameLastName: sameLastName,
  );

  final primary = _completenessScore(a) >= _completenessScore(b) ? a : b;
  final duplicate = identical(primary, a) ? b : a;
  final matchDetails = _matchDetails(
    fullNameMatch: fullNameMatch,
    nameSimilarity: nameSimilarity,
    structuredMatch: structuredMatch,
    structuredSimilarity: structuredSimilarity,
    sameBirthYear: sameBirthYear,
    closeBirthYear: closeBirthYear,
    sameDeathYear: sameDeathYear,
    closeDeathYear: closeDeathYear,
    sameLastName: sameLastName,
  );

  return DuplicateCandidate(
    primary: primary,
    duplicate: duplicate,
    score: score,
    reason: reason,
    matchDetails: matchDetails,
    preview: const DuplicateMergePreview(
      eventCount: 0,
      noteCount: 0,
      mediaCount: 0,
      relationshipCount: 0,
    ),
    isMarked: false,
  );
}

int _duplicateScore({
  required bool fullNameMatch,
  required double nameSimilarity,
  required int nameDistance,
  required bool structuredMatch,
  required double structuredSimilarity,
  required bool sameBirthYear,
  required bool closeBirthYear,
  required bool sameDeathYear,
  required bool closeDeathYear,
  required bool sameLastName,
}) {
  var score = 0;

  if (fullNameMatch) score += 50;
  score += (nameSimilarity * 30).round();
  if (nameDistance <= 2) score += 10;
  if (structuredMatch) score += 35;
  score += (structuredSimilarity * 20).round();
  if (sameLastName) score += 15;
  if (sameBirthYear) score += 20;
  if (closeBirthYear) score += 8;
  if (sameDeathYear) score += 10;
  if (closeDeathYear) score += 4;

  return score;
}

String _duplicateReason({
  required bool fullNameMatch,
  required double nameSimilarity,
  required bool structuredMatch,
  required double structuredSimilarity,
  required bool sameBirthYear,
  required bool closeBirthYear,
  required bool sameDeathYear,
  required bool closeDeathYear,
  required bool sameLastName,
}) {
  final parts = <String>[];
  if (fullNameMatch) parts.add('same name');
  if (!fullNameMatch && nameSimilarity >= 0.75) {
    parts.add('similar name');
  }
  if (structuredMatch) parts.add('same structured name');
  if (!structuredMatch && structuredSimilarity >= 0.75) {
    parts.add('similar structured name');
  }
  if (sameBirthYear) parts.add('same birth year');
  if (!sameBirthYear && closeBirthYear) parts.add('near birth year');
  if (sameDeathYear) parts.add('same death year');
  if (!sameDeathYear && closeDeathYear) parts.add('near death year');
  if (sameLastName) parts.add('same last name');

  return parts.isEmpty ? 'possible duplicate' : parts.join(', ');
}

List<String> _matchDetails({
  required bool fullNameMatch,
  required double nameSimilarity,
  required bool structuredMatch,
  required double structuredSimilarity,
  required bool sameBirthYear,
  required bool closeBirthYear,
  required bool sameDeathYear,
  required bool closeDeathYear,
  required bool sameLastName,
}) {
  final details = <String>[];
  if (fullNameMatch) {
    details.add('exact name match');
  } else if (nameSimilarity >= 0.75) {
    details.add('fuzzy name match');
  }

  if (structuredMatch) {
    details.add('structured name match');
  } else if (structuredSimilarity >= 0.75) {
    details.add('structured name similarity');
  }

  if (sameBirthYear) {
    details.add('birth year match');
  } else if (closeBirthYear) {
    details.add('birth year proximity');
  }

  if (sameDeathYear) {
    details.add('death year match');
  } else if (closeDeathYear) {
    details.add('death year proximity');
  }

  if (sameLastName) {
    details.add('last-name match');
  }

  return details;
}

int _completenessScore(GenealogyPerson person) {
  var score = 0;
  final fields = [
    person.prefix,
    person.firstName,
    person.middleName,
    person.lastName,
    person.nickname,
    person.birthDate,
    person.deathDate,
    person.birthPlace,
    person.currentPlace,
    person.biography,
    person.notes,
  ];

  for (final field in fields) {
    if (field == null) continue;
    if (field is String && field.trim().isEmpty) continue;
    score++;
  }

  if (!person.isLiving) score++;
  if (person.isPrivate) score++;
  return score;
}

String _displayName(GenealogyPerson person) {
  final parts = <String>[
    if (_normalizedText(person.prefix).isNotEmpty) person.prefix!.trim(),
    if (_normalizedText(person.firstName).isNotEmpty) person.firstName.trim(),
    if (_normalizedText(person.middleName).isNotEmpty)
      person.middleName!.trim(),
    if (_normalizedText(person.lastName).isNotEmpty) person.lastName!.trim(),
    if (_normalizedText(person.suffix).isNotEmpty) person.suffix!.trim(),
  ];

  return parts.isEmpty ? person.fullName : parts.join(' ');
}

String _structuredKey(GenealogyPerson person) {
  final parts = [
    _normalizedText(person.prefix),
    _normalizedText(person.firstName),
    _normalizedText(person.middleName),
    _normalizedText(person.lastName),
    _normalizedText(person.suffix),
  ].where((part) => part.isNotEmpty).toList();

  return parts.join(' ');
}

String _normalizedName(GenealogyPerson person) {
  final name = _displayName(person);
  return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String _normalizedText(String? value) {
  return value?.trim().toLowerCase() ?? '';
}

double _similarity(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 0;
  final distance = _levenshtein(a, b);
  return 1 - (distance / maxLen);
}

int _levenshtein(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        prev[j] + 1,
        curr[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    for (var j = 0; j <= b.length; j++) {
      prev[j] = curr[j];
    }
  }

  return prev[b.length];
}

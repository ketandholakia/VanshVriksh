import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/relationship_repository_provider.dart';
import '../../core/extensions/genealogy_person_extensions.dart';

class IntegrityIssue {
  const IntegrityIssue({
    required this.severity,
    required this.title,
    required this.description,
    this.personId,
  });

  final String severity;
  final String title;
  final String description;
  final String? personId;
}

final integrityIssuesProvider = FutureProvider<List<IntegrityIssue>>((
  ref,
) async {
  final personRepo = ref.watch(genealogyRepositoryProvider);
  final relationshipRepo = ref.watch(relationshipRepositoryProvider);

  final people = await personRepo.getPeopleByTree(AppConstants.defaultTreeId);
  final parentChildLinks = await relationshipRepo.getParentChildRelationships(
    AppConstants.defaultTreeId,
  );

  final issues = <IntegrityIssue>[];
  final byId = {for (final person in people) person.id: person};

  for (final person in people) {
    if (person.birthDate == null) continue;

    for (final link in parentChildLinks.where((l) => l.childId == person.id)) {
      final parent = byId[link.parentId];
      if (parent == null || parent.birthDate == null) continue;

      final ageGap =
          person.birthDate!.difference(parent.birthDate!).inDays / 365.25;
      if (ageGap < 0) {
        issues.add(
          IntegrityIssue(
            severity: 'error',
            title: 'Impossible parent-child age gap',
            description:
                '${_displayName(parent)} appears younger than ${_displayName(person)}.',
            personId: person.id,
          ),
        );
      } else if (ageGap < 12) {
        issues.add(
          IntegrityIssue(
            severity: 'warning',
            title: 'Very small parent-child age gap',
            description:
                '${_displayName(parent)} is only ${ageGap.toStringAsFixed(1)} years older than ${_displayName(person)}.',
            personId: person.id,
          ),
        );
      }
    }
  }

  final visited = <String>{};
  final stack = <String>{};

  bool dfs(String personId) {
    if (stack.contains(personId)) return true;
    if (!visited.add(personId)) return false;

    stack.add(personId);
    final children = parentChildLinks
        .where((link) => link.parentId == personId)
        .map((link) => link.childId);

    for (final childId in children) {
      if (dfs(childId)) return true;
    }

    stack.remove(personId);
    return false;
  }

  for (final person in people) {
    if (dfs(person.id)) {
      issues.add(
        IntegrityIssue(
          severity: 'error',
          title: 'Circular parent-child chain',
          description:
              'A circular parent-child chain exists in the current tree.',
          personId: person.id,
        ),
      );
      break;
    }
  }

  return issues;
});

String _displayName(GenealogyPerson person) {
  final parts = <String>[
    if ((person.prefix ?? '').trim().isNotEmpty) person.prefix!.trim(),
    if ((person.firstName ?? '').trim().isNotEmpty) person.firstName!.trim(),
    if ((person.middleName ?? '').trim().isNotEmpty) person.middleName!.trim(),
    if ((person.lastName ?? '').trim().isNotEmpty) person.lastName!.trim(),
    if ((person.suffix ?? '').trim().isNotEmpty) person.suffix!.trim(),
  ];
  return parts.isEmpty ? person.fullName : parts.join(' ');
}

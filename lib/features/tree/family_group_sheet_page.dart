import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database/app_database.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/relationship_repository_provider.dart';
import '../people/people_providers.dart';
import '../settings/app_settings_provider.dart';
import '../settings/display_formatters.dart';

/// The family group sheet: one nuclear family at a time — a couple with their
/// vital data and their children — the record genealogists file per household.
///
/// A person may head several families across their life, so the page renders
/// one section per recorded partnership.
class FamilyGroupSheetPage extends ConsumerWidget {
  const FamilyGroupSheetPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheet = ref.watch(familyGroupSheetProvider(personId));
    final dateFormat =
        ref.watch(dateDisplayFormatProvider).value ??
        DateDisplayFormat.fullDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family group sheet'),
        actions: [
          sheet.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (data) => data == null || data.groups.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Share as text',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () async {
                      await SharePlus.instance.share(
                        ShareParams(
                          text: buildGroupSheetText(data, dateFormat),
                          title: 'Family group sheet',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      body: sheet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load the group sheet:\n$error'),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Person not found'));
          }
          if (data.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No nuclear family recorded',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A group sheet needs a partnership or children. Add a '
                      'spouse or a child first.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < data.groups.length; i++)
                _NuclearFamilyCard(
                  group: data.groups[i],
                  index: data.groups.length > 1 ? i + 1 : null,
                  dateFormat: dateFormat,
                ),
            ],
          );
        },
      ),
    );
  }
}

final familyGroupSheetProvider =
    FutureProvider.family<FamilyGroupSheetData?, String>((ref, personId) async {
      ref.watch(personRelationshipsProvider(personId));

      final person = await ref
          .watch(genealogyRepositoryProvider)
          .getPersonById(personId);
      if (person == null || person.isDeleted) return null;

      final graph = await ref
          .watch(relationshipRepositoryProvider)
          .loadFamilyGraph(person.treeId);

      final groups = <NuclearFamily>[];
      for (final grouping in graph.familiesAmong({personId})) {
        if (!grouping.partnerIds.contains(personId)) continue;
        final family = graph.familyById(grouping.familyId);
        groups.add(
          NuclearFamily(
            familyId: grouping.familyId,
            husband: grouping.partnerIds.isNotEmpty
                ? graph.person(grouping.partnerIds[0])
                : null,
            wife: grouping.partnerIds.length >= 2
                ? graph.person(grouping.partnerIds[1])
                : null,
            marriageDate: family?.marriageDate,
            marriagePlace: family?.marriagePlace,
            divorceDate: family?.divorceDate,
            children: [
              for (final childId in grouping.childIds)
                if (graph.person(childId) != null) graph.person(childId)!,
            ],
          ),
        );
      }

      return FamilyGroupSheetData(person: person, groups: groups);
    });

class FamilyGroupSheetData {
  const FamilyGroupSheetData({required this.person, required this.groups});

  final GenealogyPerson person;
  final List<NuclearFamily> groups;
}

class NuclearFamily {
  const NuclearFamily({
    required this.familyId,
    required this.husband,
    required this.wife,
    required this.marriageDate,
    required this.marriagePlace,
    required this.divorceDate,
    required this.children,
  });

  final String familyId;
  final GenealogyPerson? husband;
  final GenealogyPerson? wife;
  final DateTime? marriageDate;
  final String? marriagePlace;
  final DateTime? divorceDate;
  final List<GenealogyPerson> children;
}

class _NuclearFamilyCard extends ConsumerWidget {
  const _NuclearFamilyCard({
    required this.group,
    required this.index,
    required this.dateFormat,
  });

  final NuclearFamily group;
  final int? index;
  final DateDisplayFormat dateFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final parents = [group.husband, group.wife].whereType<GenealogyPerson>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parents.map((p) => p.fullName).join('  &  '),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (index != null)
                  Text(
                    'Family $index',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (group.marriageDate != null || group.marriagePlace != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _marriageLine(dateFormat),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (group.divorceDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Divorced ${formatDateForDisplay(group.divorceDate!, dateFormat)}',
                style: TextStyle(fontSize: 12.5, color: colorScheme.error),
              ),
            ],
            const Divider(height: 20),
            for (final parent in parents)
              _VitalTile(person: parent, dateFormat: dateFormat),
            const SizedBox(height: 4),
            Text(
              'Children (${group.children.length})',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            if (group.children.isEmpty)
              Text(
                'No children recorded in this family.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final child in group.children)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.child_care_outlined),
                  title: Text(child.fullName),
                  subtitle: Text(
                    _lifespan(child),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/people/${child.id}'),
                ),
          ],
        ),
      ),
    );
  }

  String _marriageLine(DateDisplayFormat dateFormat) {
    final date = group.marriageDate == null
        ? null
        : formatDateForDisplay(group.marriageDate!, dateFormat);
    final place = group.marriagePlace?.trim();
    return [
      if (date != null) 'Married $date',
      if (place != null && place.isNotEmpty) place,
    ].join(' · ');
  }

  String _lifespan(GenealogyPerson person) => formatLifespanForDisplay(
    person.birthDate,
    person.deathDate,
    dateFormat,
    isLiving: person.isLiving,
  );
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({required this.person, required this.dateFormat});

  final GenealogyPerson person;
  final DateDisplayFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vitals = <String>[
      if (person.birthDate != null)
        'Born ${formatDateForDisplay(person.birthDate!, dateFormat)}',
      if ((person.birthPlace ?? '').trim().isNotEmpty)
        'in ${person.birthPlace!.trim()}',
      if (person.deathDate != null)
        'Died ${formatDateForDisplay(person.deathDate!, dateFormat)}',
      if ((person.occupation ?? '').trim().isNotEmpty)
        person.occupation!.trim(),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            person.gender.trim().toLowerCase().startsWith('m')
                ? Icons.man_outlined
                : Icons.woman_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (vitals.isNotEmpty)
                  Text(
                    vitals.join(' · '),
                    style: TextStyle(
                      fontSize: 12.3,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shareable plain-text form of the sheet.
String buildGroupSheetText(
  FamilyGroupSheetData data,
  DateDisplayFormat dateFormat,
) {
  final buffer = StringBuffer('Family Group Sheet — VanshVriksh\n');
  buffer.writeln('Focus: ${data.person.fullName}');
  buffer.writeln();

  for (var i = 0; i < data.groups.length; i++) {
    final group = data.groups[i];
    if (data.groups.length > 1) buffer.writeln('--- Family ${i + 1} ---');
    final parents = [group.husband, group.wife].whereType<GenealogyPerson>();
    for (final parent in parents) {
      buffer.writeln(_personLine(parent, dateFormat));
    }
    if (group.marriageDate != null || group.marriagePlace != null) {
      buffer.writeln(
        'Married: '
        '${group.marriageDate == null ? '' : formatDateForDisplay(group.marriageDate!, dateFormat)}'
        '${group.marriagePlace == null ? '' : ' · ${group.marriagePlace}'}',
      );
    }
    if (group.divorceDate != null) {
      buffer.writeln(
        'Divorced: ${formatDateForDisplay(group.divorceDate!, dateFormat)}',
      );
    }
    buffer.writeln('Children: ${group.children.length}');
    for (final child in group.children) {
      buffer.writeln('  - ${_personLine(child, dateFormat)}');
    }
    buffer.writeln();
  }
  return buffer.toString();
}

String _personLine(GenealogyPerson person, DateDisplayFormat dateFormat) {
  final lifespan = formatLifespanForDisplay(
    person.birthDate,
    person.deathDate,
    dateFormat,
    isLiving: person.isLiving,
  );
  return [
    person.fullName,
    if (lifespan.isNotEmpty && lifespan != 'Not available') '($lifespan)',
  ].join(' ');
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_background.dart';
import '../../core/widgets/person_avatar.dart';
import '../../data/database/app_database.dart';
import '../settings/app_settings_provider.dart';
import '../settings/display_formatters.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import 'people_providers.dart';

class PeopleListPage extends ConsumerStatefulWidget {
  const PeopleListPage({super.key});

  @override
  ConsumerState<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends ConsumerState<PeopleListPage> {
  String _searchText = '';
  PersonListFilter _filter = PersonListFilter.all;

  String _displayName(GenealogyPerson person) {
    final parts = <String>[
      if ((person.prefix ?? '').trim().isNotEmpty) person.prefix!.trim(),
      if ((person.firstName ?? '').trim().isNotEmpty) person.firstName!.trim(),
      if ((person.middleName ?? '').trim().isNotEmpty) person.middleName!.trim(),
      if ((person.lastName ?? '').trim().isNotEmpty) person.lastName!.trim(),
      if ((person.suffix ?? '').trim().isNotEmpty) person.suffix!.trim(),
    ];

    if (parts.isNotEmpty) return parts.join(' ');
    return person.fullName;
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final nextFilter = PersonListFilter.fromQuery(uri.queryParameters['filter']);
    if (nextFilter != _filter) {
      _filter = nextFilter;
    }

    final peopleAsync = ref.watch(peopleListProvider);
    final dateFormat =
        ref.watch(dateDisplayFormatProvider).value ?? dateDisplayFormatDefault;
    final photoFitMode =
        ref.watch(personPhotoFitModeProvider).value ?? personPhotoFitModeDefault;
    final hideYearsForLiving =
        ref.watch(hideYearsForLivingProvider).value ?? hideYearsForLivingDefault;

    return Scaffold(
      appBar: AppBar(
        title: Text(_filter.title),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Find duplicates',
            onPressed: () => context.go('/people/duplicates'),
            icon: const Icon(Icons.rule_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PersonListFilter.values.map((filter) {
                  final selected = _filter == filter;
                  return ChoiceChip(
                    label: Text(filter.chipLabel),
                    selected: selected,
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
                    ),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (_) {
                      final target = filter == PersonListFilter.all
                          ? '/people'
                          : '/people?filter=${filter.queryValue}';
                      context.push(target);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search family members',
                prefixIcon: Icon(Icons.search),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: peopleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load people:\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (people) {
                final filteredPeople = people.where((person) {
                  if (!_filter.matches(person)) return false;
                  if (_searchText.isEmpty) return true;

                  final name = _displayName(person).toLowerCase();
                  final structuredName = [
                    person.prefix,
                    person.firstName,
                    person.middleName,
                    person.lastName,
                    person.suffix,
                    person.nickname,
                  ].whereType<String>().join(' ').toLowerCase();
                  final birthPlace = person.birthPlace?.toLowerCase() ?? '';
                  final currentPlace = person.currentPlace?.toLowerCase() ?? '';

                  return name.contains(_searchText) ||
                      structuredName.contains(_searchText) ||
                      birthPlace.contains(_searchText) ||
                      currentPlace.contains(_searchText);
                }).toList();

                if (filteredPeople.isEmpty) {
                  return _EmptyPeopleView(hasSearch: _searchText.isNotEmpty);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filteredPeople.length,
                  itemBuilder: (context, index) {
                    final person = filteredPeople[index];
                    return _PersonListTile(
                      displayName: _displayName(person),
                      gender: person.gender,
                      birthDate: person.birthDate,
                      deathDate: person.deathDate,
                      isLiving: person.isLiving,
                      birthPlace: person.birthPlace,
                      profilePhotoPath: person.profilePhotoPath,
                      dateFormat: dateFormat,
                      photoFitMode: photoFitMode,
                      hideYearsForLiving: hideYearsForLiving,
                      onTap: () => context.push('/people/${person.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/people/add?returnTo=/people'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Person'),
      ),
    );
  }
}

enum PersonListFilter {
  all,
  living,
  deceased,
  withPhotos,
  missingPhotos;

  static PersonListFilter fromQuery(String? value) {
    return switch (value) {
      'living' => PersonListFilter.living,
      'deceased' => PersonListFilter.deceased,
      'with-photos' => PersonListFilter.withPhotos,
      'missing-photos' => PersonListFilter.missingPhotos,
      _ => PersonListFilter.all,
    };
  }

  String get title => switch (this) {
        PersonListFilter.all => 'People',
        PersonListFilter.living => 'Living People',
        PersonListFilter.deceased => 'Deceased People',
        PersonListFilter.withPhotos => 'People With Photos',
        PersonListFilter.missingPhotos => 'People Missing Photos',
      };

  String get chipLabel => switch (this) {
        PersonListFilter.all => 'All',
        PersonListFilter.living => 'Living',
        PersonListFilter.deceased => 'Deceased',
        PersonListFilter.withPhotos => 'With Photos',
        PersonListFilter.missingPhotos => 'Missing Photos',
      };

  String get queryValue => switch (this) {
        PersonListFilter.all => 'all',
        PersonListFilter.living => 'living',
        PersonListFilter.deceased => 'deceased',
        PersonListFilter.withPhotos => 'with-photos',
        PersonListFilter.missingPhotos => 'missing-photos',
      };

  bool matches(GenealogyPerson person) {
    return switch (this) {
      PersonListFilter.all => true,
      PersonListFilter.living => person.isLiving,
      PersonListFilter.deceased => !person.isLiving,
      PersonListFilter.withPhotos => (person.profilePhotoPath ?? '').trim().isNotEmpty,
      PersonListFilter.missingPhotos => (person.profilePhotoPath ?? '').trim().isEmpty,
    };
  }
}

class _EmptyPeopleView extends StatelessWidget {
  const _EmptyPeopleView({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.center,
                opacity: 0.04,
                scale: 1.15,
                padding: EdgeInsets.zero,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasSearch ? Icons.search_off_outlined : Icons.family_restroom_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  hasSearch ? 'No matching family member found' : 'No family members yet',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  hasSearch
                      ? 'Try searching with another name or place.'
                      : 'Start by adding your first family member.',
                  textAlign: TextAlign.center,
                ),
                if (!hasSearch) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push('/people/add?returnTo=/people'),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add First Person'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonListTile extends StatelessWidget {
  const _PersonListTile({
    required this.displayName,
    required this.gender,
    required this.birthDate,
    required this.deathDate,
    required this.isLiving,
    required this.birthPlace,
    required this.profilePhotoPath,
    required this.dateFormat,
    required this.photoFitMode,
    required this.hideYearsForLiving,
    required this.onTap,
  });

  final String displayName;
  final String gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final bool isLiving;
  final String? birthPlace;
  final String? profilePhotoPath;
  final DateDisplayFormat dateFormat;
  final PersonPhotoFitMode photoFitMode;
  final bool hideYearsForLiving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lifespan = formatLifespanForDisplay(
      birthDate,
      deathDate,
      dateFormat,
      isLiving: isLiving,
      hideYearsForLiving: hideYearsForLiving,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.centerRight,
                opacity: 0.028,
                scale: 0.85,
                padding: EdgeInsets.only(right: 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  PersonAvatar(
                    photoPath: profilePhotoPath,
                    initialText: displayName,
                    size: 44,
                    fitMode: photoFitMode,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (lifespan.isNotEmpty) lifespan,
                            if (birthPlace != null && birthPlace!.trim().isNotEmpty) birthPlace!,
                          ].join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

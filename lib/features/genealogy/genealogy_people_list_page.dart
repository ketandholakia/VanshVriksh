import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/person_avatar.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../settings/app_settings_provider.dart';

final genealogyPeopleByTreeProvider =
    StreamProvider.family<List<GenealogyPerson>, String>((ref, treeId) {
  final repo = ref.watch(genealogyRepositoryProvider);
  return repo.watchPeopleByTree(treeId);
});

class GenealogyPeopleListPage extends ConsumerStatefulWidget {
  const GenealogyPeopleListPage({super.key});

  @override
  ConsumerState<GenealogyPeopleListPage> createState() =>
      _GenealogyPeopleListPageState();
}

class _GenealogyPeopleListPageState extends ConsumerState<GenealogyPeopleListPage> {
  String _searchText = '';

  String _displayName(GenealogyPerson person) {
    final surname = (person.marriedSurname?.trim().isNotEmpty ?? false)
        ? person.marriedSurname!.trim()
        : (person.birthSurname?.trim().isNotEmpty ?? false)
            ? person.birthSurname!.trim()
            : (person.lastName ?? '').trim();

    final parts = <String>[
      if ((person.prefix ?? '').trim().isNotEmpty) person.prefix!.trim(),
      person.firstName.trim(),
      if ((person.middleName ?? '').trim().isNotEmpty) person.middleName!.trim(),
      if (surname.isNotEmpty) surname,
      if ((person.suffix ?? '').trim().isNotEmpty) person.suffix!.trim(),
    ];

    return parts.where((part) => part.trim().isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(genealogyPeopleByTreeProvider(AppConstants.defaultTreeId));
    final photoFitMode =
        ref.watch(personPhotoFitModeProvider).value ?? personPhotoFitModeDefault;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genealogy People v2'),
        actions: [
          IconButton(
            tooltip: 'Add person',
            onPressed: () => context.push('/v2/people/add?returnTo=/v2/people'),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search people',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchText = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: peopleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Failed to load people:\n$error')),
              data: (people) {
                final filtered = people.where((person) {
                  if (_searchText.isEmpty) return true;
                  final name = _displayName(person).toLowerCase();
                  return name.contains(_searchText) ||
                      (person.birthSurname ?? '').toLowerCase().contains(_searchText) ||
                      (person.marriedSurname ?? '').toLowerCase().contains(_searchText) ||
                      person.firstName.toLowerCase().contains(_searchText) ||
                      (person.nickname ?? '').toLowerCase().contains(_searchText);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchText.isEmpty ? 'No genealogy people yet.' : 'No matching people found.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final person = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: PersonAvatar(
                          photoPath: null,
                          initialText: _displayName(person),
                          size: 40,
                          fitMode: photoFitMode,
                        ),
                        title: Text(_displayName(person)),
                        subtitle: Text([
                          if ((person.birthSurname ?? '').trim().isNotEmpty)
                            'Birth: ${person.birthSurname}',
                          if ((person.marriedSurname ?? '').trim().isNotEmpty)
                            'Married: ${person.marriedSurname}',
                        ].join(' • ')),
                        onTap: () => context.push('/v2/people/${person.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

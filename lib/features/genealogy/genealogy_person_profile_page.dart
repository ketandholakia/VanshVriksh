import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';

class GenealogyPersonProfilePage extends ConsumerWidget {
  const GenealogyPersonProfilePage({super.key, required this.personId});

  final String personId;

  String _displayName(GenealogyPerson person) {
    final surname = (person.marriedSurname?.trim().isNotEmpty ?? false)
        ? person.marriedSurname!.trim()
        : (person.birthSurname?.trim().isNotEmpty ?? false)
        ? person.birthSurname!.trim()
        : (person.lastName ?? '').trim();
    final parts = <String>[
      if ((person.prefix ?? '').trim().isNotEmpty) person.prefix!.trim(),
      person.firstName.trim(),
      if ((person.middleName ?? '').trim().isNotEmpty)
        person.middleName!.trim(),
      if (surname.isNotEmpty) surname,
      if ((person.suffix ?? '').trim().isNotEmpty) person.suffix!.trim(),
    ];
    return parts.where((part) => part.trim().isNotEmpty).join(' ');
  }

  String _surnameOf(GenealogyPerson person) {
    return (person.marriedSurname?.trim().isNotEmpty ?? false)
        ? person.marriedSurname!.trim()
        : (person.birthSurname?.trim().isNotEmpty ?? false)
        ? person.birthSurname!.trim()
        : (person.lastName ?? '').trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(genealogyRepositoryProvider);
    final personAsync = StreamProvider.autoDispose(
      (ref) => repo.watchPersonById(personId),
    );
    final historyAsync = StreamProvider.autoDispose(
      (ref) => repo.watchSurnameHistory(personId),
    );
    final familiesAsync = StreamProvider.autoDispose(
      (ref) => repo.watchFamiliesForPerson(personId),
    );
    final person = ref.watch(personAsync).asData?.value;
    final history = ref.watch(historyAsync).asData?.value ?? const [];
    final families = ref.watch(familiesAsync).asData?.value ?? const [];

    if (person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Person Profile v2')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Profile v2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(
              '/v2/people/$personId/edit?returnTo=/v2/people/$personId',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(person),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Gender: ${person.gender}'),
                  Text('Display: ${person.displayNameFormat}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Surname History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text('No surname history yet.')
          else
            ...history.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item.surname),
                  subtitle: Text(item.surnameType),
                  trailing: item.isPrimary ? const Icon(Icons.star) : null,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Family Links',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/v2/tree/$personId'),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('Open Tree'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/v2/people/$personId/link/spouse'),
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Link Spouse'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/v2/people/$personId/link/child'),
                    icon: const Icon(Icons.family_restroom),
                    label: const Text('Link Child'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/v2/tree/$personId'),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('View Tree'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (families.isEmpty)
            const Text('No family links yet.')
          else
            ...families.map((family) {
              final spouseId = family.husbandId == personId
                  ? family.wifeId
                  : family.husbandId;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<GenealogyPerson?>(
                        future: spouseId == null
                            ? Future.value(null)
                            : repo.getPersonById(spouseId),
                        builder: (context, snapshot) {
                          final spouse = snapshot.data;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.favorite_border),
                            title: Text(
                              spouse == null
                                  ? 'Spouse not linked'
                                  : _displayName(spouse),
                            ),
                            subtitle: Text(family.relationshipType),
                            trailing: spouse == null
                                ? null
                                : Text(_surnameOf(spouse)),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      const Text(
                        'Children',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<FamilyChildrenV2Data>>(
                        stream: repo.watchChildrenForFamily(family.id),
                        builder: (context, snapshot) {
                          final children = snapshot.data ?? const [];
                          if (children.isEmpty) {
                            return const Text('No children linked.');
                          }
                          return Column(
                            children: children.map((childLink) {
                              return FutureBuilder<GenealogyPerson?>(
                                future: repo.getPersonById(childLink.childId),
                                builder: (context, childSnapshot) {
                                  final child = childSnapshot.data;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.child_care),
                                    title: Text(
                                      child == null
                                          ? 'Unknown child'
                                          : _displayName(child),
                                    ),
                                    subtitle: Text(childLink.relationshipType),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

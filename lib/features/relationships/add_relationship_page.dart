import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/relationship_repository_provider.dart';
import '../people/people_providers.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../settings/app_settings_provider.dart';

class AddRelationshipPage extends ConsumerStatefulWidget {
  const AddRelationshipPage({
    super.key,
    required this.personId,
    this.initialRelation,
  });

  final String personId;
  final String? initialRelation;

  @override
  ConsumerState<AddRelationshipPage> createState() =>
      _AddRelationshipPageState();
}

class _AddRelationshipPageState extends ConsumerState<AddRelationshipPage> {
  late String _selectedRelation;
  String? _selectedPersonId;
  String _personSelectionMode = 'existing';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRelation = _normalizeRelation(widget.initialRelation) ?? 'father';
  }

  Future<void> _saveRelationship(GenealogyPerson currentPerson) async {
    final relatedPersonId = _selectedPersonId;

    if (relatedPersonId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a person.')));
      return;
    }

    if (relatedPersonId == currentPerson.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A person cannot be related to themselves.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(relationshipRepositoryProvider);

      switch (_selectedRelation) {
        case 'father':
        case 'mother':
          await repository.addParentChildRelationship(
            treeId: AppConstants.defaultTreeId,
            parentId: relatedPersonId,
            childId: currentPerson.id,
          );
          break;
        case 'child':
          await repository.addParentChildRelationship(
            treeId: AppConstants.defaultTreeId,
            parentId: currentPerson.id,
            childId: relatedPersonId,
          );

          final spouses = await repository.getSpouses(currentPerson.id);
          for (final spouse in spouses) {
            try {
              await repository.addParentChildRelationship(
                treeId: AppConstants.defaultTreeId,
                parentId: spouse.id,
                childId: relatedPersonId,
              );
            } catch (_) {
              // Ignore duplicate links when the child is already attached.
            }
          }
          break;
        case 'spouse':
          await repository.addSpouseRelationship(
            treeId: AppConstants.defaultTreeId,
            personAId: currentPerson.id,
            personBId: relatedPersonId,
          );
          break;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relationship added successfully.')),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add relationship: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _relationHelpText() {
    final labelStyle =
        ref.read(relationshipLabelStyleProvider).value ??
        relationshipLabelStyleDefault;
    switch (_selectedRelation) {
      case 'father':
        return labelStyle == RelationshipLabelStyle.neutral
            ? 'Selected person will become a parent of this profile person.'
            : 'Selected person will become father of this profile person.';
      case 'mother':
        return labelStyle == RelationshipLabelStyle.neutral
            ? 'Selected person will become a parent of this profile person.'
            : 'Selected person will become mother of this profile person.';
      case 'spouse':
        return 'Selected person will become spouse of this profile person.';
      case 'child':
        return 'Selected person will become son or daughter of this profile person.';
      default:
        return '';
    }
  }

  String? _normalizeRelation(String? relation) {
    switch (relation) {
      case 'father':
      case 'mother':
      case 'spouse':
      case 'child':
        return relation;
      default:
        return null;
    }
  }

  String _createPersonLabel() {
    final labelStyle =
        ref.read(relationshipLabelStyleProvider).value ??
        relationshipLabelStyleDefault;
    switch (_selectedRelation) {
      case 'father':
        return labelStyle == RelationshipLabelStyle.neutral
            ? 'Create Parent'
            : 'Create Father';
      case 'mother':
        return labelStyle == RelationshipLabelStyle.neutral
            ? 'Create Parent'
            : 'Create Mother';
      case 'spouse':
        return 'Create Spouse';
      case 'child':
        return 'Create Son or Daughter';
      default:
        return 'Create Person';
    }
  }

  String _initialGenderForNewPerson(String linkedGender) {
    switch (_selectedRelation) {
      case 'father':
        return 'male';
      case 'mother':
        return 'female';
      case 'spouse':
        if (linkedGender == 'male') return 'female';
        if (linkedGender == 'female') return 'male';
        return 'other';
      default:
        return 'other';
    }
  }

  void _openNewPersonForm(GenealogyPerson currentPerson) {
    final relationKind = switch (_selectedRelation) {
      'father' || 'mother' => 'parent',
      'child' => 'child',
      'spouse' => 'spouse',
      _ => 'parent',
    };

    final queryParameters = <String, String>{
      'linkPersonId': currentPerson.id,
      'relationKind': relationKind,
      'returnTo': '/people/${widget.personId}',
      'initialGender': _initialGenderForNewPerson(currentPerson.gender),
    };

    context.go('/people/add?${Uri(queryParameters: queryParameters).query}');
  }

  @override
  Widget build(BuildContext context) {
    final currentPersonAsync = ref.watch(personByIdProvider(widget.personId));
    final peopleAsync = ref.watch(peopleListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Relationship')),
      body: currentPersonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load person:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (currentPerson) {
          if (currentPerson == null) {
            return const Center(child: Text('Person not found'));
          }

          return peopleAsync.when(
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
              final availablePeople = people
                  .where((person) => person.id != currentPerson.id)
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CurrentPersonCard(person: currentPerson),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Relationship',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRelation,
                    decoration: const InputDecoration(
                      labelText: 'Relationship Type',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'father', child: Text('Father')),
                      DropdownMenuItem(value: 'mother', child: Text('Mother')),
                      DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                      DropdownMenuItem(
                        value: 'child',
                        child: Text('Son or Daughter'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedRelation = value;
                        _selectedPersonId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _relationHelpText(),
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'existing',
                        label: Text('Existing person'),
                        icon: Icon(Icons.person_search_outlined),
                      ),
                      ButtonSegment(
                        value: 'new',
                        label: Text('Create new'),
                        icon: Icon(Icons.person_add_alt_1_outlined),
                      ),
                    ],
                    selected: <String>{_personSelectionMode},
                    onSelectionChanged: (selection) {
                      final nextMode = selection.first;
                      setState(() {
                        _personSelectionMode = nextMode;
                        _selectedPersonId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Person',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (_personSelectionMode == 'existing') ...[
                    if (availablePeople.isEmpty)
                      const _NoPeopleAvailableCard()
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPersonId,
                        decoration: const InputDecoration(
                          labelText: 'Choose existing person',
                          prefixIcon: Icon(Icons.person_search_outlined),
                        ),
                        items: availablePeople.map((person) {
                          return DropdownMenuItem(
                            value: person.id,
                            child: Text(person.fullName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPersonId = value;
                          });
                        },
                      ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a new person and link them as ${_selectedRelation == 'father' || _selectedRelation == 'mother' ? 'parent' : _selectedRelation}.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You will fill the person details first, then the relationship will be saved automatically.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (_personSelectionMode == 'existing')
                    FilledButton.icon(
                      onPressed: _isSaving || availablePeople.isEmpty
                          ? null
                          : () => _saveRelationship(currentPerson),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_outlined),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Relationship',
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _openNewPersonForm(currentPerson),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(_createPersonLabel()),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CurrentPersonCard extends StatelessWidget {
  const _CurrentPersonCard({required this.person});

  final GenealogyPerson person;

  @override
  Widget build(BuildContext context) {
    final initial = person.fullName.trim().isNotEmpty
        ? person.fullName.trim()[0].toUpperCase()
        : '?';

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(initial)),
        title: const Text('Adding relationship for'),
        subtitle: Text(
          person.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _NoPeopleAvailableCard extends StatelessWidget {
  const _NoPeopleAvailableCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.person_add_disabled_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No other person available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add more family members first, then connect relationships.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

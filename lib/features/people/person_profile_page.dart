import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_background.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/person_avatar.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/relationship_repository_provider.dart';
import '../../data/repositories/relationship_repository.dart';
import '../settings/app_settings_provider.dart';
import '../tree/family_charts_pages.dart';
import '../settings/display_formatters.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import 'people_providers.dart';
import 'person_relationship_models.dart';

class PersonProfilePage extends ConsumerWidget {
  const PersonProfilePage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(personByIdProvider(personId));
    final parentsAsync = ref.watch(parentItemsProvider(personId));
    final spousesAsync = ref.watch(spouseItemsProvider(personId));
    final childrenAsync = ref.watch(childItemsProvider(personId));
    final dateFormat =
        ref.watch(dateDisplayFormatProvider).value ?? dateDisplayFormatDefault;
    final labelStyle =
        ref.watch(relationshipLabelStyleProvider).value ??
        relationshipLabelStyleDefault;
    final photoFitMode =
        ref.watch(personPhotoFitModeProvider).value ??
        personPhotoFitModeDefault;
    final hideYearsForLiving =
        ref.watch(hideYearsForLivingProvider).value ??
        hideYearsForLivingDefault;
    final relationAvailability = _RelationAvailability.fromAsyncValues(
      parentsAsync: parentsAsync,
      spousesAsync: spousesAsync,
      childrenAsync: childrenAsync,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Profile'),
        actions: [
          if (relationAvailability.hasMissingParentRelations)
            PopupMenuButton<_RelationAction>(
              tooltip: 'Add family relation',
              onSelected: (action) {
                _showRelationChoiceSheet(
                  context: context,
                  personId: personId,
                  action: action,
                );
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<_RelationAction>>[];
                if (relationAvailability.canAddFather) {
                  items.add(
                    const PopupMenuItem(
                      value: _RelationAction.father,
                      child: Text('Add Father'),
                    ),
                  );
                }
                if (relationAvailability.canAddMother) {
                  items.add(
                    const PopupMenuItem(
                      value: _RelationAction.mother,
                      child: Text('Add Mother'),
                    ),
                  );
                }
                return items;
              },
            ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.push('/people/$personId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: personAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load profile:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (person) {
          if (person == null) {
            return const Center(child: Text('Person not found'));
          }

          final birthDateText = formatDateForDisplay(
            person.birthDate,
            dateFormat,
            hideYear: person.isLiving && hideYearsForLiving,
          );
          final lifespanText = formatLifespanForDisplay(
            person.birthDate,
            person.deathDate,
            dateFormat,
            isLiving: person.isLiving,
            hideYearsForLiving: hideYearsForLiving,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.55),
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.7),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 150),
                children: [
                  _ProfileSummaryCard(
                    displayName: _displayName(person),
                    gender: person.gender,
                    isLiving: person.isLiving,
                    profilePhotoPath: person.profilePhotoPath,
                    photoFitMode: photoFitMode,
                    birthPlace: person.birthPlace,
                    birthDateText: birthDateText,
                    lifespanText: lifespanText,
                  ),
                  const SizedBox(height: 12),
                  _LifeOverviewCard(
                    birthDateText: birthDateText,
                    birthPlace: person.birthPlace,
                    ageText: _ageText(person.birthDate, person.isLiving),
                    currentPlace: person.currentPlace,
                  ),
                  const SizedBox(height: 12),
                  _FamilyRelationsCard(
                    personId: personId,
                    personGender: person.gender,
                    relationAvailability: relationAvailability,
                    labelStyle: labelStyle,
                    dateFormat: dateFormat,
                    photoFitMode: photoFitMode,
                    hideYearsForLiving: hideYearsForLiving,
                  ),
                  const SizedBox(height: 12),
                  _NotesCard(
                    text: person.bio == null || person.bio!.trim().isEmpty
                        ? 'No notes added yet.'
                        : person.bio!,
                  ),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 8,
                child: _ActionDock(
                  onTree: () => showChartPicker(context, personId),
                  onMedia: () => context.push('/people/$personId/media'),
                  onFacts: () => context.push('/people/$personId/facts'),
                  onEdit: () => context.push('/people/$personId/edit'),
                  onDelete: () => _confirmDelete(context, ref),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove person from tree?'),
          content: const Text(
            'This removes the person from the tree. Their children and the '
            'people they were married to stay in the tree, and a family that '
            'exists only for this person is removed with them.\n\n'
            'The record is kept recoverably rather than erased, but it will no '
            'longer appear anywhere in the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final repository = ref.read(genealogyRepositoryProvider);
      await repository.deletePerson(personId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Person removed from the tree.')),
      );

      context.pop();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete person: $e')));
    }
  }

  String _displayName(GenealogyPerson person) {
    final parts = <String>[
      if ((person.prefix ?? '').trim().isNotEmpty) person.prefix!.trim(),
      if (person.firstName.trim().isNotEmpty) person.firstName.trim(),
      if ((person.middleName ?? '').trim().isNotEmpty)
        person.middleName!.trim(),
      if (_displaySurname(person).isNotEmpty) _displaySurname(person),
      if ((person.suffix ?? '').trim().isNotEmpty) person.suffix!.trim(),
    ];

    return parts.isEmpty ? person.fullName : parts.join(' ');
  }

  String _displaySurname(GenealogyPerson person) {
    if (person.gender == 'female') {
      final marriedSurname = (person.marriedSurname ?? '').trim();
      if (marriedSurname.isNotEmpty) return marriedSurname;
    }

    final birthSurname = (person.birthSurname ?? '').trim();
    if (birthSurname.isNotEmpty) return birthSurname;

    return (person.lastName ?? '').trim();
  }

  String _ageText(DateTime? birthDate, bool isLiving) {
    if (birthDate == null) return 'Not available';
    if (!isLiving) return 'Deceased';
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthdayThisYear =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthdayThisYear) age--;
    return '$age Years';
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.displayName,
    required this.gender,
    required this.isLiving,
    required this.profilePhotoPath,
    required this.photoFitMode,
    required this.birthPlace,
    required this.birthDateText,
    required this.lifespanText,
  });

  final String displayName;
  final String gender;
  final bool isLiving;
  final String? profilePhotoPath;
  final PersonPhotoFitMode photoFitMode;
  final String? birthPlace;
  final String birthDateText;
  final String lifespanText;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.centerRight,
                opacity: 0.06,
                scale: 1.15,
                padding: EdgeInsets.only(right: 8),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PersonAvatar(
                          photoPath: profilePhotoPath,
                          initialText: initial,
                          size: 92,
                          fitMode: photoFitMode,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _Pill(
                                label: _genderLabel(gender),
                                icon: _genderIcon(gender),
                              ),
                              _Pill(
                                label: isLiving ? 'Living' : 'Deceased',
                                icon: isLiving
                                    ? Icons.favorite_outline
                                    : Icons.history_toggle_off_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMeta(
                        icon: Icons.location_on_outlined,
                        value: birthPlace?.trim().isNotEmpty == true
                            ? birthPlace!.trim()
                            : 'Not added',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: _MiniMeta(
                        icon: Icons.event_outlined,
                        value: lifespanText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _genderIcon(String gender) {
    switch (gender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.person_outline;
    }
  }

  String _genderLabel(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Other';
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LifeOverviewCard extends StatelessWidget {
  const _LifeOverviewCard({
    required this.birthDateText,
    required this.birthPlace,
    required this.ageText,
    required this.currentPlace,
  });

  final String birthDateText;
  final String? birthPlace;
  final String ageText;
  final String? currentPlace;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.topRight,
                opacity: 0.045,
                scale: 1.0,
                padding: EdgeInsets.only(top: 8, right: 4),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Life Overview',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: constraints.maxWidth > 420 ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3.15,
                      children: [
                        _OverviewTile(
                          icon: Icons.event_outlined,
                          title: 'Birth Date',
                          value: birthDateText,
                        ),
                        _OverviewTile(
                          icon: Icons.location_on_outlined,
                          title: 'Birth Place',
                          value: birthPlace?.trim().isNotEmpty == true
                              ? birthPlace!.trim()
                              : 'Not added',
                        ),
                        _OverviewTile(
                          icon: Icons.timelapse_outlined,
                          title: 'Age',
                          value: ageText,
                        ),
                        _OverviewTile(
                          icon: Icons.home_outlined,
                          title: 'Current Place',
                          value: currentPlace?.trim().isNotEmpty == true
                              ? currentPlace!.trim()
                              : 'Not added',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.bottomRight,
                opacity: 0.042,
                scale: 0.92,
                padding: EdgeInsets.only(bottom: 4, right: 6),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Life Story / Notes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    OutlinedButton(onPressed: null, child: const Text('+ Add')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: text == 'No notes added yet.' ? Colors.grey : null,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.onTree,
    required this.onMedia,
    required this.onFacts,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onTree;
  final VoidCallback onMedia;
  final VoidCallback onFacts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        return Card(
          color: Theme.of(context).colorScheme.surface,
          elevation: 5,
          shadowColor: Theme.of(
            context,
          ).colorScheme.shadow.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 8 : 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DockAction(
                  icon: Icons.account_tree_outlined,
                  label: 'Tree',
                  onTap: onTree,
                  compact: compact,
                ),
                _DockAction(
                  icon: Icons.collections_outlined,
                  label: 'Media',
                  onTap: onMedia,
                  compact: compact,
                ),
                FloatingActionButton(
                  onPressed: onEdit,
                  heroTag: 'profile_fab',
                  mini: false,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
                _DockAction(
                  icon: Icons.menu_book_outlined,
                  label: 'Facts',
                  onTap: onFacts,
                  compact: compact,
                ),
                _DockAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: onDelete,
                  danger: true,
                  compact: compact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 2, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: compact ? 22 : 24),
            if (!compact) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: 52,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FamilyRelationsCard extends ConsumerWidget {
  const _FamilyRelationsCard({
    required this.personId,
    required this.personGender,
    required this.relationAvailability,
    required this.labelStyle,
    required this.dateFormat,
    required this.photoFitMode,
    required this.hideYearsForLiving,
  });

  final String personId;
  final String? personGender;
  final _RelationAvailability relationAvailability;
  final RelationshipLabelStyle labelStyle;
  final DateDisplayFormat dateFormat;
  final PersonPhotoFitMode photoFitMode;
  final bool hideYearsForLiving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(parentItemsProvider(personId));
    final spousesAsync = ref.watch(spouseItemsProvider(personId));
    final childrenAsync = ref.watch(childItemsProvider(personId));
    final siblingsAsync = ref.watch(siblingItemsProvider(personId));

    return _InfoCard(
      title: 'Family Relations',
      trailing: relationAvailability.hasMissingParentRelations
          ? PopupMenuButton<_RelationAction>(
              tooltip: 'Add family relation',
              onSelected: (action) {
                _showRelationChoiceSheet(
                  context: context,
                  personId: personId,
                  personGender: personGender,
                  action: action,
                );
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<_RelationAction>>[];
                if (relationAvailability.canAddFather) {
                  items.add(
                    const PopupMenuItem(
                      value: _RelationAction.father,
                      child: Text('Add Father'),
                    ),
                  );
                }
                if (relationAvailability.canAddMother) {
                  items.add(
                    const PopupMenuItem(
                      value: _RelationAction.mother,
                      child: Text('Add Mother'),
                    ),
                  );
                }
                return items;
              },
            )
          : null,
      children: [
        _FamilyRow(
          icon: Icons.family_restroom_outlined,
          title: 'Parents',
          subtitle: _relationSubtitle(parentsAsync),
          details: _relationDetails(
            parentsAsync,
            relationKind: _RelationRowKind.parents,
          ),
          onRemoveDetail: (detail) =>
              _removeRelation(context, ref, detail, _RelationRowKind.parents),
          canAdd: relationAvailability.hasMissingParentRelations,
          onAdd: relationAvailability.hasMissingParentRelations
              ? () => _showRelationChoiceSheet(
                  context: context,
                  personId: personId,
                  personGender: personGender,
                  action: relationAvailability.canAddFather
                      ? _RelationAction.father
                      : _RelationAction.mother,
                )
              : null,
        ),
        _FamilyRow(
          icon: Icons.favorite_outline,
          title: 'Spouse',
          subtitle: _relationSubtitle(spousesAsync),
          details: _relationDetails(
            spousesAsync,
            relationKind: _RelationRowKind.spouse,
          ),
          onRemoveDetail: (detail) =>
              _removeRelation(context, ref, detail, _RelationRowKind.spouse),
          canAdd: relationAvailability.canAddSpouse,
          onAdd: relationAvailability.canAddSpouse
              ? () => _showRelationChoiceSheet(
                  context: context,
                  personId: personId,
                  personGender: personGender,
                  action: _RelationAction.spouse,
                )
              : null,
        ),
        _FamilyRow(
          icon: Icons.child_care_outlined,
          title: 'Children',
          subtitle: _relationSubtitle(childrenAsync),
          details: _relationDetails(
            childrenAsync,
            relationKind: _RelationRowKind.children,
          ),
          onRemoveDetail: (detail) =>
              _removeRelation(context, ref, detail, _RelationRowKind.children),
          canAdd: relationAvailability.canAddChild,
          onAdd: relationAvailability.canAddChild
              ? () => _showRelationChoiceSheet(
                  context: context,
                  personId: personId,
                  personGender: personGender,
                  action: _RelationAction.child,
                )
              : null,
        ),
        _FamilyRow(
          icon: Icons.groups_2_outlined,
          title: 'Siblings',
          subtitle: _relationSubtitle(siblingsAsync),
          details: _relationDetails(
            siblingsAsync,
            relationKind: _RelationRowKind.siblings,
          ),
          onRemoveDetail: (detail) =>
              _removeRelation(context, ref, detail, _RelationRowKind.siblings),
          canAdd: relationAvailability.canAddSibling,
          onAdd: relationAvailability.canAddSibling
              ? () => _showRelationChoiceSheet(
                  context: context,
                  personId: personId,
                  personGender: personGender,
                  action: _RelationAction.sibling,
                )
              : null,
        ),
      ],
    );
  }

  String _relationSubtitle(AsyncValue<List<PersonRelationItem>> itemsAsync) {
    final count = itemsAsync.asData?.value.length ?? 0;
    return count == 0 ? 'Not added' : '$count added';
  }

  List<_RelationDetail> _relationDetails(
    AsyncValue<List<PersonRelationItem>> itemsAsync, {
    required _RelationRowKind relationKind,
  }) {
    final items = itemsAsync.asData?.value ?? const <PersonRelationItem>[];
    if (items.isEmpty) return const [];

    return items.map((item) {
      final label = switch (relationKind) {
        _RelationRowKind.parents => switch (item.person.gender) {
          'male' => 'Father',
          'female' => 'Mother',
          _ => 'Parent',
        },
        _RelationRowKind.spouse => switch (item.person.gender) {
          'male' => 'Husband',
          'female' => 'Wife',
          _ => 'Spouse',
        },
        _RelationRowKind.children => switch (item.person.gender) {
          'male' => 'Son',
          'female' => 'Daughter',
          _ => 'Child',
        },
        _RelationRowKind.siblings => switch (item.person.gender) {
          'male' => 'Brother',
          'female' => 'Sister',
          _ => 'Sibling',
        },
      };

      // Non-biological parentage is labelled, so an adoptive or step link
      // never masquerades as a biological one.
      final type = item.relationshipType;
      final labelled =
          type == null ||
              type == 'biological' ||
              relationKind == _RelationRowKind.spouse ||
              relationKind == _RelationRowKind.siblings
          ? label
          : '$label · $type';

      return _RelationDetail(
        label: labelled,
        displayName: _displayName(item.person),
        personId: item.person.id,
        removable: relationKind == _RelationRowKind.siblings || item.canRemove,
      );
    }).toList();
  }

  Future<void> _removeRelation(
    BuildContext context,
    WidgetRef ref,
    _RelationDetail detail,
    _RelationRowKind kind,
  ) async {
    final person = detail.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove relationship?'),
        content: Text(switch (kind) {
          _RelationRowKind.parents =>
            'Remove ${detail.label.toLowerCase()} $person? $person stays in the tree.',
          _RelationRowKind.spouse =>
            'End the partnership with $person? $person stays in the tree.',
          _RelationRowKind.children =>
            'Remove $person as this person\'s child? $person stays in the tree.',
          _RelationRowKind.siblings =>
            'Remove $person as a sibling? This deletes $person\'s links to '
                'the parents shared with this person; any other parentage '
                'stays. $person stays in the tree.',
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final repository = ref.read(relationshipRepositoryProvider);
    const treeId = AppConstants.defaultTreeId;
    try {
      switch (kind) {
        case _RelationRowKind.spouse:
          try {
            await repository.removeSpouseRelationship(
              treeId: treeId,
              personAId: personId,
              personBId: detail.personId,
            );
          } on StateError {
            // The partnership has children linked through it — ending it
            // removes those parent-child links too. Say so before doing it.
            if (!context.mounted) return;
            final removeChildren = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Children are linked'),
                content: const Text(
                  'This partnership records parent-child links. Ending it '
                  'removes those links as well; the children stay in the '
                  'tree and can be re-linked to a parent afterwards.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Remove all links'),
                  ),
                ],
              ),
            );
            if (removeChildren != true || !context.mounted) return;
            await repository.removeSpouseRelationship(
              treeId: treeId,
              personAId: personId,
              personBId: detail.personId,
              removeChildRelationships: true,
            );
          }
          break;
        case _RelationRowKind.parents:
          await _removeParentLink(
            context,
            repository,
            treeId,
            detail.personId,
            personId,
          );
          break;
        case _RelationRowKind.children:
          await _removeParentLink(
            context,
            repository,
            treeId,
            personId,
            detail.personId,
          );
          break;
        case _RelationRowKind.siblings:
          await repository.removeSiblingRelationship(
            treeId: treeId,
            personId: personId,
            siblingId: detail.personId,
          );
          break;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Relationship removed.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove relationship: $e')),
      );
    }
  }

  /// Removes a parent→child link, escalating once when the family has a
  /// co-parent whose parentage would drop with it.
  Future<void> _removeParentLink(
    BuildContext context,
    RelationshipRepository repository,
    String treeId,
    String parentId,
    String childId,
  ) async {
    try {
      await repository.removeParentChildRelationship(
        treeId: treeId,
        parentId: parentId,
        childId: childId,
      );
      return;
    } on StateError {
      // A co-parent is recorded in the same family.
    }
    if (!context.mounted) return;

    final removeBoth = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('The other parent is linked too'),
        content: const Text(
          'Both parents are recorded in the same family, so removing this '
          'link also removes the other parent\'s link. The child stays in '
          'the tree and can be re-linked afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove both'),
          ),
        ],
      ),
    );
    if (removeBoth != true) return;

    await repository.removeParentChildRelationship(
      treeId: treeId,
      parentId: parentId,
      childId: childId,
      removeCoParent: true,
    );
  }

  String _displayName(GenealogyPerson person) {
    final parts = <String>[
      if ((person.prefix ?? '').trim().isNotEmpty) person.prefix!.trim(),
      if ((person.firstName).trim().isNotEmpty) person.firstName.trim(),
      if ((person.middleName ?? '').trim().isNotEmpty)
        person.middleName!.trim(),
      if (_displaySurname(person).isNotEmpty) _displaySurname(person),
      if ((person.suffix ?? '').trim().isNotEmpty) person.suffix!.trim(),
    ];

    return parts.isEmpty ? person.fullName : parts.join(' ');
  }

  String _displaySurname(GenealogyPerson person) {
    if (person.gender == 'female') {
      final marriedSurname = (person.marriedSurname ?? '').trim();
      if (marriedSurname.isNotEmpty) return marriedSurname;
    }

    final birthSurname = (person.birthSurname ?? '').trim();
    if (birthSurname.isNotEmpty) return birthSurname;

    return (person.lastName ?? '').trim();
  }
}

class _FamilyRow extends StatelessWidget {
  const _FamilyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.canAdd,
    required this.onAdd,
    this.onRemoveDetail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<_RelationDetail> details;
  final bool canAdd;
  final VoidCallback? onAdd;
  final void Function(_RelationDetail detail)? onRemoveDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: compact ? 19 : 21,
                ),
              ),
              SizedBox(width: compact ? 11 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      details.isNotEmpty ? '' : subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: compact ? 11.8 : 12.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: details.map((detail) {
                          final removable =
                              detail.removable && onRemoveDetail != null;
                          return Container(
                            padding: const EdgeInsets.only(
                              left: 10,
                              top: 7,
                              bottom: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => context.push(
                                    '/people/${detail.personId}',
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${detail.label} : ${detail.displayName}',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: compact ? 11.0 : 11.6,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 15,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                                if (removable)
                                  Tooltip(
                                    message: 'Remove relationship',
                                    child: InkWell(
                                      onTap: () => onRemoveDetail!(detail),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          6,
                                          2,
                                          6,
                                          2,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!removable) const SizedBox(width: 10),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (canAdd && onAdd != null)
                compact
                    ? IconButton(
                        onPressed: onAdd,
                        tooltip: 'Add',
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 25,
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onAdd,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('+ Add'),
                      ),
            ],
          ),
        );
      },
    );
  }
}

class _RelationDetail {
  const _RelationDetail({
    required this.label,
    required this.displayName,
    required this.personId,
    this.removable = false,
  });

  final String label;
  final String displayName;
  final String personId;

  /// Whether the UI offers unlinking for this row. Siblings are always
  /// removable (unlinking deletes the shared parentage); the other kinds are
  /// removable when the item carries the row that ties them together.
  final bool removable;
}

enum _RelationRowKind { parents, spouse, children, siblings }

class _RelationAvailability {
  const _RelationAvailability({
    required this.canAddFather,
    required this.canAddMother,
    required this.canAddChild,
    required this.canAddSpouse,
    required this.canAddSibling,
  });

  final bool canAddFather;
  final bool canAddMother;
  final bool canAddChild;
  final bool canAddSpouse;
  final bool canAddSibling;

  bool get hasMissingParentRelations => canAddFather || canAddMother;

  bool get hasMissingRelations =>
      hasMissingParentRelations || canAddChild || canAddSpouse || canAddSibling;

  static _RelationAvailability fromAsyncValues({
    required AsyncValue<List<PersonRelationItem>> parentsAsync,
    required AsyncValue<List<PersonRelationItem>> spousesAsync,
    required AsyncValue<List<PersonRelationItem>> childrenAsync,
  }) {
    if (parentsAsync.isLoading ||
        spousesAsync.isLoading ||
        childrenAsync.isLoading) {
      return const _RelationAvailability(
        canAddFather: false,
        canAddMother: false,
        canAddChild: false,
        canAddSpouse: false,
        canAddSibling: false,
      );
    }

    final parents = parentsAsync.asData?.value ?? const <PersonRelationItem>[];
    final hasFather = parents.any((item) => item.person.gender == 'male');
    final hasMother = parents.any((item) => item.person.gender == 'female');
    final canAddFather = parents.length < 2 && !hasFather;
    final canAddMother = parents.length < 2 && !hasMother;
    final canAddChild = true;
    // Multiple partnerships are part of the domain (remarriage), so a spouse
    // can always be added.
    final canAddSpouse = true;
    // One recorded parent is enough to establish a sibling: the sibling is
    // attached to every family the profile person is a child of.
    final canAddSibling = parents.isNotEmpty;

    return _RelationAvailability(
      canAddFather: canAddFather,
      canAddMother: canAddMother,
      canAddChild: canAddChild,
      canAddSpouse: canAddSpouse,
      canAddSibling: canAddSibling,
    );
  }
}

enum _RelationAction { father, mother, son, daughter, spouse, child, sibling }

void _showRelationChoiceSheet({
  required BuildContext context,
  required String personId,
  String? personGender,
  required _RelationAction action,
}) {
  final relationKind = switch (action) {
    _RelationAction.father => 'parent',
    _RelationAction.mother => 'parent',
    _RelationAction.son => 'child',
    _RelationAction.daughter => 'child',
    _RelationAction.spouse => 'spouse',
    _RelationAction.child => 'child',
    _RelationAction.sibling => 'sibling',
  };

  final title = switch (action) {
    _RelationAction.father => 'Add Father',
    _RelationAction.mother => 'Add Mother',
    _RelationAction.son => 'Add Son',
    _RelationAction.daughter => 'Add Daughter',
    _RelationAction.spouse => 'Add Spouse',
    _RelationAction.child => 'Add Child',
    _RelationAction.sibling => 'Add Sibling',
  };

  final relationLabel = switch (action) {
    _RelationAction.father => 'father',
    _RelationAction.mother => 'mother',
    _RelationAction.son => 'son',
    _RelationAction.daughter => 'daughter',
    _RelationAction.spouse => 'spouse',
    _RelationAction.child => 'child',
    _RelationAction.sibling => 'sibling',
  };

  final createLabel = switch (action) {
    _RelationAction.father => 'Create New Father',
    _RelationAction.mother => 'Create New Mother',
    _RelationAction.son => 'Create New Son',
    _RelationAction.daughter => 'Create New Daughter',
    _RelationAction.spouse => 'Create New Spouse',
    _RelationAction.child => 'Create New Child',
    _RelationAction.sibling => 'Create New Sibling',
  };

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose whether to connect someone already in the tree or create a new person first. For siblings, the new person will share the same parents automatically.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push(
                    '/people/$personId/add-relationship?${Uri(queryParameters: {'relation': relationKind}).query}',
                  );
                },
                icon: const Icon(Icons.person_search_outlined),
                label: Text('Link existing $relationLabel'),
              ),
              const SizedBox(height: 10),
              if (action == _RelationAction.child ||
                  action == _RelationAction.sibling) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          final isSibling = action == _RelationAction.sibling;
                          context.go(
                            '/people/add?${Uri(queryParameters: {'linkPersonId': personId, 'relationKind': isSibling ? 'sibling' : 'child', if (isSibling) 'siblingOfPersonId': personId, 'returnTo': '/people/$personId', 'initialGender': 'male'}).query}',
                          );
                        },
                        icon: const Icon(Icons.person_outline),
                        label: Text(
                          action == _RelationAction.sibling
                              ? 'Create Brother'
                              : 'Create Son',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          final isSibling = action == _RelationAction.sibling;
                          context.go(
                            '/people/add?${Uri(queryParameters: {'linkPersonId': personId, 'relationKind': isSibling ? 'sibling' : 'child', if (isSibling) 'siblingOfPersonId': personId, 'returnTo': '/people/$personId', 'initialGender': 'female'}).query}',
                          );
                        },
                        icon: const Icon(Icons.person_outline),
                        label: Text(
                          action == _RelationAction.sibling
                              ? 'Create Sister'
                              : 'Create Daughter',
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go(
                      '/people/add?${Uri(queryParameters: {
                        'linkPersonId': personId,
                        'relationKind': relationKind,
                        'returnTo': '/people/$personId',
                        'initialGender': _initialGenderForRelation(action, linkedGender: personGender),
                      }).query}',
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(createLabel),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

String _initialGenderForRelation(
  _RelationAction action, {
  required String? linkedGender,
}) {
  switch (action) {
    case _RelationAction.father:
      return 'male';
    case _RelationAction.mother:
      return 'female';
    case _RelationAction.son:
      return 'male';
    case _RelationAction.daughter:
      return 'female';
    case _RelationAction.spouse:
      if (linkedGender == 'male') return 'female';
      if (linkedGender == 'female') return 'male';
      return 'other';
    case _RelationAction.child:
      if (linkedGender == 'male') return 'male';
      if (linkedGender == 'female') return 'female';
      return 'other';
    case _RelationAction.sibling:
      return 'other';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.topRight,
                opacity: 0.03,
                scale: 0.92,
                padding: EdgeInsets.only(top: 2, right: 4),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _TrailingSlot(child: trailing),
                  ],
                ),
                const SizedBox(height: 10),
                if (children.isNotEmpty) ...children,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailingSlot extends StatelessWidget {
  const _TrailingSlot({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return child ?? const SizedBox.shrink();
  }
}

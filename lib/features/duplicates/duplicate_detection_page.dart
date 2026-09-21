import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import 'duplicate_merge_dialog.dart';
import 'duplicate_scoring_widgets.dart';
import 'person_name_formatter.dart';
import 'duplicate_detection_providers.dart';
import '../../core/constants/app_constants.dart';

class DuplicateDetectionPage extends ConsumerStatefulWidget {
  const DuplicateDetectionPage({super.key});

  @override
  ConsumerState<DuplicateDetectionPage> createState() =>
      _DuplicateDetectionPageState();
}

class _DuplicateDetectionPageState
    extends ConsumerState<DuplicateDetectionPage> {
  String _searchText = '';
  bool _highConfidenceOnly = false;

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(duplicateCandidatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate Detection')),
      body: candidatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load duplicate suggestions:\n$error'),
          ),
        ),
        data: (candidates) {
          final filtered = candidates
              .where((candidate) {
                if (_searchText.trim().isEmpty) return true;
                final query = _searchText.trim().toLowerCase();
                return displayPersonName(
                      candidate.primary,
                    ).toLowerCase().contains(query) ||
                    displayPersonName(
                      candidate.duplicate,
                    ).toLowerCase().contains(query) ||
                    candidate.reason.toLowerCase().contains(query);
              })
              .where((candidate) {
                if (!_highConfidenceOnly) return true;
                return candidate.score >= 80;
              })
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search duplicate pairs',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            setState(() {
                              _searchText = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) => setState(() => _searchText = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High-confidence only'),
                subtitle: const Text(
                  'Show only stronger matches with score 80 or above.',
                ),
                value: _highConfidenceOnly,
                onChanged: (value) {
                  setState(() {
                    _highConfidenceOnly = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _SummaryCard(count: filtered.length),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const _EmptyDuplicatesView()
              else
                ...filtered.map(
                  (candidate) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DuplicateCandidateCard(
                      candidate: candidate,
                      onMerge: () =>
                          _showMergePreviewDialog(context, candidate),
                      onMark: () => _markCandidate(context, candidate),
                      onOpenPrimary: () =>
                          context.push('/people/${candidate.primary.id}'),
                      onOpenDuplicate: () =>
                          context.push('/people/${candidate.duplicate.id}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMergePreviewDialog(
    BuildContext context,
    DuplicateCandidate candidate,
  ) async {
    final selection = await showDuplicateMergeDialog(
      context,
      candidate: candidate,
      title: 'Merge duplicates?',
    );

    if (selection == null) return;

    final repository = ref.read(genealogyRepositoryProvider);
    final survivorId = selection.keepPrimary
        ? candidate.primary.id
        : candidate.duplicate.id;
    final duplicateId = selection.keepPrimary
        ? candidate.duplicate.id
        : candidate.primary.id;

    try {
      await repository.mergePeople(
        survivorId: survivorId,
        duplicateId: duplicateId,
        preferredBirthDateSource: selection.preferredBirthDateSource,
        preferredDeathDateSource: selection.preferredDeathDateSource,
        preferredBirthPlaceSource: selection.preferredBirthPlaceSource,
        preferredCurrentPlaceSource: selection.preferredCurrentPlaceSource,
        preferredBioSource: selection.preferredBioSource,
        preferredNotesSource: selection.preferredNotesSource,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('People merged successfully.')),
      );
      ref.invalidate(duplicateCandidatesProvider);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to merge people: $e')));
    }
  }

  Future<void> _markCandidate(
    BuildContext context,
    DuplicateCandidate candidate,
  ) async {
    try {
      await ref
          .read(genealogyRepositoryProvider)
          .markAsDuplicate(
            treeId: AppConstants.defaultTreeId,
            sourceId: candidate.primary.id,
            targetId: candidate.duplicate.id,
            reason: candidate.reason,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as duplicate for review.')),
      );
      ref.invalidate(duplicateCandidatesProvider);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark duplicate: $e')));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          count == 0
              ? 'No likely duplicate pairs found.'
              : '$count likely duplicate pair${count == 1 ? '' : 's'} found.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DuplicateCandidateCard extends StatelessWidget {
  const _DuplicateCandidateCard({
    required this.candidate,
    required this.onMerge,
    required this.onMark,
    required this.onOpenPrimary,
    required this.onOpenDuplicate,
  });

  final DuplicateCandidate candidate;
  final VoidCallback onMerge;
  final VoidCallback onMark;
  final VoidCallback onOpenPrimary;
  final VoidCallback onOpenDuplicate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.reason,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Chip(label: Text('${candidate.score}%')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Will move: ${candidate.preview.eventCount} events, '
              '${candidate.preview.noteCount} notes, '
              '${candidate.preview.mediaCount} media, '
              '${candidate.preview.relationshipCount} relationships',
            ),
            const SizedBox(height: 8),
            DuplicateScoringToggle(
              title: 'Why flagged?',
              reason: candidate.reason,
              preview: candidate.preview,
              score: candidate.score,
              matchDetails: candidate.matchDetails,
            ),
            if (candidate.isMarked) ...[
              const SizedBox(height: 8),
              const Chip(
                avatar: Icon(Icons.flag_outlined, size: 18),
                label: Text('Already marked'),
              ),
            ],
            const SizedBox(height: 12),
            _PersonRow(
              label: 'Keep',
              person: candidate.primary,
              onTap: onOpenPrimary,
              accent: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 8),
            _PersonRow(
              label: 'Merge',
              person: candidate.duplicate,
              onTap: onOpenDuplicate,
              accent: Theme.of(context).colorScheme.secondaryContainer,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: candidate.isMarked ? null : onMark,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Mark'),
                  ),
                  FilledButton.icon(
                    onPressed: onMerge,
                    icon: const Icon(Icons.merge_type_outlined),
                    label: const Text('Merge'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.label,
    required this.person,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final GenealogyPerson person;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(child: Text(label[0])),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12)),
                  Text(
                    displayPersonName(person),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _EmptyDuplicatesView extends StatelessWidget {
  const _EmptyDuplicatesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rule_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No likely duplicates found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Duplicate suggestions appear when names and dates are close enough to review safely.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

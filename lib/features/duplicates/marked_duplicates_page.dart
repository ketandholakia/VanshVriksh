import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/research_notes_repository_provider.dart';
import 'duplicate_merge_dialog.dart';
import 'duplicate_scoring_widgets.dart';
import 'person_name_formatter.dart';
import 'duplicate_detection_providers.dart';

class _MarkedDuplicateViewModel {
  const _MarkedDuplicateViewModel({
    required this.marker,
    required this.personA,
    required this.personB,
    required this.preview,
  });

  final DuplicateMarker marker;
  final GenealogyPerson? personA;
  final GenealogyPerson? personB;
  final DuplicateMergePreview preview;
}

enum _MarkedSort { newest, oldest, score }

final markedDuplicatesProvider =
    FutureProvider<List<_MarkedDuplicateViewModel>>((ref) async {
      final repository = ref.watch(genealogyRepositoryProvider);
      final markers = await repository.getDuplicateMarkers(
        AppConstants.defaultTreeId,
      );
      final people = await repository.getPeopleByTree(
        AppConstants.defaultTreeId,
      );
      final byId = {for (final person in people) person.id: person};

      final views = <_MarkedDuplicateViewModel>[];
      for (final marker in markers) {
        final preview = await repository.getMergePreview(
          survivorId: marker.personAId,
          duplicateId: marker.personBId,
        );
        views.add(
          _MarkedDuplicateViewModel(
            marker: marker,
            personA: byId[marker.personAId],
            personB: byId[marker.personBId],
            preview: preview,
          ),
        );
      }

      return views;
    });

class MarkedDuplicatesPage extends ConsumerStatefulWidget {
  const MarkedDuplicatesPage({super.key});

  @override
  ConsumerState<MarkedDuplicatesPage> createState() =>
      _MarkedDuplicatesPageState();
}

class _MarkedDuplicatesPageState extends ConsumerState<MarkedDuplicatesPage> {
  final _searchController = TextEditingController();
  _MarkedSort _sort = _MarkedSort.newest;
  final Set<String> _selectedKeys = {};

  String get _searchText => _searchController.text.trim().toLowerCase();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(markedDuplicatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Marked Duplicates')),
      body: markersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load marked duplicates:\n$error'),
          ),
        ),
        data: (markers) {
          final filtered = markers.where((marker) {
            if (_searchText.isEmpty) return true;
            return _matchesSearch(marker, _searchText);
          }).toList();

          _sortMarkers(filtered);
          _selectedKeys.removeWhere(
            (key) =>
                !filtered.any((marker) => _markerKey(marker.marker) == key),
          );

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  _searchText.isEmpty
                      ? 'No manual duplicate markers yet.'
                      : 'No marked duplicates matched your search.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search marked pairs',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<_MarkedSort>(
                segments: const [
                  ButtonSegment(
                    value: _MarkedSort.newest,
                    label: Text('Newest'),
                    icon: Icon(Icons.schedule_outlined),
                  ),
                  ButtonSegment(
                    value: _MarkedSort.oldest,
                    label: Text('Oldest'),
                    icon: Icon(Icons.history_outlined),
                  ),
                  ButtonSegment(
                    value: _MarkedSort.score,
                    label: Text('Move count'),
                    icon: Icon(Icons.percent_outlined),
                  ),
                ],
                selected: {_sort},
                onSelectionChanged: (value) {
                  setState(() {
                    _sort = value.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_selectedKeys.isNotEmpty) ...[
                _BulkActionBar(
                  selectedCount: _selectedKeys.length,
                  onSelectAll: () {
                    setState(() {
                      _selectedKeys
                        ..clear()
                        ..addAll(
                          filtered.map((marker) => _markerKey(marker.marker)),
                        );
                    });
                  },
                  onSelectNone: () {
                    setState(() {
                      _selectedKeys.clear();
                    });
                  },
                  onOpenFirst: () {
                    final selected = filtered
                        .where(
                          (marker) =>
                              _selectedKeys.contains(_markerKey(marker.marker)),
                        )
                        .toList();
                    if (selected.isEmpty) return;
                    context.push('/people/${selected.first.marker.personAId}');
                  },
                  onExport: () =>
                      _exportSelectedToReviewNote(context, ref, filtered),
                  onUnmarkSelected: () =>
                      _bulkRemoveMarkers(context, ref, filtered),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${filtered.length} marked pair${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...filtered.map(
                (marker) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _selectedKeys.contains(
                                  _markerKey(marker.marker),
                                ),
                                onChanged: (_) =>
                                    _toggleSelected(marker.marker),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  titleAlignment: ListTileTitleAlignment.top,
                                  title: Text(
                                    marker.marker.reason ??
                                        'Marked duplicate pair',
                                  ),
                                  subtitle: Text(
                                    '${displayPersonNameOrNull(marker.personA) ?? marker.marker.personAId} • '
                                    '${displayPersonNameOrNull(marker.personB) ?? marker.marker.personBId}\n'
                                    'Will move: ${marker.preview.eventCount} events, '
                                    '${marker.preview.noteCount} notes, '
                                    '${marker.preview.mediaCount} media, '
                                    '${marker.preview.relationshipCount} relationships',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'open_a') {
                                        context.push(
                                          '/people/${marker.marker.personAId}',
                                        );
                                      } else if (value == 'open_b') {
                                        context.push(
                                          '/people/${marker.marker.personBId}',
                                        );
                                      } else if (value == 'remove') {
                                        await _removeMarker(
                                          context,
                                          ref,
                                          marker.marker,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'open_a',
                                        child: Text('Open first person'),
                                      ),
                                      PopupMenuItem(
                                        value: 'open_b',
                                        child: Text('Open second person'),
                                      ),
                                      PopupMenuItem(
                                        value: 'remove',
                                        child: Text('Unmark duplicate'),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _toggleSelected(marker.marker),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DuplicateScoringToggle(
                            title: 'Why flagged?',
                            reason: marker.marker.reason ?? 'manual mark',
                            preview: marker.preview,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showMergePreviewDialog(context, marker),
                                  icon: const Icon(Icons.merge_type_outlined),
                                  label: const Text('Merge'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _removeMarker(
                                    context,
                                    ref,
                                    marker.marker,
                                  ),
                                  icon: const Icon(Icons.flag_outlined),
                                  label: const Text('Unmark'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleSelected(DuplicateMarker marker) {
    setState(() {
      final key = _markerKey(marker);
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  String _markerKey(DuplicateMarker marker) {
    final ids = [marker.personAId, marker.personBId]..sort();
    return '${ids[0]}:${ids[1]}';
  }

  void _sortMarkers(List<_MarkedDuplicateViewModel> markers) {
    markers.sort((a, b) {
      switch (_sort) {
        case _MarkedSort.newest:
          return b.marker.createdAt.compareTo(a.marker.createdAt);
        case _MarkedSort.oldest:
          return a.marker.createdAt.compareTo(b.marker.createdAt);
        case _MarkedSort.score:
          final aScore =
              a.preview.eventCount +
              a.preview.noteCount +
              a.preview.mediaCount +
              a.preview.relationshipCount;
          final bScore =
              b.preview.eventCount +
              b.preview.noteCount +
              b.preview.mediaCount +
              b.preview.relationshipCount;
          return bScore.compareTo(aScore);
      }
    });
  }

  bool _matchesSearch(_MarkedDuplicateViewModel marker, String query) {
    final haystack = [
      marker.marker.reason,
      displayPersonNameOrNull(marker.personA),
      displayPersonNameOrNull(marker.personB),
      marker.marker.personAId,
      marker.marker.personBId,
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains(query);
  }

  Future<void> _removeMarker(
    BuildContext context,
    WidgetRef ref,
    DuplicateMarker marker,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unmark duplicate?'),
          content: const Text(
            'This only removes the manual duplicate flag. The people will not be merged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Unmark'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return;

    final repository = ref.read(genealogyRepositoryProvider);
    await repository.deleteDuplicateMarker(
      personAId: marker.personAId,
      personBId: marker.personBId,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Duplicate marker removed.')));
    ref.invalidate(markedDuplicatesProvider);
  }

  Future<void> _bulkRemoveMarkers(
    BuildContext context,
    WidgetRef ref,
    List<_MarkedDuplicateViewModel> markers,
  ) async {
    final selected = markers
        .where((marker) => _selectedKeys.contains(_markerKey(marker.marker)))
        .toList();

    if (selected.isEmpty) return;

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Unmark ${selected.length} duplicate pairs?'),
          content: const Text(
            'This only removes the manual duplicate flags. The people will not be merged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Unmark'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return;

    final repository = ref.read(genealogyRepositoryProvider);
    for (final item in selected) {
      await repository.deleteDuplicateMarker(
        personAId: item.marker.personAId,
        personBId: item.marker.personBId,
      );
    }

    if (!context.mounted) return;

    setState(() {
      _selectedKeys.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selected.length} duplicate markers removed.')),
    );
    ref.invalidate(markedDuplicatesProvider);
  }

  Future<void> _exportSelectedToReviewNote(
    BuildContext context,
    WidgetRef ref,
    List<_MarkedDuplicateViewModel> markers,
  ) async {
    final selected = markers
        .where((marker) => _selectedKeys.contains(_markerKey(marker.marker)))
        .toList();
    if (selected.isEmpty) return;

    final lines = <String>[
      'Marked duplicate review',
      '',
      for (final item in selected) ...[
        '- ${displayPersonNameOrNull(item.personA) ?? item.marker.personAId} vs ${displayPersonNameOrNull(item.personB) ?? item.marker.personBId}',
        '  Reason: ${item.marker.reason ?? 'marked duplicate'}',
        '  Move counts: ${item.preview.eventCount} events, ${item.preview.noteCount} notes, ${item.preview.mediaCount} media, ${item.preview.relationshipCount} relationships',
      ],
    ];

    final repository = ref.read(researchNotesRepositoryProvider);
    await repository.addResearchNote(
      noteText: lines.join('\n'),
      researchQuestion: 'Duplicate review summary',
      noteDate: DateTime.now(),
      noteDateDisplay: 'Today',
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selected pairs exported to a review note.'),
      ),
    );
  }

  Future<void> _showMergePreviewDialog(
    BuildContext context,
    _MarkedDuplicateViewModel marker,
  ) async {
    final candidate = DuplicateCandidate(
      primary: marker.personA ?? marker.personB!,
      duplicate: marker.personB ?? marker.personA!,
      score:
          marker.preview.eventCount +
          marker.preview.noteCount +
          marker.preview.mediaCount +
          marker.preview.relationshipCount,
      reason: marker.marker.reason ?? 'marked duplicate',
      matchDetails: const [],
      preview: marker.preview,
      isMarked: true,
    );

    final selection = await showDuplicateMergeDialog(
      context,
      candidate: candidate,
      title: 'Merge marked duplicates?',
    );

    if (selection == null) return;

    final repository = ref.read(genealogyRepositoryProvider);
    final survivorId = selection.keepPrimary
        ? (marker.personA?.id ?? marker.marker.personAId)
        : (marker.personB?.id ?? marker.marker.personBId);
    final duplicateId = selection.keepPrimary
        ? (marker.personB?.id ?? marker.marker.personBId)
        : (marker.personA?.id ?? marker.marker.personAId);

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
      ref.invalidate(markedDuplicatesProvider);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to merge people: $e')));
    }
  }
}

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.selectedCount,
    required this.onSelectAll,
    required this.onSelectNone,
    required this.onOpenFirst,
    required this.onExport,
    required this.onUnmarkSelected,
  });

  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;
  final VoidCallback onOpenFirst;
  final VoidCallback onExport;
  final VoidCallback onUnmarkSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              '$selectedCount selected',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(onPressed: onSelectAll, child: const Text('Select all')),
            TextButton(
              onPressed: onSelectNone,
              child: const Text('Select none'),
            ),
            OutlinedButton(
              onPressed: onOpenFirst,
              child: const Text('Open first'),
            ),
            OutlinedButton(
              onPressed: onExport,
              child: const Text('Export note'),
            ),
            FilledButton(
              onPressed: onUnmarkSelected,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Unmark'),
            ),
          ],
        ),
      ),
    );
  }
}

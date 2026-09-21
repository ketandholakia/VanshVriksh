import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/events_repository_provider.dart';
import '../../data/providers/research_notes_repository_provider.dart';
import 'person_facts_providers.dart';

enum _FactsFilter { all, dated, undated }

enum _FactKindFilter { all, events, notes }

enum _NoteStatusFilter { all, open, resolved }

class PersonFactsPage extends ConsumerStatefulWidget {
  const PersonFactsPage({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<PersonFactsPage> createState() => _PersonFactsPageState();
}

class _PersonFactsPageState extends ConsumerState<PersonFactsPage> {
  final _searchController = TextEditingController();
  _FactsFilter _filter = _FactsFilter.all;
  _FactKindFilter _kindFilter = _FactKindFilter.all;
  _NoteStatusFilter _noteStatusFilter = _NoteStatusFilter.all;

  String get _searchText => _searchController.text.trim().toLowerCase();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsByPersonProvider(widget.personId));
    final notesAsync = ref.watch(
      researchNotesByPersonProvider(widget.personId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facts & Research'),
        actions: [
          IconButton(
            tooltip: 'Add Event',
            onPressed: () =>
                context.push('/people/${widget.personId}/facts/new'),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
          IconButton(
            tooltip: 'Add Note',
            onPressed: () =>
                context.push('/people/${widget.personId}/facts/new?kind=note'),
            icon: const Icon(Icons.note_add_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search events and notes',
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
          SegmentedButton<_FactsFilter>(
            segments: const [
              ButtonSegment(
                value: _FactsFilter.all,
                label: Text('All'),
                icon: Icon(Icons.view_agenda_outlined),
              ),
              ButtonSegment(
                value: _FactsFilter.dated,
                label: Text('Dated'),
                icon: Icon(Icons.event_available_outlined),
              ),
              ButtonSegment(
                value: _FactsFilter.undated,
                label: Text('Undated'),
                icon: Icon(Icons.event_busy_outlined),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (value) {
              setState(() {
                _filter = value.first;
              });
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<_FactKindFilter>(
            segments: const [
              ButtonSegment(
                value: _FactKindFilter.all,
                label: Text('All Types'),
                icon: Icon(Icons.view_agenda_outlined),
              ),
              ButtonSegment(
                value: _FactKindFilter.events,
                label: Text('Events'),
                icon: Icon(Icons.event_outlined),
              ),
              ButtonSegment(
                value: _FactKindFilter.notes,
                label: Text('Notes'),
                icon: Icon(Icons.sticky_note_2_outlined),
              ),
            ],
            selected: {_kindFilter},
            onSelectionChanged: (value) {
              setState(() {
                _kindFilter = value.first;
              });
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<_NoteStatusFilter>(
            segments: const [
              ButtonSegment(
                value: _NoteStatusFilter.all,
                label: Text('Any Status'),
                icon: Icon(Icons.rule_outlined),
              ),
              ButtonSegment(
                value: _NoteStatusFilter.open,
                label: Text('Open Notes'),
                icon: Icon(Icons.mark_unread_chat_alt_outlined),
              ),
              ButtonSegment(
                value: _NoteStatusFilter.resolved,
                label: Text('Resolved'),
                icon: Icon(Icons.task_alt_outlined),
              ),
            ],
            selected: {_noteStatusFilter},
            onSelectionChanged: (value) {
              setState(() {
                _noteStatusFilter = value.first;
              });
            },
          ),
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Events'),
          eventsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text('Failed to load events: $error'),
            data: (events) {
              final filtered = events.where((event) {
                final matchesSearch = _matchesSearch(
                  event.eventType,
                  event.dateDisplay,
                  event.place,
                  event.description,
                );
                final matchesFilter = _matchesFilter(event.dateSort != null);
                final matchesKind = _matchesKind(isEvent: true);
                return matchesSearch && matchesFilter && matchesKind;
              }).toList();

              return _EmptyOrList(
                emptyText: _searchText.isNotEmpty || _filter != _FactsFilter.all
                    ? 'No matching events found.'
                    : 'No events added yet.',
                emptyIcon: Icons.event_note_outlined,
                emptySubtitle:
                    _searchText.isNotEmpty || _filter != _FactsFilter.all
                    ? 'Try a different search or switch the date filter.'
                    : 'Add life events like birth, residence, occupation, or burial.',
                childCount: filtered.length,
                itemBuilder: (context, index) {
                  final event = filtered[index];
                  return _TimelineTile(
                    categoryLabel: 'Event',
                    leading: _factInitial(event.eventType),
                    title: event.eventType,
                    metadata: [
                      _dateBadgeText(event.dateSort != null),
                      if (event.dateDisplay != null) event.dateDisplay!,
                      if (event.place != null) event.place!,
                    ],
                    compactBody: event.description,
                    details: [
                      _detailRow('Place', event.place),
                      _detailRow('Description', event.description),
                    ],
                    onEdit: () {
                      context.push(
                        '/people/${widget.personId}/facts/edit/${event.id}',
                      );
                    },
                    onDelete: () => _confirmDeleteEvent(context, ref, event.id),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Research Notes'),
          notesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) =>
                Text('Failed to load research notes: $error'),
            data: (notes) {
              final filtered = notes.where((note) {
                final matchesSearch = _matchesSearch(
                  note.researchQuestion,
                  note.noteText,
                  note.noteDateDisplay,
                );
                final matchesFilter = _matchesFilter(note.noteDateSort != null);
                final matchesKind = _matchesKind(isEvent: false);
                final matchesResolved = _matchesNoteStatus(note.resolved);
                return matchesSearch &&
                    matchesFilter &&
                    matchesKind &&
                    matchesResolved;
              }).toList();

              return _EmptyOrList(
                emptyText: _searchText.isNotEmpty || _filter != _FactsFilter.all
                    ? 'No matching research notes found.'
                    : 'No research notes added yet.',
                emptyIcon: Icons.sticky_note_2_outlined,
                emptySubtitle:
                    _searchText.isNotEmpty || _filter != _FactsFilter.all
                    ? 'Try a different search or switch the date filter.'
                    : 'Capture questions, clues, and follow-up research tasks here.',
                childCount: filtered.length,
                itemBuilder: (context, index) {
                  final note = filtered[index];
                  return _TimelineTile(
                    categoryLabel: note.resolved ? 'Resolved' : 'Open',
                    leading: 'N',
                    title: note.researchQuestion ?? 'Research Note',
                    metadata: [
                      _dateBadgeText(note.noteDateSort != null),
                      note.resolved ? 'Resolved' : 'Open',
                      if (note.noteDateDisplay != null) note.noteDateDisplay!,
                      _noteDateText(note.createdAt),
                    ],
                    compactBody: note.noteText,
                    details: [
                      _detailRow('Question', note.researchQuestion),
                      _detailRow('Note Date', note.noteDateDisplay),
                      _detailRow('Status', note.resolved ? 'Resolved' : 'Open'),
                    ],
                    onEdit: () {
                      context.push(
                        '/people/${widget.personId}/facts/edit/${note.id}?kind=note',
                      );
                    },
                    onDelete: () =>
                        _confirmDeleteResearchNote(context, ref, note.id),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(String? a, [String? b, String? c, String? d]) {
    if (_searchText.isEmpty) return true;

    final joined = [a, b, c, d].whereType<String>().join(' ').toLowerCase();

    return joined.contains(_searchText);
  }

  bool _matchesFilter(bool hasDate) {
    switch (_filter) {
      case _FactsFilter.all:
        return true;
      case _FactsFilter.dated:
        return hasDate;
      case _FactsFilter.undated:
        return !hasDate;
    }
  }

  bool _matchesKind({required bool isEvent}) {
    switch (_kindFilter) {
      case _FactKindFilter.all:
        return true;
      case _FactKindFilter.events:
        return isEvent;
      case _FactKindFilter.notes:
        return !isEvent;
    }
  }

  bool _matchesNoteStatus(bool resolved) {
    switch (_noteStatusFilter) {
      case _NoteStatusFilter.all:
        return true;
      case _NoteStatusFilter.open:
        return !resolved;
      case _NoteStatusFilter.resolved:
        return resolved;
    }
  }

  Future<void> _confirmDeleteEvent(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event?'),
          content: const Text('This event will be permanently removed.'),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final repository = ref.read(eventsRepositoryProvider);
    await repository.deleteEvent(eventId);
  }

  Future<void> _confirmDeleteResearchNote(
    BuildContext context,
    WidgetRef ref,
    String noteId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Research Note?'),
          content: const Text(
            'This research note will be permanently removed.',
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final repository = ref.read(researchNotesRepositoryProvider);
    await repository.deleteResearchNote(noteId);
  }

  String _factInitial(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String _dateBadgeText(bool hasDate) {
    return hasDate ? 'Dated' : 'Undated';
  }

  String _noteDateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return 'Added $day-$month-$year';
  }

  String? _detailRow(String label, String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return '$label: $trimmed';
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.categoryLabel,
    required this.leading,
    required this.title,
    required this.metadata,
    required this.compactBody,
    required this.details,
    required this.onEdit,
    required this.onDelete,
  });

  final String categoryLabel;
  final String leading;
  final String title;
  final List<String> metadata;
  final String? compactBody;
  final List<String?> details;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final body = compactBody?.trim();

    return _ExpandableFactCard(
      title: title,
      categoryLabel: categoryLabel,
      leading: leading,
      metadata: metadata,
      body: body,
      details: details,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _ExpandableFactCard extends StatefulWidget {
  const _ExpandableFactCard({
    required this.categoryLabel,
    required this.leading,
    required this.title,
    required this.metadata,
    required this.body,
    required this.details,
    required this.onEdit,
    required this.onDelete,
  });

  final String categoryLabel;
  final String leading;
  final String title;
  final List<String> metadata;
  final String? body;
  final List<String?> details;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ExpandableFactCard> createState() => _ExpandableFactCardState();
}

class _ExpandableFactCardState extends State<_ExpandableFactCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 18, child: Text(widget.leading)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _CompactChip(
                              label: widget.categoryLabel,
                              emphasized: widget.categoryLabel == 'Resolved',
                              resolved: widget.categoryLabel == 'Resolved',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.metadata
                              .where((item) => item.trim().isNotEmpty)
                              .map((item) => _CompactChip(label: item))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit();
                      } else if (value == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              if (widget.body != null && widget.body!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.body!,
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ],
              if (_expanded) ...[
                const SizedBox(height: 10),
                ...widget.details.whereType<String>().map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tap to collapse',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  'Tap to expand',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({
    required this.label,
    this.emphasized = false,
    this.resolved,
  });

  final String label;
  final bool emphasized;
  final bool? resolved;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = resolved == null
        ? (emphasized ? colorScheme.primaryContainer : null)
        : resolved!
        ? colorScheme.secondaryContainer
        : colorScheme.errorContainer;
    final foregroundColor = resolved == null
        ? (emphasized ? colorScheme.onPrimaryContainer : null)
        : resolved!
        ? colorScheme.onSecondaryContainer
        : colorScheme.onErrorContainer;
    final borderColor = resolved == null
        ? (emphasized ? colorScheme.primary.withValues(alpha: 0.35) : null)
        : resolved!
        ? colorScheme.secondary.withValues(alpha: 0.35)
        : colorScheme.error.withValues(alpha: 0.35);

    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: foregroundColor != null
          ? TextStyle(color: foregroundColor, fontWeight: FontWeight.w700)
          : null,
      side: borderColor != null ? BorderSide(color: borderColor) : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyOrList extends StatelessWidget {
  const _EmptyOrList({
    required this.emptyText,
    required this.emptyIcon,
    required this.emptySubtitle,
    required this.childCount,
    required this.itemBuilder,
  });

  final String emptyText;
  final IconData emptyIcon;
  final String emptySubtitle;
  final int childCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (childCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                emptyIcon,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                emptyText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(emptySubtitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(
        childCount,
        (index) => itemBuilder(context, index),
      ),
    );
  }
}

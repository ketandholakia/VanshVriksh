import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../data/providers/events_repository_provider.dart';
import '../../data/providers/research_notes_repository_provider.dart';

enum FactKind { event, researchNote }

class PersonFactFormPage extends ConsumerStatefulWidget {
  const PersonFactFormPage({
    super.key,
    required this.personId,
    required this.kind,
    this.factId,
  });

  final String personId;
  final FactKind kind;
  final String? factId;

  @override
  ConsumerState<PersonFactFormPage> createState() => _PersonFactFormPageState();
}

class _PersonFactFormPageState extends ConsumerState<PersonFactFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _dateDisplayController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _questionController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSaving = false;
  bool _hasLoaded = false;
  Event? _editingEvent;
  ResearchNote? _editingNote;
  DateTime? _eventDate;
  DateTime? _noteDate;
  bool _noteResolved = false;

  bool get _isEdit => widget.factId != null;

  @override
  void dispose() {
    _typeController.dispose();
    _dateDisplayController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    _questionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (_hasLoaded || !_isEdit) return;

    if (widget.kind == FactKind.event) {
      final repository = ref.read(eventsRepositoryProvider);
      _editingEvent = await repository.getEventById(widget.factId!);
      final event = _editingEvent;
      if (event != null) {
        _typeController.text = event.eventType;
        _dateDisplayController.text = event.dateDisplay ?? '';
        _placeController.text = event.place ?? '';
        _descriptionController.text = event.description ?? '';
        _eventDate = _parseDisplayDate(event.dateDisplay);
      }
    } else {
      final repository = ref.read(researchNotesRepositoryProvider);
      _editingNote = await repository.getResearchNoteById(widget.factId!);
      final note = _editingNote;
      if (note != null) {
        _questionController.text = note.researchQuestion ?? '';
        _noteController.text = note.noteText;
        _noteDate = _parseDisplayDate(note.noteDateDisplay);
        _noteResolved = note.resolved;
      }
    }

    _hasLoaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.kind == FactKind.event) {
        final repository = ref.read(eventsRepositoryProvider);
        final type = _typeController.text.trim();
        final dateDisplay = _eventDate == null
            ? _emptyToNull(_dateDisplayController.text)
            : _formatDate(_eventDate!);
        if (_isEdit && _editingEvent != null) {
          await repository.updateEvent(
            id: _editingEvent!.id,
            personId: _editingEvent!.personId,
            eventType: type,
            eventDate: _eventDate,
            dateDisplay: dateDisplay,
            place: _emptyToNull(_placeController.text),
            description: _emptyToNull(_descriptionController.text),
            isPrimary: _editingEvent!.isPrimary,
            createdAt: _editingEvent!.createdAt,
          );
        } else {
          await repository.addEvent(
            personId: widget.personId,
            eventType: type,
            eventDate: _eventDate,
            dateDisplay: dateDisplay,
            place: _emptyToNull(_placeController.text),
            description: _emptyToNull(_descriptionController.text),
          );
        }
      } else {
        final repository = ref.read(researchNotesRepositoryProvider);
        final noteText = _noteController.text.trim();
        final noteDateDisplay = _noteDate == null
            ? null
            : _formatDate(_noteDate!);
        if (_isEdit && _editingNote != null) {
          await repository.updateResearchNote(
            id: _editingNote!.id,
            personId: _editingNote!.personId,
            noteText: noteText,
            researchQuestion: _emptyToNull(_questionController.text),
            noteDate: _noteDate,
            noteDateDisplay: noteDateDisplay,
            resolved: _noteResolved,
            createdAt: _editingNote!.createdAt,
          );
        } else {
          await repository.addResearchNote(
            personId: widget.personId,
            noteText: noteText,
            researchQuestion: _emptyToNull(_questionController.text),
            noteDate: _noteDate,
            noteDateDisplay: noteDateDisplay,
          );
        }
      }

      if (!mounted) return;
      context.go('/people/${widget.personId}/facts');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _parseDisplayDate(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value.trim());
    if (match == null) return null;

    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _eventDate = picked;
      _dateDisplayController.text = _formatDate(picked);
    });
  }

  Future<void> _pickNoteDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _noteDate ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _noteDate = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadExisting(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done && !_hasLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text(_isEdit ? 'Edit Fact' : 'Add Fact')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.kind == FactKind.event
                  ? (_isEdit ? 'Edit Event' : 'Add Event')
                  : (_isEdit ? 'Edit Research Note' : 'Add Research Note'),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.kind == FactKind.event) ...[
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Event Type *',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter event type'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickEventDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Event Date',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dateDisplayController.text.trim().isEmpty
                                  ? 'Select date'
                                  : _dateDisplayController.text.trim(),
                            ),
                          ),
                          TextButton(
                            onPressed: _eventDate == null
                                ? null
                                : () {
                                    setState(() {
                                      _eventDate = null;
                                      _dateDisplayController.clear();
                                    });
                                  },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _placeController,
                    decoration: const InputDecoration(
                      labelText: 'Place',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.event_note_outlined),
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: 'Research Question',
                      prefixIcon: Icon(Icons.help_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickNoteDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Note Date',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _noteDate == null
                                  ? 'Select date'
                                  : _formatDate(_noteDate!),
                            ),
                          ),
                          TextButton(
                            onPressed: _noteDate == null
                                ? null
                                : () {
                                    setState(() {
                                      _noteDate = null;
                                    });
                                  },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    minLines: 6,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Note Text *',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.sticky_note_2_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter note text'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.task_alt_outlined),
                    title: const Text('Resolved'),
                    subtitle: const Text(
                      'Mark this research note as completed.',
                    ),
                    value: _noteResolved,
                    onChanged: (value) {
                      setState(() {
                        _noteResolved = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => context.go('/people/${widget.personId}/facts'),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

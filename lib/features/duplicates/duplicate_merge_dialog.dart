import 'package:flutter/material.dart';

import 'duplicate_detection_providers.dart';
import 'person_name_formatter.dart';
import '../../core/extensions/genealogy_person_extensions.dart';

class DuplicateMergeSelection {
  const DuplicateMergeSelection({
    required this.keepPrimary,
    required this.preferredBirthDateSource,
    required this.preferredDeathDateSource,
    required this.preferredBirthPlaceSource,
    required this.preferredCurrentPlaceSource,
    required this.preferredBioSource,
    required this.preferredNotesSource,
  });

  final bool keepPrimary;
  final String preferredBirthDateSource;
  final String preferredDeathDateSource;
  final String preferredBirthPlaceSource;
  final String preferredCurrentPlaceSource;
  final String preferredBioSource;
  final String preferredNotesSource;
}

Future<DuplicateMergeSelection?> showDuplicateMergeDialog(
  BuildContext context, {
  required DuplicateCandidate candidate,
  required String title,
}) {
  var keepPrimary = true;
  var preferredBirthDateSource = 'primary';
  var preferredDeathDateSource = 'primary';
  var preferredBirthPlaceSource = 'primary';
  var preferredCurrentPlaceSource = 'primary';
  var preferredBioSource = 'primary';
  var preferredNotesSource = 'primary';

  return showDialog<DuplicateMergeSelection>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MergeSourceChoiceRow(
                    label: 'Keep record',
                    primaryLabel: displayPersonName(candidate.primary),
                    secondaryLabel: displayPersonName(candidate.duplicate),
                    value: keepPrimary ? 'primary' : 'secondary',
                    onChanged: (value) {
                      setState(() => keepPrimary = value == 'primary');
                    },
                  ),
                  const SizedBox(height: 12),
                  _MergeChoicePanel(
                    candidate: candidate,
                    keepPrimary: keepPrimary,
                    preferredBirthDateSource: preferredBirthDateSource,
                    preferredDeathDateSource: preferredDeathDateSource,
                    preferredBirthPlaceSource: preferredBirthPlaceSource,
                    preferredCurrentPlaceSource: preferredCurrentPlaceSource,
                    preferredBioSource: preferredBioSource,
                    preferredNotesSource: preferredNotesSource,
                    onKeepPrimaryChanged: (value) {
                      setState(() => keepPrimary = value);
                    },
                    onBirthDateSourceChanged: (value) {
                      setState(() => preferredBirthDateSource = value);
                    },
                    onDeathDateSourceChanged: (value) {
                      setState(() => preferredDeathDateSource = value);
                    },
                    onBirthPlaceSourceChanged: (value) {
                      setState(() => preferredBirthPlaceSource = value);
                    },
                    onCurrentPlaceSourceChanged: (value) {
                      setState(() => preferredCurrentPlaceSource = value);
                    },
                    onBioSourceChanged: (value) {
                      setState(() => preferredBioSource = value);
                    },
                    onNotesSourceChanged: (value) {
                      setState(() => preferredNotesSource = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    DuplicateMergeSelection(
                      keepPrimary: keepPrimary,
                      preferredBirthDateSource: preferredBirthDateSource,
                      preferredDeathDateSource: preferredDeathDateSource,
                      preferredBirthPlaceSource: preferredBirthPlaceSource,
                      preferredCurrentPlaceSource: preferredCurrentPlaceSource,
                      preferredBioSource: preferredBioSource,
                      preferredNotesSource: preferredNotesSource,
                    ),
                  );
                },
                child: const Text('Merge'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _MergeChoicePanel extends StatelessWidget {
  const _MergeChoicePanel({
    required this.candidate,
    required this.keepPrimary,
    required this.preferredBirthDateSource,
    required this.preferredDeathDateSource,
    required this.preferredBirthPlaceSource,
    required this.preferredCurrentPlaceSource,
    required this.preferredBioSource,
    required this.preferredNotesSource,
    required this.onKeepPrimaryChanged,
    required this.onBirthDateSourceChanged,
    required this.onDeathDateSourceChanged,
    required this.onBirthPlaceSourceChanged,
    required this.onCurrentPlaceSourceChanged,
    required this.onBioSourceChanged,
    required this.onNotesSourceChanged,
  });

  final DuplicateCandidate candidate;
  final bool keepPrimary;
  final String preferredBirthDateSource;
  final String preferredDeathDateSource;
  final String preferredBirthPlaceSource;
  final String preferredCurrentPlaceSource;
  final String preferredBioSource;
  final String preferredNotesSource;
  final ValueChanged<bool> onKeepPrimaryChanged;
  final ValueChanged<String> onBirthDateSourceChanged;
  final ValueChanged<String> onDeathDateSourceChanged;
  final ValueChanged<String> onBirthPlaceSourceChanged;
  final ValueChanged<String> onCurrentPlaceSourceChanged;
  final ValueChanged<String> onBioSourceChanged;
  final ValueChanged<String> onNotesSourceChanged;

  @override
  Widget build(BuildContext context) {
    final survivor = keepPrimary ? candidate.primary : candidate.duplicate;
    final source = keepPrimary ? candidate.duplicate : candidate.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Field preview',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _FieldPreviewRow(
              label: 'Name',
              survivor: survivor.fullName,
              source: source.fullName,
            ),
            _FieldPreviewRow(
              label: 'First name',
              survivor: survivor.firstName,
              source: source.firstName,
            ),
            _FieldPreviewRow(
              label: 'Middle name',
              survivor: survivor.middleName,
              source: source.middleName,
            ),
            _FieldPreviewRow(
              label: 'Last name',
              survivor: survivor.lastName,
              source: source.lastName,
            ),
            _FieldPreviewRow(
              label: 'Birth date',
              survivor: _fmtDate(survivor.birthDate),
              source: _fmtDate(source.birthDate),
            ),
            _FieldPreviewRow(
              label: 'Death date',
              survivor: _fmtDate(survivor.deathDate),
              source: _fmtDate(source.deathDate),
            ),
            _FieldPreviewRow(
              label: 'Birth place',
              survivor: survivor.birthPlace,
              source: source.birthPlace,
            ),
            _FieldPreviewRow(
              label: 'Current place',
              survivor: survivor.currentPlace,
              source: source.currentPlace,
            ),
            _FieldPreviewRow(
              label: 'Bio',
              survivor: survivor.biography,
              source: source.biography,
            ),
            _FieldPreviewRow(
              label: 'Notes',
              survivor: survivor.notes,
              source: source.notes,
            ),
            const Divider(height: 24),
            _SourceChoiceRow(
              label: 'Birth date',
              value: preferredBirthDateSource,
              onChanged: onBirthDateSourceChanged,
            ),
            _SourceChoiceRow(
              label: 'Death date',
              value: preferredDeathDateSource,
              onChanged: onDeathDateSourceChanged,
            ),
            _SourceChoiceRow(
              label: 'Birth place',
              value: preferredBirthPlaceSource,
              onChanged: onBirthPlaceSourceChanged,
            ),
            _SourceChoiceRow(
              label: 'Current place',
              value: preferredCurrentPlaceSource,
              onChanged: onCurrentPlaceSourceChanged,
            ),
            _SourceChoiceRow(
              label: 'Bio',
              value: preferredBioSource,
              onChanged: onBioSourceChanged,
            ),
            _SourceChoiceRow(
              label: 'Notes',
              value: preferredNotesSource,
              onChanged: onNotesSourceChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime? value) {
    if (value == null) return 'Not set';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day-$month-${value.year}';
  }
}

class _MergeSourceChoiceRow extends StatelessWidget {
  const _MergeSourceChoiceRow({
    required this.label,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String primaryLabel;
  final String secondaryLabel;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(primaryLabel),
              selected: value == 'primary',
              onSelected: (_) => onChanged('primary'),
            ),
            ChoiceChip(
              label: Text(secondaryLabel),
              selected: value == 'secondary',
              onSelected: (_) => onChanged('secondary'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceChoiceRow extends StatelessWidget {
  const _SourceChoiceRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Keep survivor'),
                  selected: value == 'primary',
                  onSelected: (_) => onChanged('primary'),
                ),
                ChoiceChip(
                  label: const Text('Use source'),
                  selected: value == 'secondary',
                  onSelected: (_) => onChanged('secondary'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldPreviewRow extends StatelessWidget {
  const _FieldPreviewRow({
    required this.label,
    required this.survivor,
    required this.source,
  });

  final String label;
  final String? survivor;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final survivorValue = _value(survivor);
    final sourceValue = _value(source);
    final keepSource = survivorValue == 'Not set' && sourceValue != 'Not set';
    final survivorChosen = keepSource ? sourceValue : survivorValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Survivor: $survivorValue',
                  style: TextStyle(
                    color: keepSource
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                Text(
                  'Source: $sourceValue',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Keeps: $survivorChosen',
                  style: TextStyle(
                    color: keepSource
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              keepSource ? 'from source' : 'keep survivor',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _value(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not set' : trimmed;
  }
}

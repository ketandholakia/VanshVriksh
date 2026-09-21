import 'package:flutter/material.dart';

import 'duplicate_detection_providers.dart';

class DuplicateScoringToggle extends StatefulWidget {
  const DuplicateScoringToggle({
    super.key,
    required this.title,
    required this.reason,
    required this.preview,
    this.score,
    this.matchDetails = const [],
  });

  final String title;
  final String reason;
  final DuplicateMergePreview preview;
  final int? score;
  final List<String> matchDetails;

  @override
  State<DuplicateScoringToggle> createState() => _DuplicateScoringToggleState();
}

class _DuplicateScoringToggleState extends State<DuplicateScoringToggle> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(_expanded ? 'Hide why flagged' : widget.title),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          DuplicateScoringExplanation(
            reason: widget.reason,
            preview: widget.preview,
            score: widget.score,
            matchDetails: widget.matchDetails,
          ),
        ],
      ],
    );
  }
}

class DuplicateScoringExplanation extends StatelessWidget {
  const DuplicateScoringExplanation({
    super.key,
    required this.reason,
    required this.preview,
    this.score,
    this.matchDetails = const [],
  });

  final String reason;
  final DuplicateMergePreview preview;
  final int? score;
  final List<String> matchDetails;

  @override
  Widget build(BuildContext context) {
    final totalMoves =
        preview.eventCount +
        preview.noteCount +
        preview.mediaCount +
        preview.relationshipCount;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (score != null)
          Chip(
            avatar: const Icon(Icons.rule_outlined, size: 18),
            label: Text('Score $score'),
          ),
        Chip(
          avatar: const Icon(Icons.swap_horiz_outlined, size: 18),
          label: Text('Moves $totalMoves'),
        ),
        Chip(
          avatar: const Icon(Icons.info_outline, size: 18),
          label: Text(reason),
        ),
        ...matchDetails.map(
          (detail) => Chip(
            avatar: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(detail),
          ),
        ),
      ],
    );
  }
}

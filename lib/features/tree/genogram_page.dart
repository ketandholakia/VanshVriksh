import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../settings/app_settings_provider.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/relationship_repository_provider.dart';
import 'ancestor_tree_layout.dart';
import 'chart_image_exporter.dart';
import 'chart_providers.dart';
import 'generation_tree_layout.dart';
import 'tree_models.dart';

/// A genogram-style view of the family over the hourglass arrangement:
/// squares for male, circles for female, a cross through the deceased,
/// double slashes on a divorced couple's union line, dashed connector lines
/// for adopted/foster/step parentage, and the standard relationship-dynamic
/// lines (close, distant, conflict, estranged) recorded as person bonds.
///
/// Medical context (hereditary conditions, causes of death) is written on
/// each person's form ("Medical Notes") and shown from a person's legend
/// sheet here.
class GenogramChartPage extends ConsumerStatefulWidget {
  const GenogramChartPage({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<GenogramChartPage> createState() => _GenogramChartPageState();
}

class _GenogramChartPageState extends ConsumerState<GenogramChartPage> {
  void Function(Canvas canvas, Size size)? _painter;
  Size _canvasSize = Size.zero;
  bool _exporting = false;

  Future<void> _exportPng() async {
    final painter = _painter;
    if (painter == null || _exporting || _canvasSize.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final file = await renderChartPng(
        canvasSize: _canvasSize,
        dateFormat: DateDisplayFormat.fullDate,
        fileNamePrefix: 'vanshvriksh_genogram',
        paint: painter,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Genogram image saved: ${file.path}')),
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Genogram - VanshVriksh'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export the genogram: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chart = ref.watch(genogramChartProvider(widget.personId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genogram'),
        actions: [
          IconButton(
            tooltip: 'Save as image',
            onPressed: _painter == null || _exporting ? null : _exportPng,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined),
          ),
          chart.maybeWhen(
            data: (data) => data == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Relationships & medical',
                    icon: const Icon(Icons.edit_note_outlined),
                    onPressed: () =>
                        showGenogramAnnotationsSheet(context, ref, data),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: chart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load genogram:\n$error'),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Person not found'));
          }

          final ancestorLayout = computeAncestorTreeLayout(
            focusId: data.ancestors.focusId,
            fatherOf: data.ancestors.fatherOf,
            motherOf: data.ancestors.motherOf,
            maxGenerations: 12,
            cardSize: const Size(120, 56),
            branchGap: 24,
            levelGap: 46,
          );
          final descendantLayout = computeGenerationTreeLayout(
            rootId: data.descendants.rootId,
            couples: [
              for (final couple in data.descendants.couples)
                TreeLayoutCouple(
                  familyId: couple.familyId,
                  partnerIds: couple.partnerIds,
                  childIds: couple.childIds,
                ),
            ],
            cardSize: const Size(120, 56),
            coupleGap: 20,
            siblingGap: 24,
            levelGap: 46,
          );
          final layout = mergeHourglassLayouts(
            ancestorLayout: ancestorLayout,
            descendantLayout: descendantLayout,
            focusId: data.focusId,
          );

          _painter = (canvas, size) {
            GenogramPainter(
              cardRects: layout.cardRects,
              people: data.people,
              focusId: data.focusId,
              couples: data.descendants.couples,
              familiesById: {
                for (final family in data.families) family.id: family,
              },
              childLinkTypes: data.childLinkTypes,
              bonds: data.bonds,
              fatherOf: data.ancestors.fatherOf,
              motherOf: data.ancestors.motherOf,
              lineColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.65),
              maleColor: Theme.of(context).colorScheme.primary,
              femaleColor: Theme.of(context).colorScheme.tertiary,
              textColor: Theme.of(context).colorScheme.onSurface,
              focusColor: Theme.of(context).colorScheme.primary,
              levelGap: 46,
            ).paint(canvas, size);
          };
          _canvasSize = layout.canvasSize;

          return Stack(
            children: [
              GenogramCanvas(
                layout: layout,
                people: data.people,
                focusId: data.focusId,
                fatherOf: data.ancestors.fatherOf,
                motherOf: data.ancestors.motherOf,
                couples: data.descendants.couples,
                families: data.families,
                childLinkTypes: data.childLinkTypes,
                bonds: data.bonds,
              ),
              const Positioned(left: 12, bottom: 12, child: _BondLegend()),
            ],
          );
        },
      ),
    );
  }
}

/// The legend for the relationship-dynamic lines.
class _BondLegend extends StatelessWidget {
  const _BondLegend();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final line = colorScheme.primary.withValues(alpha: 0.65);

    Widget sample(Widget line) => SizedBox(width: 34, height: 12, child: line);

    return Card(
      color: colorScheme.surface.withValues(alpha: 0.92),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendRow(
              sample(
                CustomPaint(
                  painter: _LegendLinePainter(kind: 'close', color: line),
                  size: const Size(34, 12),
                ),
              ),
              'Close',
            ),
            const SizedBox(height: 4),
            _legendRow(
              sample(
                CustomPaint(
                  painter: _LegendLinePainter(kind: 'conflict', color: line),
                  size: const Size(34, 12),
                ),
              ),
              'Conflict',
            ),
            const SizedBox(height: 4),
            _legendRow(
              sample(
                CustomPaint(
                  painter: _LegendLinePainter(kind: 'estranged', color: line),
                  size: const Size(34, 12),
                ),
              ),
              'Estranged',
            ),
            const SizedBox(height: 4),
            _legendRow(
              sample(
                CustomPaint(
                  painter: _LegendLinePainter(kind: 'distant', color: line),
                  size: const Size(34, 12),
                ),
              ),
              'Distant',
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Widget sample, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      sample,
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(0, size.height / 2);
    final end = Offset(size.width, size.height / 2);
    final painter = GenogramPainter(
      cardRects: const {},
      people: const {},
      focusId: '',
      couples: const [],
      familiesById: const {},
      childLinkTypes: const {},
      bonds: const [],
      fatherOf: const {},
      motherOf: const {},
      lineColor: color,
      maleColor: color,
      femaleColor: color,
      textColor: color,
      focusColor: color,
      levelGap: 46,
    );
    switch (kind) {
      case 'close':
        painter._line(canvas, start, end);
        painter._line(canvas, start.translate(0, 4), end.translate(0, 4));
        break;
      case 'conflict':
        final segments = 6;
        final step = size.width / segments;
        final points = <Offset>[start];
        for (var i = 1; i < segments; i++) {
          points.add(
            Offset(start.dx + step * i, start.dy + (i.isOdd ? -5.0 : 5.0)),
          );
        }
        points.add(end);
        painter._polyline(canvas, points);
        break;
      case 'distant':
        painter._dashedPolyline(canvas, [start, end], dash: 2, gap: 4);
        break;
      default:
        painter._dashedPolyline(canvas, [start, end]);
        final mid = Offset(size.width / 2, size.height / 2);
        painter._line(canvas, mid.translate(-4, -6), mid.translate(4, 6));
        break;
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

/// Adds, retypes and removes relationship bonds among the visible people, and
/// shows each person's medical notes.
Future<void> showGenogramAnnotationsSheet(
  BuildContext context,
  WidgetRef ref,
  GenogramChartData data,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => DriftSafeAnnotationsSheet(data: data),
  );
}

class DriftSafeAnnotationsSheet extends ConsumerStatefulWidget {
  const DriftSafeAnnotationsSheet({super.key, required this.data});

  final GenogramChartData data;

  @override
  ConsumerState<DriftSafeAnnotationsSheet> createState() =>
      _DriftSafeAnnotationsSheetState();
}

class _DriftSafeAnnotationsSheetState
    extends ConsumerState<DriftSafeAnnotationsSheet> {
  String? _personAId;
  String? _personBId;
  String _bondType = 'close';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final people = data.people.values.toList()
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Relationship dynamics',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'These lines are drawn on the genogram between the two '
                'people. Medical notes live on each person\'s form and show '
                'below.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ..._existingBonds(data),
              const Divider(height: 24),
              const Text('Add a bond'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _personAId,
                      decoration: const InputDecoration(labelText: 'Person'),
                      items: [
                        for (final person in people)
                          DropdownMenuItem(
                            value: person.id,
                            child: Text(
                              person.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _personAId = value),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—'),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _personBId,
                      decoration: const InputDecoration(labelText: 'Person'),
                      items: [
                        for (final person in people)
                          DropdownMenuItem(
                            value: person.id,
                            child: Text(
                              person.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _personBId = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'close', label: Text('Close')),
                  ButtonSegment(value: 'conflict', label: Text('Conflict')),
                  ButtonSegment(value: 'estranged', label: Text('Estranged')),
                  ButtonSegment(value: 'distant', label: Text('Distant')),
                ],
                selected: {_bondType},
                onSelectionChanged: (selection) =>
                    setState(() => _bondType = selection.first),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () => _saveBond(),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_link_outlined),
                label: const Text('Save bond'),
              ),
              const Divider(height: 24),
              const Text('Medical notes'),
              const SizedBox(height: 8),
              ..._medicalNotes(data),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _existingBonds(GenogramChartData data) {
    if (data.bonds.isEmpty) {
      return [
        Text(
          'No relationship dynamics recorded yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
    }
    String name(String id) => data.people[id]?.fullName ?? 'Unknown';

    return [
      for (final bond in data.bonds)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.link_outlined),
          title: Text('${name(bond.personAId)} — ${name(bond.personBId)}'),
          subtitle: Text(bond.bondType),
          trailing: IconButton(
            tooltip: 'Remove bond',
            icon: const Icon(Icons.link_off_outlined),
            onPressed: () async {
              await ref
                  .read(relationshipRepositoryProvider)
                  .removePersonBond(
                    personAId: bond.personAId,
                    personBId: bond.personBId,
                  );
              ref.invalidate(genogramChartProvider(data.focusId));
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
    ];
  }

  Future<void> _saveBond() async {
    final a = _personAId;
    final b = _personBId;
    if (a == null || b == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick both people.')));
      return;
    }
    if (a == b) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick two different people.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(relationshipRepositoryProvider)
          .addPersonBond(
            treeId: AppConstants.defaultTreeId,
            personAId: a,
            personBId: b,
            bondType: _bondType,
          );
      ref.invalidate(genogramChartProvider(widget.data.focusId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save the bond: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Widget> _medicalNotes(GenogramChartData data) {
    final entries = data.medicalNotes.entries.toList();
    if (entries.isEmpty) {
      return [
        Text(
          'No medical notes recorded. Add them on a person\'s edit form.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
    }
    return [
      for (final entry in entries)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.medical_services_outlined),
          title: Text(data.people[entry.key]?.fullName ?? 'Unknown'),
          subtitle: Text(entry.value),
        ),
    ];
  }
}

class GenogramCanvas extends StatelessWidget {
  const GenogramCanvas({
    super.key,
    required this.layout,
    required this.people,
    required this.focusId,
    required this.fatherOf,
    required this.motherOf,
    required this.couples,
    required this.families,
    required this.childLinkTypes,
    this.bonds = const [],
  });

  final GenerationTreeLayout layout;
  final Map<String, GenealogyPerson> people;
  final String focusId;
  final Map<String, String?> fatherOf;
  final Map<String, String?> motherOf;
  final List<TreeCouple> couples;
  final List<FamiliesV2Data> families;
  final Map<String, String> childLinkTypes;
  final List<PersonBond> bonds;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = colorScheme.primary.withValues(alpha: 0.65);
    final familiesById = {for (final family in families) family.id: family};

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1200),
      minScale: 0.05,
      maxScale: 2.5,
      child: SizedBox(
        width: layout.canvasSize.width,
        height: layout.canvasSize.height,
        child: CustomPaint(
          painter: GenogramPainter(
            cardRects: layout.cardRects,
            people: people,
            focusId: focusId,
            couples: couples,
            familiesById: familiesById,
            childLinkTypes: childLinkTypes,
            bonds: bonds,
            fatherOf: fatherOf,
            motherOf: motherOf,
            lineColor: lineColor,
            maleColor: colorScheme.primary,
            femaleColor: colorScheme.tertiary,
            textColor: colorScheme.onSurface,
            focusColor: colorScheme.primary,
            levelGap: 46,
          ),
          size: layout.canvasSize,
        ),
      ),
    );
  }
}

class GenogramPainter extends CustomPainter {
  const GenogramPainter({
    required this.cardRects,
    required this.people,
    required this.focusId,
    required this.couples,
    required this.familiesById,
    required this.childLinkTypes,
    this.bonds = const [],
    required this.fatherOf,
    required this.motherOf,
    required this.lineColor,
    required this.maleColor,
    required this.femaleColor,
    required this.textColor,
    required this.focusColor,
    required this.levelGap,
  });

  final Map<String, Rect> cardRects;
  final Map<String, GenealogyPerson> people;
  final String focusId;
  final List<TreeCouple> couples;
  final Map<String, FamiliesV2Data> familiesById;
  final Map<String, String> childLinkTypes;
  final List<PersonBond> bonds;
  final Map<String, String?> fatherOf;
  final Map<String, String?> motherOf;
  final Color lineColor;
  final Color maleColor;
  final Color femaleColor;
  final Color textColor;
  final Color focusColor;
  final double levelGap;

  bool _isMale(GenealogyPerson person) =>
      person.gender.trim().toLowerCase().startsWith('m');

  @override
  void paint(Canvas canvas, Size size) {
    _drawBondLines(canvas);
    _drawUnionLines(canvas);
    _drawAncestorChildLines(canvas);
    for (final entry in cardRects.entries) {
      final person = people[entry.key];
      if (person != null) {
        _drawPerson(canvas, person, entry.value, entry.key == focusId);
      }
    }
  }

  /// Relationship dynamics between visible pairs, drawn in the standard
  /// genogram patterns: close = two parallel lines, distant = dotted,
  /// conflict = zigzag, estranged = dashed with a perpendicular slash.
  void _drawBondLines(Canvas canvas) {
    for (final bond in bonds) {
      final a = cardRects[bond.personAId];
      final b = cardRects[bond.personBId];
      if (a == null || b == null) continue;
      final start = Offset(a.right, a.center.dy);
      final end = Offset(b.left, b.center.dy);
      if (end.dx <= start.dx) continue; // only horizontal pairs
      switch (bond.bondType) {
        case 'close':
          _line(canvas, start, end);
          _line(canvas, start.translate(0, 4), end.translate(0, 4));
          break;
        case 'distant':
          _dashedPolyline(canvas, [start, end], dash: 2, gap: 5);
          break;
        case 'conflict':
          final segments = 8;
          final step = (end.dx - start.dx) / segments;
          final points = <Offset>[start];
          for (var i = 1; i < segments; i++) {
            points.add(
              Offset(start.dx + step * i, start.dy + (i.isOdd ? -6.0 : 6.0)),
            );
          }
          points.add(end);
          _polyline(canvas, points);
          break;
        case 'estranged':
        default:
          _dashedPolyline(canvas, [start, end]);
          final mid = Offset((start.dx + end.dx) / 2, start.dy);
          _line(canvas, mid.translate(-5, -7), mid.translate(5, 7), width: 2.4);
          break;
      }
    }
  }

  /// Union lines between recorded partners, with the divorce slash, and the
  /// drop lines into their children.
  void _drawUnionLines(Canvas canvas) {
    for (final couple in couples) {
      final partnerRects = [
        for (final partnerId in couple.partnerIds)
          if (cardRects[partnerId] != null) cardRects[partnerId]!,
      ];
      if (partnerRects.isEmpty) continue;

      Offset anchor;
      if (partnerRects.length >= 2) {
        final left = partnerRects[0].left <= partnerRects[1].left
            ? partnerRects[0]
            : partnerRects[1];
        final right = partnerRects[0].left <= partnerRects[1].left
            ? partnerRects[1]
            : partnerRects[0];
        final y = left.center.dy;
        _line(canvas, Offset(left.right, y), Offset(right.left, y));
        anchor = Offset((left.right + right.left) / 2, y);

        final family = familiesById[couple.familyId];
        if (family?.divorceDate != null) {
          // The genogram divorce mark: two slashes across the union line.
          final midX = anchor.dx;
          for (final offset in const [-4.0, 4.0]) {
            _line(
              canvas,
              Offset(midX + offset, y - 7),
              Offset(midX + offset + 6, y + 7),
              width: 2.4,
            );
          }
        }
      } else {
        anchor = Offset(
          partnerRects.first.center.dx,
          partnerRects.first.bottom,
        );
      }

      for (final childId in couple.childIds) {
        _drawChildDrop(
          canvas,
          anchor,
          childId,
          dashed: _isDashed(couple.familyId, childId),
        );
      }
    }
  }

  /// Ancestor-side parentage: a union segment between both parents when the
  /// direct line records a pair, otherwise a single parent line.
  void _drawAncestorChildLines(Canvas canvas) {
    for (final entry in cardRects.entries) {
      final childId = entry.key;
      if (childId == focusId) continue;
      final fatherId = fatherOf[childId];
      final motherId = motherOf[childId];
      final fatherRect = fatherId == null ? null : cardRects[fatherId];
      final motherRect = motherId == null ? null : cardRects[motherId];
      if (fatherRect == null && motherRect == null) continue;
      // Descendant-side couples already drew their union lines.
      if (couples.any((couple) => couple.childIds.contains(childId))) continue;

      Offset anchor;
      if (fatherRect != null && motherRect != null) {
        final left = fatherRect.center.dx <= motherRect.center.dx
            ? fatherRect
            : motherRect;
        final right = identical(left, fatherRect) ? motherRect : fatherRect;
        final y = left.center.dy;
        _line(canvas, Offset(left.right, y), Offset(right.left, y));
        anchor = Offset((left.right + right.left) / 2, y);
      } else {
        final parentRect = fatherRect ?? motherRect!;
        anchor = Offset(parentRect.center.dx, parentRect.bottom);
      }
      _drawChildDrop(canvas, anchor, childId);
    }
  }

  bool _isDashed(String familyId, String childId) =>
      childLinkTypes['$familyId:$childId'] != null &&
      childLinkTypes['$familyId:$childId'] != 'biological';

  void _drawChildDrop(
    Canvas canvas,
    Offset anchor,
    String childId, {
    bool dashed = false,
  }) {
    final childRect = cardRects[childId];
    if (childRect == null) return;
    final busY = childRect.top - levelGap / 2;
    final points = [
      anchor,
      Offset(anchor.dx, busY),
      Offset(childRect.center.dx, busY),
      Offset(childRect.center.dx, childRect.top),
    ];
    if (dashed) {
      _dashedPolyline(canvas, points);
    } else {
      _polyline(canvas, points);
    }
  }

  void _drawPerson(
    Canvas canvas,
    GenealogyPerson person,
    Rect rect,
    bool isFocus,
  ) {
    final male = _isMale(person);
    final color = male ? maleColor : femaleColor;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isFocus ? 2.8 : 1.8;
    final fill = Paint()
      ..color = color.withValues(alpha: isFocus ? 0.28 : 0.14)
      ..style = PaintingStyle.fill;

    final shape = Rect.fromCenter(
      center: rect.center,
      width: math.min(rect.width, 44),
      height: math.min(rect.height, 44),
    );

    if (male) {
      canvas.drawRect(shape, fill);
      canvas.drawRect(shape, stroke);
    } else {
      canvas.drawCircle(shape.center, shape.width / 2, fill);
      canvas.drawCircle(shape.center, shape.width / 2, stroke);
    }

    // Genogram deceased mark: a cross through the shape.
    if (person.deathDate != null || !person.isLiving) {
      final cross = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(shape.topLeft, shape.bottomRight, cross);
      canvas.drawLine(shape.topRight, shape.bottomLeft, cross);
    }

    // Name under the shape.
    final nameSpan = TextPainter(
      text: TextSpan(
        text: person.fullName,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isFocus ? FontWeight.w900 : FontWeight.w600,
          color: textColor,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(rect.width, shape.width) + 24);
    nameSpan.paint(
      canvas,
      Offset(rect.center.dx - nameSpan.width / 2, shape.bottom + 4),
    );
  }

  void _polyline(Canvas canvas, List<Offset> points) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _dashedPolyline(
    Canvas canvas,
    List<Offset> points, {
    double dash = 6,
    double gap = 5,
  }) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final length = (end - start).distance;
      if (length == 0) continue;
      final direction = (end - start) / length;
      var distance = 0.0;
      while (distance < length) {
        final next = math.min(distance + dash, length);
        canvas.drawLine(
          start + direction * distance,
          start + direction * next,
          paint,
        );
        distance = next + gap;
      }
    }
  }

  void _line(Canvas canvas, Offset a, Offset b, {double width = 2}) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint);
  }

  @override
  bool shouldRepaint(GenogramPainter oldDelegate) =>
      oldDelegate.cardRects != cardRects ||
      oldDelegate.people != people ||
      oldDelegate.lineColor != lineColor;
}

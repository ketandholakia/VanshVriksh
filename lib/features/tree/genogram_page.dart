import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/genealogy_person_extensions.dart';
import '../../data/database/app_database.dart';
import 'ancestor_tree_layout.dart';
import 'chart_providers.dart';
import 'generation_tree_layout.dart';
import 'tree_models.dart';

/// A genogram-style view of the family over the hourglass arrangement:
/// squares for male, circles for female, a cross through the deceased,
/// double slashes on a divorced couple's union line, and dashed connector
/// lines for adopted/foster/step parentage.
///
/// It maps what the data model actually records — gender, life dates,
/// divorce, and the parentage type — and draws no medical or emotional
/// annotations, because the schema has no fields for them yet. It is the
/// honest v1: standard genogram *symbols* over the facts the app stores.
class GenogramChartPage extends ConsumerWidget {
  const GenogramChartPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chart = ref.watch(genogramChartProvider(personId));

    return Scaffold(
      appBar: AppBar(title: const Text('Genogram')),
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

          return GenogramCanvas(
            layout: layout,
            people: data.people,
            focusId: data.focusId,
            fatherOf: data.ancestors.fatherOf,
            motherOf: data.ancestors.motherOf,
            couples: data.descendants.couples,
            families: data.families,
            childLinkTypes: data.childLinkTypes,
          );
        },
      ),
    );
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
  });

  final GenerationTreeLayout layout;
  final Map<String, GenealogyPerson> people;
  final String focusId;
  final Map<String, String?> fatherOf;
  final Map<String, String?> motherOf;
  final List<TreeCouple> couples;
  final List<FamiliesV2Data> families;
  final Map<String, String> childLinkTypes;

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
    _drawUnionLines(canvas);
    _drawAncestorChildLines(canvas);
    for (final entry in cardRects.entries) {
      final person = people[entry.key];
      if (person != null) {
        _drawPerson(canvas, person, entry.value, entry.key == focusId);
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

  void _dashedPolyline(Canvas canvas, List<Offset> points) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 5.0;
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

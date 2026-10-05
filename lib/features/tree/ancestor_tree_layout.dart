import 'dart:math' as math;
import 'dart:ui';

import 'generation_tree_layout.dart';

/// Binary ancestor (pedigree) layout.
///
/// Places [focusId] at the bottom row and their direct ancestors above —
/// father left of mother, grandparents above them — one row per generation.
/// Direct line only: the maps name each person's father and mother, so
/// siblings never appear.
///
/// An ancestor reached through several lines (pedigree collapse) is placed
/// **once**; every line that reaches them draws its own connector into the
/// shared card instead of duplicating the person.
///
/// Output rows are numbered from the top (0 = oldest generation shown), the
/// same convention [computeGenerationTreeLayout] uses, so
/// [FamilyChartCanvas]-style canvases render it unchanged.
GenerationTreeLayout computeAncestorTreeLayout({
  required String focusId,
  required Map<String, String?> fatherOf,
  required Map<String, String?> motherOf,
  required int maxGenerations,
  required Size cardSize,
  double branchGap = 30,
  double levelGap = 56,
  double padding = 44,
}) {
  // ------------------------------------------------------------ generations
  final generation = <String, int>{focusId: 0};
  final queue = <String>[focusId];
  var maxGen = 0;
  while (queue.isNotEmpty) {
    final person = queue.removeAt(0);
    final gen = generation[person]!;
    if (gen >= maxGenerations) continue;
    for (final parent in [?fatherOf[person], ?motherOf[person]]) {
      if (!generation.containsKey(parent)) {
        generation[parent] = gen + 1;
        if (gen + 1 > maxGen) maxGen = gen + 1;
        queue.add(parent);
      }
    }
  }

  final byGeneration = <int, List<String>>{};
  for (final entry in generation.entries) {
    byGeneration.putIfAbsent(entry.value, () => []).add(entry.key);
  }

  // --------------------------------------------------------------- geometry
  // Rows are placed deepest first: the oldest generation packs left to right,
  // everyone above centres on their parents, and a sweep guarantees no two
  // cards in a row overlap (two full siblings who are both direct ancestors
  // would otherwise land on the same midpoint).
  final centerX = <String, double>{};
  final cardWidth = cardSize.width;
  final cardHeight = cardSize.height;
  final rowStride = cardHeight + levelGap;

  for (final gen in (byGeneration.keys.toList()..sort()).reversed) {
    final row = byGeneration[gen]!..sort();
    var cursor = 0.0;
    for (final person in row) {
      final father = fatherOf[person];
      final mother = motherOf[person];
      final placedParents = [
        if (father != null && centerX.containsKey(father)) centerX[father]!,
        if (mother != null && centerX.containsKey(mother)) centerX[mother]!,
      ];
      final desired = placedParents.isEmpty
          ? null
          : placedParents.reduce((a, b) => a + b) / placedParents.length;

      final x = desired == null ? cursor : math.max(desired, cursor);
      centerX[person] = x;
      cursor = x + cardWidth + branchGap;
    }
  }

  final cardRects = <String, Rect>{
    for (final entry in generation.entries)
      entry.key: Rect.fromLTWH(
        centerX[entry.key]! - cardWidth / 2,
        (maxGen - entry.value) * rowStride,
        cardWidth,
        cardHeight,
      ),
  };

  // ------------------------------------------------------------- connectors
  // One connector per parent→child line, child top to parent bottom, routed
  // through the bus between the rows.
  final connectors = <TreeLayoutPath>[];
  for (final entry in generation.entries) {
    final child = entry.key;
    final childRect = cardRects[child]!;
    for (final parent in [?fatherOf[child], ?motherOf[child]]) {
      final parentRect = cardRects[parent];
      if (parentRect == null) continue;
      final busY = childRect.top - levelGap / 2;
      connectors.add([
        Offset(parentRect.center.dx, parentRect.bottom),
        Offset(parentRect.center.dx, busY),
        Offset(childRect.center.dx, busY),
        Offset(childRect.center.dx, childRect.top),
      ]);
    }
  }

  return _normalized(cardRects, connectors, {
    for (final entry in generation.entries) entry.key: maxGen - entry.value,
  }, padding);
}

/// Stacks an ancestor layout (focus on its bottom row) on top of a descendant
/// layout (focus on its top row) so the two focus cards coincide — the
/// hourglass: direct ancestors stretching up, descendants branching down.
GenerationTreeLayout mergeHourglassLayouts({
  required GenerationTreeLayout ancestorLayout,
  required GenerationTreeLayout descendantLayout,
  required String focusId,
  double padding = 44,
}) {
  final descendantFocus = descendantLayout.cardRects[focusId];
  final ancestorFocus = ancestorLayout.cardRects[focusId];
  if (descendantFocus == null || ancestorFocus == null) {
    return descendantLayout;
  }

  final shift = Offset(
    descendantFocus.center.dx - ancestorFocus.center.dx,
    descendantFocus.center.dy - ancestorFocus.center.dy,
  );

  // The descendant layout keeps the focus card; the ancestor layout's copy
  // would sit exactly on top of it.
  final ancestorRects = <String, Rect>{
    for (final entry in ancestorLayout.cardRects.entries)
      if (entry.key != focusId) entry.key: entry.value.shift(shift),
  };

  final ancestorMaxRow = ancestorLayout.generations.values.isEmpty
      ? 0
      : ancestorLayout.generations.values.reduce(math.max);
  final generations = <String, int>{
    // Ancestor rows go negative so the two blocks never share a row number.
    for (final entry in ancestorLayout.generations.entries)
      if (entry.key != focusId) entry.key: entry.value - ancestorMaxRow - 1,
    ...descendantLayout.generations,
    focusId: 0,
  };

  return _normalized(
    {...ancestorRects, ...descendantLayout.cardRects},
    [
      for (final path in ancestorLayout.connectors)
        [for (final point in path) point + shift],
      ...descendantLayout.connectors,
    ],
    generations,
    padding,
  );
}

/// Two mirrored ancestor trees flanking the focus person — the bow-tie: the
/// father's line opens to the left, the mother's line to the right.
GenerationTreeLayout mergeBowTieLayouts({
  required String focusId,
  required GenerationTreeLayout fatherLayout,
  required GenerationTreeLayout motherLayout,
  required String? fatherId,
  required String? motherId,
  double centerGap = 40,
  double padding = 44,
}) {
  final rects = <String, Rect>{};
  final connectors = <TreeLayoutPath>[];
  final generations = <String, int>{focusId: 0};

  // Focus at the origin row; parents flank it at the same height.
  final focusSize =
      _firstCardSize(fatherLayout) ??
      _firstCardSize(motherLayout) ??
      const Size(156, 72);
  final focus = Rect.fromLTWH(
    -focusSize.width / 2,
    -focusSize.height / 2,
    focusSize.width,
    focusSize.height,
  );
  rects[focusId] = focus;

  void attachSide({
    required GenerationTreeLayout layout,
    required String? anchorId,
    required bool isLeft,
  }) {
    if (anchorId == null) return;
    final anchor = layout.cardRects[anchorId];
    if (anchor == null) return;

    GenerationTreeLayout part = layout;
    if (!isLeft) part = _mirrored(part);

    final partAnchor = part.cardRects[anchorId]!;
    final sideOffset = isLeft
        ? focus.left - centerGap - partAnchor.right
        : focus.right + centerGap - partAnchor.left;
    final dy = focus.center.dy - partAnchor.center.dy;
    final shift = Offset(sideOffset, dy);

    rects.addAll({
      for (final entry in part.cardRects.entries)
        if (entry.key != focusId) entry.key: entry.value.shift(shift),
    });
    for (final path in part.connectors) {
      connectors.add([for (final point in path) point + shift]);
    }

    final maxRow = part.generations.values.isEmpty
        ? 0
        : part.generations.values.reduce(math.max);
    for (final entry in part.generations.entries) {
      if (entry.key == focusId) continue;
      // Both bottom rows align with the focus row: rebase so ancestors go
      // negative and the focus row stays 0.
      generations[entry.key] = entry.value - maxRow;
    }

    // The horizontal tie into the focus person.
    connectors.add([
      isLeft
          ? Offset(partAnchor.right + shift.dx, partAnchor.center.dy + dy)
          : Offset(partAnchor.left + shift.dx, partAnchor.center.dy + dy),
      isLeft
          ? Offset(focus.left, focus.center.dy)
          : Offset(focus.right, focus.center.dy),
    ]);
  }

  attachSide(layout: fatherLayout, anchorId: fatherId, isLeft: true);
  attachSide(layout: motherLayout, anchorId: motherId, isLeft: false);

  return _normalized(rects, connectors, generations, padding);
}

/// Mirrors a layout horizontally within its own bounds.
GenerationTreeLayout _mirrored(GenerationTreeLayout layout) {
  var left = double.infinity;
  var right = double.negativeInfinity;
  for (final rect in layout.cardRects.values) {
    left = math.min(left, rect.left);
    right = math.max(right, rect.right);
  }
  if (left.isInfinite) return layout;
  final span = right + left; // x' = span - x

  return GenerationTreeLayout(
    cardRects: {
      for (final entry in layout.cardRects.entries)
        entry.key: Rect.fromLTWH(
          span - entry.value.right,
          entry.value.top,
          entry.value.width,
          entry.value.height,
        ),
    },
    generations: layout.generations,
    connectors: [
      for (final path in layout.connectors)
        [for (final point in path) Offset(span - point.dx, point.dy)],
    ],
    canvasSize: layout.canvasSize,
  );
}

Size? _firstCardSize(GenerationTreeLayout layout) {
  for (final rect in layout.cardRects.values) {
    return rect.size;
  }
  return null;
}

/// Shifts [cardRects] and [connectors] so everything starts at [padding] and
/// wraps them in a [GenerationTreeLayout].
GenerationTreeLayout _normalized(
  Map<String, Rect> cardRects,
  List<TreeLayoutPath> connectors,
  Map<String, int> generations,
  double padding,
) {
  if (cardRects.isEmpty) {
    return GenerationTreeLayout(
      cardRects: const {},
      generations: const {},
      connectors: const [],
      canvasSize: Size.zero,
    );
  }

  var minLeft = double.infinity;
  var minTop = double.infinity;
  var maxRight = double.negativeInfinity;
  var maxBottom = double.negativeInfinity;
  for (final rect in cardRects.values) {
    minLeft = math.min(minLeft, rect.left);
    minTop = math.min(minTop, rect.top);
    maxRight = math.max(maxRight, rect.right);
    maxBottom = math.max(maxBottom, rect.bottom);
  }
  final shift = Offset(padding - minLeft, padding - minTop);

  return GenerationTreeLayout(
    cardRects: {
      for (final entry in cardRects.entries)
        entry.key: entry.value.shift(shift),
    },
    generations: generations,
    connectors: [
      for (final path in connectors) [for (final point in path) point + shift],
    ],
    canvasSize: Size(
      maxRight - minLeft + padding * 2,
      maxBottom - minTop + padding * 2,
    ),
  );
}

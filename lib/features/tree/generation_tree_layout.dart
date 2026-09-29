import 'dart:math' as math;
import 'dart:ui';

/// A union handed to [computeGenerationTreeLayout]: the partners of one couple
/// and the children of that union.
class TreeLayoutCouple {
  const TreeLayoutCouple({
    required this.familyId,
    required this.partnerIds,
    required this.childIds,
  });

  final String familyId;
  final List<String> partnerIds;
  final List<String> childIds;
}

/// A straight polyline the canvas should stroke, in canvas coordinates.
typedef TreeLayoutPath = List<Offset>;

/// A computed tree layout: where each person's card goes and which lines to
/// draw between them.
class GenerationTreeLayout {
  const GenerationTreeLayout({
    required this.cardRects,
    required this.generations,
    required this.connectors,
    required this.canvasSize,
  });

  final Map<String, Rect> cardRects;

  /// Generation index per person, 0-based, relative to the topmost row.
  final Map<String, int> generations;

  final List<TreeLayoutPath> connectors;
  final Size canvasSize;
}

/// Lays a family tree out on generation rows.
///
/// Layered-DAG algorithms (Sugiyama and friends) cannot express this shape: to
/// them a spouse is just another directed edge, so a couple ends up on two
/// different rows, and anyone whose parents are not in the visible set is
/// pinned to the top and floats away from their own children. Here the rows
/// come from the family structure instead - parents one row above their
/// children, partners sharing a row - and each union's children are packed and
/// centred underneath the couple. That is what makes a genealogy chart readable.
GenerationTreeLayout computeGenerationTreeLayout({
  required String rootId,
  required List<TreeLayoutCouple> couples,
  required Size cardSize,
  double coupleGap = 26,
  double siblingGap = 30,
  double levelGap = 56,
  double padding = 44,
}) {
  final cardWidth = cardSize.width;
  final cardHeight = cardSize.height;

  // ---------------------------------------------------------------- persons
  final personIds = <String>{rootId};
  final coupleIndicesOfPerson = <String, List<int>>{};
  for (var i = 0; i < couples.length; i++) {
    final couple = couples[i];
    personIds
      ..addAll(couple.partnerIds)
      ..addAll(couple.childIds);
    for (final partner in couple.partnerIds) {
      coupleIndicesOfPerson.putIfAbsent(partner, () => <int>[]).add(i);
    }
  }

  // ------------------------------------------------------------ generations
  // BFS from the root: a partner shares the row, a child drops one row, a
  // parent rises one row. Both directions are walked - descending only via
  // partner links would never place the ancestors. The queue is re-entered
  // whenever a generation is corrected so the whole tree stays consistent.
  final coupleIndicesAsChild = <String, List<int>>{};
  for (var i = 0; i < couples.length; i++) {
    for (final child in couples[i].childIds) {
      coupleIndicesAsChild.putIfAbsent(child, () => <int>[]).add(i);
    }
  }

  final generation = <String, int>{rootId: 0};
  final pending = <String>[rootId];
  var guard = 0;
  while (pending.isNotEmpty && guard++ < 200000) {
    final person = pending.removeAt(0);
    final current = generation[person]!;

    // This person as a partner or parent.
    for (final coupleIndex in coupleIndicesOfPerson[person] ?? const <int>[]) {
      final couple = couples[coupleIndex];
      for (final partner in couple.partnerIds) {
        if (partner == person) continue;
        final existing = generation[partner];
        if (existing == null) {
          generation[partner] = current;
          pending.add(partner);
        } else if (current > existing) {
          generation[partner] = current;
          pending.add(partner);
        }
      }
      for (final child in couple.childIds) {
        final wanted = current + 1;
        final existing = generation[child];
        if (existing == null || existing < wanted) {
          generation[child] = wanted;
          pending.add(child);
        }
      }
    }

    // This person as a child of a couple.
    for (final coupleIndex in coupleIndicesAsChild[person] ?? const <int>[]) {
      final couple = couples[coupleIndex];
      final parentGeneration = current - 1;
      for (final partner in couple.partnerIds) {
        final existing = generation[partner];
        if (existing == null) {
          generation[partner] = parentGeneration;
          pending.add(partner);
        } else if (existing > parentGeneration) {
          generation[partner] = parentGeneration;
          pending.add(partner);
        }
      }
      for (final sibling in couple.childIds) {
        if (sibling == person) continue;
        final existing = generation[sibling];
        if (existing == null) {
          generation[sibling] = current;
          pending.add(sibling);
        } else if (existing < current) {
          generation[sibling] = current;
          pending.add(sibling);
        }
      }
    }
  }
  for (final person in personIds) {
    generation.putIfAbsent(person, () => 0);
  }

  // --------------------------------------------------------------- grouping
  // A group is one visual unit: a couple sitting side by side, or one person.
  // Every person ends up in exactly one group.
  final groups = <_Group>[];
  final groupIdOfPerson = <String, String>{};

  void addGroup(String id, List<String> members) {
    final group = _Group(id, members);
    groups.add(group);
    for (final person in members) {
      groupIdOfPerson[person] = id;
    }
  }

  for (final couple in couples) {
    if (couple.partnerIds.length < 2) continue;
    if (couple.partnerIds.any(groupIdOfPerson.containsKey)) continue;
    addGroup('family:${couple.familyId}', List<String>.of(couple.partnerIds));
  }
  for (final person in personIds) {
    if (groupIdOfPerson.containsKey(person)) continue;
    addGroup('person:$person', [person]);
  }

  final groupById = {for (final group in groups) group.id: group};
  for (final group in groups) {
    group.generation = generation[group.personIds.first]!;
    group.width =
        group.personIds.length * cardWidth +
        (group.personIds.length - 1) * coupleGap;

    final coupleIndices = <int>{};
    for (final person in group.personIds) {
      coupleIndices.addAll(coupleIndicesOfPerson[person] ?? const <int>[]);
    }
    group.coupleIndices = coupleIndices.toList()..sort();

    final seen = <String>{};
    for (final coupleIndex in group.coupleIndices) {
      for (final child in couples[coupleIndex].childIds) {
        final childGroupId = groupIdOfPerson[child];
        if (childGroupId == null || childGroupId == group.id) continue;
        if (!seen.add(childGroupId)) continue;
        group.children.add(groupById[childGroupId]!);
      }
    }
  }

  // --------------------------------------------------------------- geometry
  final byGeneration = <int, List<_Group>>{};
  for (final group in groups) {
    byGeneration.putIfAbsent(group.generation, () => <_Group>[]).add(group);
  }
  final generations = byGeneration.keys.toList()..sort();
  if (generations.isEmpty) {
    return const GenerationTreeLayout(
      cardRects: <String, Rect>{},
      generations: <String, int>{},
      connectors: <TreeLayoutPath>[],
      canvasSize: Size.zero,
    );
  }
  final topGeneration = generations.first;

  // Bottom-up: how much horizontal room does each subtree need?
  final subtreeWidth = <String, double>{};
  for (final generation in generations.reversed) {
    for (final group in byGeneration[generation]!) {
      var childrenWidth = 0.0;
      for (var i = 0; i < group.children.length; i++) {
        if (i > 0) childrenWidth += siblingGap;
        childrenWidth += subtreeWidth[group.children[i].id]!;
      }
      subtreeWidth[group.id] = math.max(group.width, childrenWidth);
    }
  }

  final cardRects = <String, Rect>{};
  final placed = <String>{};

  void placeGroup(_Group group, double left) {
    if (!placed.add(group.id)) return;

    final top =
        (group.generation - topGeneration) * (cardHeight + levelGap);
    var x = left;
    for (final person in group.personIds) {
      cardRects[person] = Rect.fromLTWH(x, top, cardWidth, cardHeight);
      x += cardWidth + coupleGap;
    }

    if (group.children.isEmpty) return;
    var childrenWidth = 0.0;
    for (var i = 0; i < group.children.length; i++) {
      if (i > 0) childrenWidth += siblingGap;
      childrenWidth += subtreeWidth[group.children[i].id]!;
    }

    // Centre each union's children underneath the union itself.
    var childLeft = left + (group.width - childrenWidth) / 2;
    for (final child in group.children) {
      placeGroup(child, childLeft);
      childLeft += subtreeWidth[child.id]! + siblingGap;
    }
  }

  final hasParent = <String>{};
  for (final group in groups) {
    for (final child in group.children) {
      hasParent.add(child.id);
    }
  }
  final roots = [
    for (final group in groups)
      if (!hasParent.contains(group.id)) group,
  ]..sort((a, b) => a.generation.compareTo(b.generation));

  var cursor = 0.0;
  for (final root in roots) {
    placeGroup(root, cursor);
    cursor += subtreeWidth[root.id]! + siblingGap * 3;
  }

  // Normalise into the canvas, leaving [padding] on every side.
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
  final normalised = <String, Rect>{
    for (final entry in cardRects.entries) entry.key: entry.value.shift(shift),
  };

  // ------------------------------------------------------------- connectors
  final connectors = <TreeLayoutPath>[];
  for (final couple in couples) {
    final partnerRects = [
      for (final partner in couple.partnerIds)
        if (normalised[partner] != null) normalised[partner]!,
    ];
    if (partnerRects.isEmpty) continue;

    // Joining bar between the two partners of a couple.
    if (partnerRects.length >= 2) {
      final first = partnerRects[0];
      final second = partnerRects[1];
      final left = first.left <= second.left ? first : second;
      final right = first.left <= second.left ? second : first;
      connectors.add([
        Offset(left.right, left.center.dy),
        Offset(right.left, right.center.dy),
      ]);
    }

    final childRects = [
      for (final child in couple.childIds)
        if (normalised[child] != null) normalised[child]!,
    ];
    if (childRects.isEmpty) continue;

    final anchorX = partnerRects.length >= 2
        ? (partnerRects[0].center.dx + partnerRects[1].center.dx) / 2
        : partnerRects.first.center.dx;
    final startY = partnerRects.length >= 2
        ? partnerRects[0].center.dy
        : partnerRects.first.bottom;
    final childTop = childRects.map((rect) => rect.top).reduce(math.min);
    final busY = childTop - levelGap / 2;

    for (final childRect in childRects) {
      connectors.add([
        Offset(anchorX, startY),
        Offset(anchorX, busY),
        Offset(childRect.center.dx, busY),
        Offset(childRect.center.dx, childRect.top),
      ]);
    }
  }

  return GenerationTreeLayout(
    cardRects: normalised,
    generations: {
      for (final entry in generation.entries) entry.key: entry.value,
    },
    connectors: connectors,
    canvasSize: Size(
      maxRight - minLeft + padding * 2,
      maxBottom - minTop + padding * 2,
    ),
  );
}

class _Group {
  _Group(this.id, this.personIds);

  final String id;
  final List<String> personIds;
  final List<_Group> children = [];
  late int generation;
  late double width;
  late List<int> coupleIndices;
}

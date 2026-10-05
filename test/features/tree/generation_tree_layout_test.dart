// The generation-row layout engine, exercised as pure geometry.
//
// The invariants the canvas depends on:
//   * partners share a row; children sit exactly one row below their parents;
//   * no two person cards overlap anywhere on the canvas;
//   * every card lies inside the reported canvas bounds;
//   * each union's children hang centred underneath it;
//   * the layout is deterministic and handles single-parent unions,
//     remarriage, and several disconnected families.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/features/tree/generation_tree_layout.dart';

void main() {
  const cardSize = Size(120, 60);

  TreeLayoutCouple couple(
    String id,
    List<String> partners, [
    List<String> children = const [],
  ]) {
    return TreeLayoutCouple(
      familyId: id,
      partnerIds: partners,
      childIds: children,
    );
  }

  group('single couple with children', () {
    final layout = computeGenerationTreeLayout(
      rootId: 'p1',
      couples: [
        couple('f1', ['p1', 'p2'], ['c1', 'c2', 'c3']),
      ],
      cardSize: cardSize,
    );

    test('partners share a row, children are exactly one row below', () {
      expect(layout.generations['p1'], layout.generations['p2']);
      expect(layout.generations['c1'], layout.generations['p1']! + 1);
      expect(layout.generations['c2'], layout.generations['p1']! + 1);
      expect(layout.generations['c3'], layout.generations['p1']! + 1);
    });

    test('no two cards overlap', () {
      _assertNoOverlap(layout.cardRects);
    });

    test('children are centred underneath the couple', () {
      final left = layout.cardRects['p1']!;
      final right = layout.cardRects['p2']!;
      final coupleCenterX = (left.center.dx + right.center.dx) / 2;
      final childRects = layout.cardRects.values
          .where((rect) => rect.top > left.top)
          .toList();
      final childrenMeanX =
          childRects.map((rect) => rect.center.dx).reduce((a, b) => a + b) /
          childRects.length;
      expect(childrenMeanX, closeTo(coupleCenterX, 0.5));
    });

    test('a connector joins the two partners', () {
      final partnerBar = layout.connectors.firstWhere(
        (path) => path.length == 2,
      );
      expect(partnerBar[0].dy, partnerBar[1].dy);
    });

    test('every connector for the children routes through the bus row', () {
      final childConnectors = layout.connectors.where(
        (path) =>
            path.length == 4 &&
            path.first.dy != path.last.dy &&
            path.first.dy < path.last.dy,
      );
      expect(childConnectors, isNotEmpty);
      for (final path in childConnectors) {
        // Down from the couple, across the bus, down into the child.
        expect(path[0].dx, path[1].dx);
        expect(path[1].dy, path[2].dy);
        expect(path[2].dx, path[3].dx);
      }
    });

    test('the canvas encloses every card plus padding', () {
      _assertCanvasEncloses(layout);
    });
  });

  group('single-parent union', () {
    final layout = computeGenerationTreeLayout(
      rootId: 'solo',
      couples: [
        couple('f1', ['solo'], ['kid1', 'kid2']),
      ],
      cardSize: cardSize,
    );

    test('places the parent above the children without overlaps', () {
      expect(layout.generations['solo'], 0);
      expect(layout.generations['kid1'], 1);
      _assertNoOverlap(layout.cardRects);
      _assertCanvasEncloses(layout);
    });

    test('routes the child connector from the parent card', () {
      final parentRect = layout.cardRects['solo']!;
      final down = layout.connectors.firstWhere((path) => path.length == 4);
      expect(down.first.dx, closeTo(parentRect.center.dx, 0.5));
    });
  });

  group('remarriage', () {
    // p1 has children with p2 and later with p3.
    final layout = computeGenerationTreeLayout(
      rootId: 'p1',
      couples: [
        couple('f1', ['p1', 'p2'], ['k1', 'k2']),
        couple('f2', ['p1', 'p3'], ['k3']),
      ],
      cardSize: cardSize,
    );

    test('places everyone without overlaps', () {
      _assertNoOverlap(layout.cardRects);
      _assertCanvasEncloses(layout);
    });

    test('all children are one row below p1', () {
      for (final child in ['k1', 'k2', 'k3']) {
        expect(layout.generations[child], layout.generations['p1']! + 1);
      }
    });
  });

  group('several disconnected families', () {
    final layout = computeGenerationTreeLayout(
      rootId: 'a1',
      couples: [
        couple('fa', ['a1', 'a2'], ['a3']),
        couple('fb', ['b1', 'b2'], ['b3']),
      ],
      cardSize: cardSize,
    );

    test('lays both families out side by side without overlaps', () {
      expect(layout.cardRects.keys, containsAll(['b1', 'b2', 'b3']));
      _assertNoOverlap(layout.cardRects);
      _assertCanvasEncloses(layout);
    });
  });

  group('ancestors of the root', () {
    // The root's parents and grandparents must rise above it, not float.
    final layout = computeGenerationTreeLayout(
      rootId: 'root',
      couples: [
        couple('f0', ['gp1', 'gp2'], ['p1', 'p2']),
        couple('f1', ['p1', 'p2'], ['root', 'sib']),
        couple('f2', ['root', 'spouse'], ['kid']),
      ],
      cardSize: cardSize,
    );

    test('keeps every generation in order without overlaps', () {
      expect(layout.generations['gp1']!, lessThan(layout.generations['p1']!));
      expect(layout.generations['p1']!, lessThan(layout.generations['root']!));
      expect(layout.generations['kid'], layout.generations['root']! + 1);
      _assertNoOverlap(layout.cardRects);
      _assertCanvasEncloses(layout);
    });
  });

  test('the layout is deterministic', () {
    final couples = [
      couple('f1', ['p1', 'p2'], ['c1', 'c2']),
      couple('f2', ['p1', 'p3'], ['c3']),
      couple('f0', ['g1', 'g2'], ['p1']),
    ];
    final first = computeGenerationTreeLayout(
      rootId: 'p1',
      couples: couples,
      cardSize: cardSize,
    );
    final second = computeGenerationTreeLayout(
      rootId: 'p1',
      couples: couples,
      cardSize: cardSize,
    );

    expect(first.cardRects.keys.toSet(), second.cardRects.keys.toSet());
    for (final entry in first.cardRects.entries) {
      expect(
        entry.value,
        second.cardRects[entry.key],
        reason: 'card ${entry.key} moved between runs',
      );
    }
    expect(first.canvasSize, second.canvasSize);
  });

  test('a person with no unions still gets placed', () {
    final layout = computeGenerationTreeLayout(
      rootId: 'nobody',
      couples: const [],
      cardSize: cardSize,
    );
    expect(layout.cardRects.keys, ['nobody']);
    expect(layout.connectors, isEmpty);
    expect(layout.canvasSize.width, closeTo(cardSize.width + 44 * 2, 0.5));
    expect(layout.canvasSize.height, closeTo(cardSize.height + 44 * 2, 0.5));
  });
}

void _assertNoOverlap(Map<String, Rect> rects) {
  final entries = rects.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      final a = entries[i].value;
      final b = entries[j].value;
      final overlaps =
          a.left < b.right &&
          b.left < a.right &&
          a.top < b.bottom &&
          b.top < a.bottom;
      expect(
        overlaps,
        isFalse,
        reason:
            'cards ${entries[i].key} and ${entries[j].key} overlap: '
            '$a vs $b',
      );
    }
  }
}

void _assertCanvasEncloses(GenerationTreeLayout layout) {
  for (final entry in layout.cardRects.entries) {
    expect(
      entry.value.left,
      greaterThanOrEqualTo(0),
      reason: 'card ${entry.key} starts left of the canvas',
    );
    expect(
      entry.value.top,
      greaterThanOrEqualTo(0),
      reason: 'card ${entry.key} starts above the canvas',
    );
    expect(
      entry.value.right,
      lessThanOrEqualTo(layout.canvasSize.width),
      reason: 'card ${entry.key} ends right of the canvas',
    );
    expect(
      entry.value.bottom,
      lessThanOrEqualTo(layout.canvasSize.height),
      reason: 'card ${entry.key} ends below the canvas',
    );
  }
}

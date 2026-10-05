// The chart layout engines behind the pedigree, hourglass and bow-tie views,
// plus the family group sheet's shareable text.
//
// Layout invariants: no two cards overlap; each generation sits on its own
// row with ancestors above the focus; a pedigree-collapse ancestor is placed
// once; the hourglass stacks both blocks around one focus card; the bow-tie
// mirrors the mother's line to the right of the focus.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/features/settings/app_settings_provider.dart';
import 'package:vanshvriksh/features/tree/ancestor_tree_layout.dart';
import 'package:vanshvriksh/features/tree/family_group_sheet_page.dart';
import 'package:vanshvriksh/features/tree/generation_tree_layout.dart';

void main() {
  const cardSize = Size(156, 72);

  group('computeAncestorTreeLayout', () {
    test('stacks generations above the focus without overlaps', () {
      final layout = computeAncestorTreeLayout(
        focusId: 'me',
        fatherOf: const {'me': 'dad', 'dad': 'gf1', 'mom': 'gf2'},
        motherOf: const {'me': 'mom', 'dad': 'gm1', 'mom': 'gm2'},
        maxGenerations: 4,
        cardSize: cardSize,
      );

      _assertNoOverlap(layout.cardRects);
      _assertCanvasEncloses(layout);

      // Focus on the bottom row, parents above, grandparents above that.
      final focusY = layout.cardRects['me']!.top;
      final parentY = layout.cardRects['dad']!.top;
      final grandParentY = layout.cardRects['gf1']!.top;
      expect(parentY, lessThan(focusY));
      expect(grandParentY, lessThan(parentY));

      // One connector per parent→child line.
      expect(layout.connectors, hasLength(6));
    });

    test('places a pedigree-collapse ancestor once', () {
      // The same couple is both the paternal and maternal grandparents —
      // cousins marrying. They must render as one card each.
      final layout = computeAncestorTreeLayout(
        focusId: 'me',
        fatherOf: const {'me': 'dad', 'dad': 'gpa', 'mom': 'gpa'},
        motherOf: const {'me': 'mom', 'dad': 'gma', 'mom': 'gma'},
        maxGenerations: 4,
        cardSize: cardSize,
      );

      expect(layout.cardRects.containsKey('gpa'), isTrue);
      expect(layout.cardRects.containsKey('gma'), isTrue);
      expect(layout.cardRects, hasLength(5)); // me, dad, mom, gpa, gma
      _assertNoOverlap(layout.cardRects);
    });

    test('a single known parent still renders', () {
      final layout = computeAncestorTreeLayout(
        focusId: 'me',
        fatherOf: const {'me': 'dad'},
        motherOf: const {},
        maxGenerations: 4,
        cardSize: cardSize,
      );

      expect(layout.cardRects.keys.toSet(), {'me', 'dad'});
      _assertNoOverlap(layout.cardRects);
      expect(layout.connectors, hasLength(1));
    });
  });

  group('mergeHourglassLayouts', () {
    final ancestorLayout = computeAncestorTreeLayout(
      focusId: 'me',
      fatherOf: const {'me': 'dad'},
      motherOf: const {'me': 'mom', 'mom': 'gm'},
      maxGenerations: 4,
      cardSize: cardSize,
    );
    final descendantLayout = computeGenerationTreeLayout(
      rootId: 'me',
      couples: [
        const TreeLayoutCouple(
          familyId: 'f1',
          partnerIds: ['me', 'spouse'],
          childIds: ['kid1', 'kid2'],
        ),
      ],
      cardSize: cardSize,
    );

    final merged = mergeHourglassLayouts(
      ancestorLayout: ancestorLayout,
      descendantLayout: descendantLayout,
      focusId: 'me',
    );

    test('keeps exactly one focus card between both blocks', () {
      expect(merged.cardRects.containsKey('me'), isTrue);
      _assertNoOverlap(merged.cardRects);
      _assertCanvasEncloses(merged);
    });

    test('ancestors above the focus, descendants below', () {
      final focusTop = merged.cardRects['me']!.top;
      final focusBottom = merged.cardRects['me']!.bottom;

      expect(merged.cardRects['dad']!.bottom, lessThan(focusTop));
      expect(merged.cardRects['kid1']!.top, greaterThan(focusBottom));
      expect(merged.cardRects['spouse']!.top, focusTop);
    });
  });

  group('mergeBowTieLayouts', () {
    // Single-lineage chains, as the provider builds them: the father's
    // paternal line (dad → his father) and the mother's maternal line
    // (mom → her mother).
    final fatherLine = computeAncestorTreeLayout(
      focusId: 'dad',
      fatherOf: const {'dad': 'pGF'},
      motherOf: const {},
      maxGenerations: 4,
      cardSize: cardSize,
    );
    final motherLine = computeAncestorTreeLayout(
      focusId: 'mom',
      fatherOf: const {},
      motherOf: const {'mom': 'mGM'},
      maxGenerations: 4,
      cardSize: cardSize,
    );

    final merged = mergeBowTieLayouts(
      focusId: 'me',
      fatherLayout: fatherLine,
      motherLayout: motherLine,
      fatherId: 'dad',
      motherId: 'mom',
    );

    test("father's line left, mother's line right, focus between", () {
      final focusLeft = merged.cardRects['me']!.left;
      final focusRight = merged.cardRects['me']!.right;

      // Dad's patrilineal chain sits entirely left of the focus…
      expect(merged.cardRects['dad']!.right, lessThan(focusLeft));
      expect(merged.cardRects['pGF']!.right, lessThan(focusLeft));
      // …mom's matrilineal chain entirely right of it, each generation on
      // the row above (mirroring keeps her wing flaring outward).
      expect(merged.cardRects['mom']!.left, greaterThan(focusRight));
      expect(merged.cardRects['mGM']!.right, greaterThan(focusRight));
      expect(
        merged.cardRects['mGM']!.bottom,
        lessThan(merged.cardRects['mom']!.top),
      );
      _assertNoOverlap(merged.cardRects);
      _assertCanvasEncloses(merged);
    });

    test('ties both parents into the focus with horizontal connectors', () {
      final horizontal = merged.connectors.where(
        (path) => path.length == 2 && path.first.dy == path.last.dy,
      );
      expect(horizontal, hasLength(2));
    });
  });

  group('family group sheet text', () {
    test('renders couple, marriage and children as text', () {
      final data = FamilyGroupSheetData(
        person: _person('1', 'Raman'),
        groups: [
          NuclearFamily(
            familyId: 'f1',
            husband: _person('1', 'Raman'),
            wife: _person('2', 'Mani'),
            marriageDate: DateTime(1945, 6, 2),
            marriagePlace: 'Surat',
            divorceDate: null,
            children: [_person('3', 'Kirit'), _person('4', 'Nita')],
          ),
        ],
      );

      final text = buildGroupSheetText(data, DateDisplayFormat.yearOnly);

      expect(text, contains('Family Group Sheet'));
      expect(text, contains('Raman'));
      expect(text, contains('Mani'));
      expect(text, contains('Married:'));
      expect(text, contains('Surat'));
      expect(text, contains('Children: 2'));
      expect(text, contains('- Kirit'));
      expect(text, contains('- Nita'));
    });
  });
}

GenealogyPerson _person(String id, String firstName) {
  final now = DateTime(2000);
  return GenealogyPerson(
    id: id,
    uuid: 'uuid-$id',
    treeId: 'default-tree',
    firstName: firstName,
    gender: 'male',
    birthDate: DateTime(1920),
    displayNameFormat: 'birth_married',
    isLiving: true,
    isPrivate: false,
    privacyLevel: 0,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
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
            'cards ${entries[i].key} and ${entries[j].key} overlap: $a vs $b',
      );
    }
  }
}

void _assertCanvasEncloses(GenerationTreeLayout layout) {
  for (final entry in layout.cardRects.entries) {
    expect(entry.value.left, greaterThanOrEqualTo(0), reason: entry.key);
    expect(entry.value.top, greaterThanOrEqualTo(0), reason: entry.key);
    expect(
      entry.value.right,
      lessThanOrEqualTo(layout.canvasSize.width),
      reason: entry.key,
    );
    expect(
      entry.value.bottom,
      lessThanOrEqualTo(layout.canvasSize.height),
      reason: entry.key,
    );
  }
}

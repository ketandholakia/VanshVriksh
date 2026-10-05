import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../settings/app_settings_provider.dart';
import 'ancestor_tree_layout.dart';
import 'chart_canvas.dart';
import 'chart_providers.dart';
import 'generation_tree_layout.dart';

/// The rectangular charts: pedigree (direct ancestors), descendant drop-line,
/// hourglass (ancestors above, descendants below) and bow-tie (father's line
/// left, mother's line right). They differ only in which provider feeds them
/// and how the layout is composed, so they share one scaffold and card set.
///
/// The fan chart lives in `family_fan_chart_page.dart`; the free generation
/// tree in `family_tree_page.dart`.

const Size _chartCardSize = Size(156, 72);

class PedigreeChartPage extends ConsumerWidget {
  const PedigreeChartPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChartScaffold(
      title: 'Pedigree',
      personId: personId,
      chart: ref.watch(pedigreeChartProvider(personId)),
      buildLayout: (data) => computeAncestorTreeLayout(
        focusId: data.focusId,
        fatherOf: data.fatherOf,
        motherOf: data.motherOf,
        maxGenerations: 12,
        cardSize: _chartCardSize,
      ),
    );
  }
}

class DescendantChartPage extends ConsumerWidget {
  const DescendantChartPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChartScaffold(
      title: 'Descendants',
      personId: personId,
      chart: ref.watch(descendantChartProvider(personId)),
      buildLayout: (data) => computeGenerationTreeLayout(
        rootId: data.rootId,
        couples: [
          for (final couple in data.couples)
            TreeLayoutCouple(
              familyId: couple.familyId,
              partnerIds: couple.partnerIds,
              childIds: couple.childIds,
            ),
        ],
        cardSize: _chartCardSize,
      ),
    );
  }
}

class HourglassChartPage extends ConsumerWidget {
  const HourglassChartPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChartScaffold(
      title: 'Hourglass',
      personId: personId,
      chart: ref.watch(hourglassChartProvider(personId)),
      buildLayout: (data) {
        final ancestorLayout = computeAncestorTreeLayout(
          focusId: data.ancestors.focusId,
          fatherOf: data.ancestors.fatherOf,
          motherOf: data.ancestors.motherOf,
          maxGenerations: 12,
          cardSize: _chartCardSize,
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
          cardSize: _chartCardSize,
        );
        return mergeHourglassLayouts(
          ancestorLayout: ancestorLayout,
          descendantLayout: descendantLayout,
          focusId: data.focusId,
        );
      },
    );
  }
}

class BowTieChartPage extends ConsumerWidget {
  const BowTieChartPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChartScaffold(
      title: 'Bow tie',
      personId: personId,
      chart: ref.watch(bowTieChartProvider(personId)),
      buildLayout: (data) {
        GenerationTreeLayout layoutFor(DirectLineData? line) {
          if (line == null) {
            return const GenerationTreeLayout(
              cardRects: {},
              generations: {},
              connectors: [],
              canvasSize: Size.zero,
            );
          }
          return computeAncestorTreeLayout(
            focusId: line.focusId,
            fatherOf: line.fatherOf,
            motherOf: line.motherOf,
            maxGenerations: 12,
            cardSize: _chartCardSize,
          );
        }

        return mergeBowTieLayouts(
          focusId: data.focusId,
          fatherLayout: layoutFor(data.fatherLine),
          motherLayout: layoutFor(data.motherLine),
          fatherId: data.fatherId,
          motherId: data.motherId,
        );
      },
    );
  }
}

class _ChartScaffold<T> extends ConsumerWidget {
  const _ChartScaffold({
    required this.title,
    required this.personId,
    required this.chart,
    required this.buildLayout,
  });

  final String title;
  final String personId;
  final AsyncValue<T?> chart;
  final GenerationTreeLayout Function(T data) buildLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat =
        ref.watch(dateDisplayFormatProvider).value ??
        DateDisplayFormat.fullDate;
    final hideYears = ref.watch(hideYearsForLivingProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: chart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load chart:\n$error'),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Person not found'));
          }
          final layout = buildLayout(data);
          final people = switch (data) {
            DirectLineData d => d.people,
            DescendantLineData d => d.people,
            HourglassChartData d => d.people,
            BowTieChartData d => d.people,
            _ => <String, GenealogyPerson>{},
          };

          return InheritedChartSettings(
            dateFormat: dateFormat,
            hideYearsForLiving: hideYears,
            child: FamilyChartCanvas(
              layout: layout,
              people: people,
              rootId: personId,
            ),
          );
        },
      ),
    );
  }
}

/// Opens the chart picker for [personId] — the entry point shared by the
/// profile page and the tree pages.
Future<void> showChartPicker(BuildContext context, String personId) {
  final options = <(String, IconData, String)>[
    ('Generation tree', Icons.account_tree_outlined, '/tree/$personId'),
    ('Fan chart', Icons.filter_drama_outlined, '/fan-tree/$personId'),
    ('Pedigree', Icons.timeline, '/pedigree/$personId'),
    ('Descendants', Icons.device_hub, '/descendant-chart/$personId'),
    ('Hourglass', Icons.hourglass_bottom_outlined, '/hourglass/$personId'),
    ('Bow tie', Icons.swap_horiz, '/bow-tie/$personId'),
    ('Genogram', Icons.medical_services_outlined, '/genogram/$personId'),
    (
      'Family group sheet',
      Icons.description_outlined,
      '/family-sheet/$personId',
    ),
  ];

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'View as chart',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final (label, icon, route) in options)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(route);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

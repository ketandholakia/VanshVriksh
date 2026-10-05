import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_background.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../../data/database/app_database.dart';
import '../settings/app_settings_provider.dart';
import '../settings/display_formatters.dart';
import 'generation_tree_layout.dart';

/// The interactive frame every rectangular chart renders inside: pan/zoom,
/// fit-to-viewport on open, connectors under the cards.
///
/// Charts describe themselves as a [GenerationTreeLayout] — card rectangles in
/// canvas coordinates plus the connector polylines between them — and hand a
/// card builder per person. `family_tree_page` keeps its own richer card; the
/// other charts share [defaultChartCardBuilder] and [ChartPersonCard].
class FamilyChartCanvas extends StatefulWidget {
  const FamilyChartCanvas({
    super.key,
    required this.layout,
    required this.people,
    required this.rootId,
    this.cardBuilder = defaultChartCardBuilder,
    this.lineThickness = TreeLineThickness.normal,
    this.zoomOnLoad = true,
  });

  final GenerationTreeLayout layout;
  final Map<String, GenealogyPerson> people;
  final String rootId;
  final Widget Function(
    BuildContext context,
    GenealogyPerson person,
    Rect rect,
    bool isRoot,
  )
  cardBuilder;
  final TreeLineThickness lineThickness;
  final bool zoomOnLoad;

  @override
  State<FamilyChartCanvas> createState() => _FamilyChartCanvasState();
}

class _FamilyChartCanvasState extends State<FamilyChartCanvas> {
  final TransformationController _controller = TransformationController();
  bool _fittedToViewport = false;

  @override
  void didUpdateWidget(covariant FamilyChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout.canvasSize != widget.layout.canvasSize) {
      _fittedToViewport = false;
      _controller.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Frame the whole chart on open instead of dropping the user into the
  /// top-left corner where a wide chart looks like a single card.
  void _fitToViewport(Size viewport, Size canvas) {
    if (_fittedToViewport || viewport.isEmpty || canvas.isEmpty) return;
    _fittedToViewport = true;
    final scale = math.min(
      1.0,
      math.min(viewport.width / canvas.width, viewport.height / canvas.height),
    );
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - canvas.width * scale) / 2,
        (viewport.height - canvas.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (widget.zoomOnLoad && !_fittedToViewport && !viewport.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitToViewport(viewport, layout.canvasSize);
          });
        }

        return InteractiveViewer(
          constrained: false,
          transformationController: _controller,
          boundaryMargin: const EdgeInsets.all(1200),
          minScale: 0.05,
          maxScale: 2.5,
          child: SizedBox(
            width: layout.canvasSize.width,
            height: layout.canvasSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: ChartConnectorPainter(
                      connectors: layout.connectors,
                      color: colorScheme.primary.withValues(alpha: 0.6),
                      strokeWidth: switch (widget.lineThickness) {
                        TreeLineThickness.thin => 1.4,
                        TreeLineThickness.thick => 3.2,
                        TreeLineThickness.normal => 2.2,
                      },
                    ),
                  ),
                ),
                for (final entry in layout.cardRects.entries)
                  if (widget.people[entry.key] != null)
                    Positioned.fromRect(
                      rect: entry.value,
                      child: widget.cardBuilder(
                        context,
                        widget.people[entry.key]!,
                        entry.value,
                        entry.key == widget.rootId,
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Strokes the polylines a layout produced.
class ChartConnectorPainter extends CustomPainter {
  const ChartConnectorPainter({
    required this.connectors,
    required this.color,
    required this.strokeWidth,
  });

  final List<TreeLayoutPath> connectors;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (connectors.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final points in connectors) {
      if (points.length < 2) continue;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ChartConnectorPainter oldDelegate) =>
      oldDelegate.connectors != connectors ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// The card the standard charts use: gender-tinted, name and lifespan.
class ChartPersonCard extends StatelessWidget {
  const ChartPersonCard({
    super.key,
    required this.person,
    required this.isRoot,
    required this.dateFormat,
    required this.hideYearsForLiving,
  });

  final GenealogyPerson person;
  final bool isRoot;
  final DateDisplayFormat dateFormat;
  final bool hideYearsForLiving;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = switch (person.gender.trim().toLowerCase()) {
      final g when g.startsWith('m') => colorScheme.primaryContainer,
      final g when g.startsWith('f') => colorScheme.tertiaryContainer,
      _ => colorScheme.surfaceContainerHighest,
    };

    final lifespan = formatLifespanForDisplay(
      person.birthDate,
      person.deathDate,
      dateFormat,
      isLiving: person.isLiving,
      hideYearsForLiving: hideYearsForLiving,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/people/${person.id}'),
      child: Card(
        color: isRoot ? colorScheme.primaryContainer : colorScheme.surface,
        elevation: isRoot ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isRoot
                ? colorScheme.primary.withValues(alpha: 0.28)
                : colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Stack(
            children: [
              const Positioned.fill(child: BrandWatermark(opacity: 0.05)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: accent,
                        child: Text(
                          person.fullName.trim().isNotEmpty
                              ? person.fullName.trim()[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!person.isLiving)
                        Icon(
                          Icons.person_off_outlined,
                          size: 13,
                          color: colorScheme.outline,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    person.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.2,
                      height: 1.1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (lifespan.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lifespan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget defaultChartCardBuilder(
  BuildContext context,
  GenealogyPerson person,
  Rect rect,
  bool isRoot,
) {
  return Builder(
    builder: (cardContext) {
      final dateFormat =
          InheritedChartSettings.maybeOf(cardContext)?.dateFormat ??
          DateDisplayFormat.fullDate;
      final hideYears =
          InheritedChartSettings.maybeOf(cardContext)?.hideYearsForLiving ??
          false;
      return ChartPersonCard(
        person: person,
        isRoot: isRoot,
        dateFormat: dateFormat,
        hideYearsForLiving: hideYears,
      );
    },
  );
}

/// Carries the display settings into the default card builder without every
/// chart page having to close over them.
class InheritedChartSettings extends InheritedWidget {
  const InheritedChartSettings({
    super.key,
    required this.dateFormat,
    required this.hideYearsForLiving,
    required super.child,
  });

  final DateDisplayFormat dateFormat;
  final bool hideYearsForLiving;

  static InheritedChartSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedChartSettings>();

  @override
  bool updateShouldNotify(InheritedChartSettings oldWidget) =>
      oldWidget.dateFormat != dateFormat ||
      oldWidget.hideYearsForLiving != hideYearsForLiving;
}

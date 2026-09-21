import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/genealogy_person_extensions.dart';
import '../../core/widgets/person_avatar.dart';
import '../../data/database/app_database.dart';
import '../people/people_providers.dart';
import '../settings/app_settings_provider.dart';
import 'tree_models.dart';
import 'tree_providers.dart';
import 'tree_view_mode_toggle.dart';

class FamilyFanChartPage extends ConsumerStatefulWidget {
  const FamilyFanChartPage({super.key, this.rootPersonId});

  final String? rootPersonId;

  @override
  ConsumerState<FamilyFanChartPage> createState() => _FamilyFanChartPageState();
}

class _FamilyFanChartPageState extends ConsumerState<FamilyFanChartPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (widget.rootPersonId != null) {
        ref
            .read(selectedRootPersonIdProvider.notifier)
            .setRootPersonId(widget.rootPersonId);
      }
    });
  }

  @override
  void dispose() {
    final rememberRootEnabled =
        ref.read(rememberLastRootPersonProvider).value ??
        rememberLastRootPersonDefault;
    if (!rememberRootEnabled) {
      ref.read(selectedRootPersonIdProvider.notifier).setRootPersonId(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRootId = ref.watch(selectedRootPersonIdProvider);
    final firstPersonAsync = ref.watch(firstPersonProvider);
    final peopleAsync = ref.watch(peopleListProvider);
    final savedRootAsync = ref.watch(lastRootPersonIdProvider);
    final defaultRootAsync = ref.watch(defaultRootPersonIdProvider);
    final rememberRootEnabled =
        ref.watch(rememberLastRootPersonProvider).value ??
        rememberLastRootPersonDefault;
    final rootId =
        selectedRootId ??
        widget.rootPersonId ??
        (rememberRootEnabled ? savedRootAsync.value : null) ??
        defaultRootAsync.value ??
        firstPersonAsync.asData?.value?.id;
    final dateFormat =
        ref.watch(dateDisplayFormatProvider).value ?? dateDisplayFormatDefault;
    final labelStyle =
        ref.watch(relationshipLabelStyleProvider).value ??
        relationshipLabelStyleDefault;
    final photoFitMode =
        ref.watch(personPhotoFitModeProvider).value ??
        personPhotoFitModeDefault;
    final treeSpacing =
        ref.watch(treeCardSpacingProvider).value ?? treeCardSpacingDefault;
    final treeDensity =
        ref.watch(treeCardDensityProvider).value ?? treeCardDensityDefault;
    final lineThickness =
        ref.watch(treeLineThicknessProvider).value ?? treeLineThicknessDefault;
    final zoomOnLoad = ref.watch(zoomOnLoadProvider).value ?? zoomOnLoadDefault;
    final hideYearsForLiving =
        ref.watch(hideYearsForLivingProvider).value ??
        hideYearsForLivingDefault;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fan Chart'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TreeFanModeToggle(
              selectedMode: TreeViewMode.fan,
              onTreeSelected: () {
                if (rootId == null) return;
                context.push('/tree/$rootId');
              },
              onFanSelected: () {},
            ),
          ),
          IconButton(
            tooltip: 'People',
            onPressed: () => context.push('/people'),
            icon: const Icon(Icons.people_alt_outlined),
          ),
        ],
      ),
      body: firstPersonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load fan chart:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (firstPerson) {
          if (firstPerson == null) {
            return _EmptyFanView(
              onAddPerson: () => context.push('/people/add?returnTo=/fan-tree'),
            );
          }

          final rootId =
              selectedRootId ??
              widget.rootPersonId ??
              (rememberRootEnabled ? savedRootAsync.value : null) ??
              defaultRootAsync.value ??
              firstPerson.id;
          final ancestryAsync = ref.watch(ancestryFanChartProvider(rootId));

          return Column(
            children: [
              peopleAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (people) => _RootPersonSelector(
                  people: people,
                  selectedPersonId: rootId,
                  onChanged: (personId) {
                    if (personId == null) return;
                    ref
                        .read(selectedRootPersonIdProvider.notifier)
                        .setRootPersonId(personId);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: const [
                        Icon(Icons.touch_app_outlined),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tap a card to view profile. Long press a person to make them root. Tap a missing ancestor slot to add father or mother.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ancestryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to render fan chart:\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (fanChartData) {
                    if (fanChartData == null) {
                      return const Center(
                        child: Text('Selected person not found'),
                      );
                    }

                    return _AncestryFanChartCanvas(
                      data: fanChartData,
                      dateFormat: dateFormat,
                      labelStyle: labelStyle,
                      photoFitMode: photoFitMode,
                      spacing: treeSpacing,
                      density: treeDensity,
                      lineThickness: lineThickness,
                      hideYearsForLiving: hideYearsForLiving,
                      zoomOnLoad: zoomOnLoad,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RootPersonSelector extends StatelessWidget {
  const _RootPersonSelector({
    required this.people,
    required this.selectedPersonId,
    required this.onChanged,
  });

  final List<GenealogyPerson> people;
  final String selectedPersonId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
          initialValue: selectedPersonId,
          decoration: const InputDecoration(
            labelText: 'Root Person',
            prefixIcon: Icon(Icons.pie_chart_outline),
          ),
          items: people
              .map(
                (person) => DropdownMenuItem(
                  value: person.id,
                  child: Text(person.fullName),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EmptyFanView extends StatelessWidget {
  const _EmptyFanView({required this.onAddPerson});

  final VoidCallback onAddPerson;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No fan chart yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first family member to start building the fan chart.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddPerson,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add First Person'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AncestryFanChartCanvas extends StatefulWidget {
  const _AncestryFanChartCanvas({
    required this.data,
    required this.dateFormat,
    required this.labelStyle,
    required this.photoFitMode,
    required this.spacing,
    required this.density,
    required this.lineThickness,
    required this.hideYearsForLiving,
    required this.zoomOnLoad,
  });

  final AncestryFanChartData data;
  final DateDisplayFormat dateFormat;
  final RelationshipLabelStyle labelStyle;
  final PersonPhotoFitMode photoFitMode;
  final TreeCardSpacing spacing;
  final TreeCardDensity density;
  final TreeLineThickness lineThickness;
  final bool hideYearsForLiving;
  final bool zoomOnLoad;

  @override
  State<_AncestryFanChartCanvas> createState() =>
      _AncestryFanChartCanvasState();
}

class _AncestryFanChartCanvasState extends State<_AncestryFanChartCanvas> {
  static const double canvasWidth = 1600;
  static const double canvasHeight = 1600;
  static const double baseNodeWidth = 180;
  static const double baseNodeHeight = 82;

  final TransformationController _transformationController =
      TransformationController();
  bool _hasAutoFitted = false;
  Offset? _tapLocalPosition;

  double get _densityFactor => switch (widget.density) {
    TreeCardDensity.compact => 0.9,
    TreeCardDensity.normal => 1.0,
    TreeCardDensity.spacious => 1.12,
  };

  double get _nodeWidth => baseNodeWidth * _densityFactor;
  double get _nodeHeight => baseNodeHeight * _densityFactor;

  @override
  void didUpdateWidget(covariant _AncestryFanChartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.rootPerson.id != widget.data.rootPerson.id ||
        oldWidget.data.generations.length != widget.data.generations.length ||
        oldWidget.spacing != widget.spacing ||
        oldWidget.density != widget.density ||
        oldWidget.lineThickness != widget.lineThickness) {
      _hasAutoFitted = false;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _layoutNodes();
    final sectors = _buildSectors(nodes);
    final contentBounds = _contentBounds(nodes).inflate(48);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.zoomOnLoad) {
          _scheduleAutoFit(constraints.biggest, contentBounds);
        }

        return InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.25,
          maxScale: 2.75,
          constrained: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _tapLocalPosition = details.localPosition,
            onTapUp: (_) {
              final tap = _tapLocalPosition;
              _tapLocalPosition = null;
              if (tap == null) return;
              final match = _hitTestSector(sectors, tap);
              if (match == null || match.person == null) return;
              context.push('/people/${match.person!.id}');
            },
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: CustomPaint(
                painter: _RadialFanChartPainter(
                  sectors: sectors,
                  selectedPersonId: null,
                  colorScheme: Theme.of(context).colorScheme,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _scheduleAutoFit(Size viewportSize, Rect contentBounds) {
    if (_hasAutoFitted ||
        viewportSize.isInfinite ||
        viewportSize.width <= 0 ||
        viewportSize.height <= 0) {
      return;
    }

    _hasAutoFitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitToViewport(viewportSize, contentBounds);
    });
  }

  void _fitToViewport(Size viewportSize, Rect contentBounds) {
    final scale = math.min(
      viewportSize.width / contentBounds.width,
      viewportSize.height / contentBounds.height,
    );
    final clampedScale = scale.clamp(0.25, 2.75).toDouble();

    final dx =
        (viewportSize.width - contentBounds.width * clampedScale) / 2 -
        contentBounds.left * clampedScale;
    final dy =
        (viewportSize.height - contentBounds.height * clampedScale) / 2 -
        contentBounds.top * clampedScale;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(clampedScale, clampedScale, 1, 1);
  }

  Rect _contentBounds(List<_AncestryNodePosition> nodes) {
    if (nodes.isEmpty) {
      return Rect.zero;
    }

    var bounds = Rect.fromLTWH(
      nodes.first.x,
      nodes.first.y,
      _nodeWidth,
      _nodeHeight,
    );
    for (var index = 1; index < nodes.length; index++) {
      final node = nodes[index];
      bounds = bounds.expandToInclude(
        Rect.fromLTWH(node.x, node.y, _nodeWidth, _nodeHeight),
      );
    }

    return bounds;
  }

  List<_AncestryNodePosition> _layoutNodes() {
    final nodes = <_AncestryNodePosition>[];
    final rootX = canvasWidth / 2 - _nodeWidth / 2;
    final rootY = canvasHeight - 140;

    nodes.add(
      _AncestryNodePosition(
        slot: widget.data.generations.first.first,
        x: rootX,
        y: rootY,
        width: _nodeWidth,
        height: _nodeHeight,
      ),
    );

    final arcCenter = Offset(canvasWidth / 2, canvasHeight + 220);
    const startAngle = math.pi * 1.08;
    const sweepAngle = math.pi * 0.84;
    final baseRadius = 200.0 * _spacingFactor() * _densityFactor;
    final radiusStep = 145.0 * _spacingFactor() * _densityFactor;

    for (
      var generation = 1;
      generation < widget.data.generations.length;
      generation++
    ) {
      final slots = widget.data.generations[generation];
      final radius = baseRadius + ((generation - 1) * radiusStep);
      final positions = _spreadArc(
        count: slots.length,
        center: arcCenter,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        radius: radius,
      );

      for (var index = 0; index < slots.length; index++) {
        final slot = slots[index];
        final position = positions[index];
        nodes.add(
          _AncestryNodePosition(
            slot: slot,
            x: position.dx - _nodeWidth / 2,
            y: position.dy - _nodeHeight / 2,
            width: _nodeWidth,
            height: _nodeHeight,
          ),
        );
      }
    }

    return nodes;
  }

  List<_FanSector> _buildSectors(List<_AncestryNodePosition> nodes) {
    final sectors = <_FanSector>[];
    final center = Offset(canvasWidth / 2, canvasHeight / 2);
    final root = nodes.first;
    sectors.add(
      _FanSector(
        node: root,
        person: root.slot.person,
        innerRadius: 0,
        outerRadius: 110,
        startAngle: 0,
        sweepAngle: 2 * math.pi,
        center: center,
      ),
    );

    for (
      var generation = 1;
      generation < widget.data.generations.length;
      generation++
    ) {
      final slots = widget.data.generations[generation];
      final radius =
          110 + (generation * 120.0 * _spacingFactor() * _densityFactor);
      final innerRadius = radius - (108 * _densityFactor);
      final startAngle = math.pi * 1.08;
      final sweepAngle = math.pi * 0.84;
      for (var index = 0; index < slots.length; index++) {
        final slot = slots[index];
        final start = slots.length == 1
            ? startAngle
            : startAngle + sweepAngle * (index / slots.length);
        final end = slots.length == 1
            ? startAngle + sweepAngle
            : startAngle + sweepAngle * ((index + 1) / slots.length);
        sectors.add(
          _FanSector(
            node: nodes.firstWhere(
              (node) => node.slot == slot,
              orElse: () => nodes.first,
            ),
            person: slot.person,
            innerRadius: innerRadius,
            outerRadius: radius,
            startAngle: start,
            sweepAngle: end - start,
            center: center,
          ),
        );
      }
    }

    return sectors;
  }

  _FanSector? _hitTestSector(List<_FanSector> sectors, Offset point) {
    for (final sector in sectors.reversed) {
      if (sector.contains(point)) return sector;
    }
    return null;
  }

  double _spacingFactor() {
    return switch (widget.spacing) {
      TreeCardSpacing.compact => 0.85,
      TreeCardSpacing.normal => 1.0,
      TreeCardSpacing.spacious => 1.2,
    };
  }

  List<Offset> _spreadArc({
    required int count,
    required Offset center,
    required double startAngle,
    required double sweepAngle,
    required double radius,
  }) {
    if (count == 1) {
      final angle = startAngle + sweepAngle / 2;
      return [
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
      ];
    }

    return List.generate(count, (index) {
      final t = index / (count - 1);
      final angle = startAngle + sweepAngle * t;
      return Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    });
  }
}

class _AncestryNodePosition {
  const _AncestryNodePosition({
    required this.slot,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final AncestrySlot slot;
  final double x;
  final double y;
  final double width;
  final double height;

  Offset get topCenter => Offset(x + width / 2, y);
  Offset get bottomCenter => Offset(x + width / 2, y + height);
  Offset get leftCenter => Offset(x, y + height / 2);
  Offset get rightCenter => Offset(x + width, y + height / 2);
}

class _FanSector {
  _FanSector({
    required this.node,
    required this.person,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sweepAngle,
    required this.center,
  });

  final _AncestryNodePosition node;
  final GenealogyPerson? person;
  final double innerRadius;
  final double outerRadius;
  final double startAngle;
  final double sweepAngle;
  final Offset center;

  bool contains(Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final radius = math.sqrt(dx * dx + dy * dy);
    if (radius < innerRadius || radius > outerRadius) return false;

    var angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    final start = _normalizeAngle(startAngle);
    final end = _normalizeAngle(startAngle + sweepAngle);
    if (start <= end) return angle >= start && angle <= end;
    return angle >= start || angle <= end;
  }

  double _normalizeAngle(double value) {
    var result = value % (2 * math.pi);
    if (result < 0) result += 2 * math.pi;
    return result;
  }
}

class _RadialFanChartPainter extends CustomPainter {
  const _RadialFanChartPainter({
    required this.sectors,
    required this.selectedPersonId,
    required this.colorScheme,
  });

  final List<_FanSector> sectors;
  final String? selectedPersonId;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..style = PaintingStyle.fill;
    final center = sectors.first.center;

    canvas.drawCircle(center, 78, Paint()..color = colorScheme.surface);
    canvas.drawCircle(
      center,
      78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.35),
    );

    final rootPerson = sectors.first.person;
    if (rootPerson != null) {
      _paintCenterLabel(canvas, center, rootPerson);
    }

    for (final sector in sectors) {
      final person = sector.person;
      final rect = Rect.fromCircle(
        center: sector.center,
        radius: sector.outerRadius,
      );
      final path = Path()
        ..addArc(rect, sector.startAngle, sector.sweepAngle)
        ..arcTo(
          Rect.fromCircle(center: sector.center, radius: sector.innerRadius),
          sector.startAngle + sector.sweepAngle,
          -sector.sweepAngle,
          false,
        )
        ..close();

      final color = _sectorColor(sector);
      fill.color = color;
      stroke.color = colorScheme.outline.withValues(alpha: 0.18);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);

      if (person != null && !sector.node.slot.isRoot) {
        _paintSectorLabel(canvas, sector, person);
      }
    }
  }

  Color _sectorColor(_FanSector sector) {
    if (sector.node.slot.isRoot) {
      return colorScheme.surfaceContainerHighest;
    }

    final generation = sector.node.slot.generation;
    final depthTint = (generation * 12).clamp(0, 42).toDouble();
    final alpha = (0.95 - (generation * 0.07)).clamp(0.55, 0.95);
    final isRightSide =
        math.cos(sector.startAngle + sector.sweepAngle / 2) >= 0;

    final base = isRightSide
        ? colorScheme.secondaryContainer
        : colorScheme.tertiaryContainer;
    return Color.alphaBlend(
      colorScheme.surface.withValues(alpha: depthTint / 100),
      base.withValues(alpha: alpha),
    );
  }

  void _paintCenterLabel(Canvas canvas, Offset center, GenealogyPerson rootPerson) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: rootPerson.fullName,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 110);

    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: rootPerson.isLiving ? 'Living root' : 'Root person',
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 110);

    final totalHeight = titlePainter.height + subtitlePainter.height + 4;
    titlePainter.paint(
      canvas,
      Offset(center.dx - titlePainter.width / 2, center.dy - totalHeight / 2),
    );
    subtitlePainter.paint(
      canvas,
      Offset(
        center.dx - subtitlePainter.width / 2,
        center.dy - totalHeight / 2 + titlePainter.height + 4,
      ),
    );
  }

  void _paintSectorLabel(Canvas canvas, _FanSector sector, GenealogyPerson person) {
    final mid = sector.startAngle + sector.sweepAngle / 2;
    final radius = (sector.innerRadius + sector.outerRadius) / 2;
    final pos = Offset(
      sector.center.dx + math.cos(mid) * radius,
      sector.center.dy + math.sin(mid) * radius,
    );
    final isRight = math.cos(mid) >= 0;
    final rotate = mid + (isRight ? math.pi / 2 : -math.pi / 2);
    final availableWidth = (sector.outerRadius - sector.innerRadius) - 18;
    final label = _compactLabel(person);
    final lines = availableWidth < 95 ? 2 : 3;

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          height: 1.08,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: lines,
      textAlign: TextAlign.center,
      ellipsis: '...',
    )..layout(maxWidth: math.max(64, availableWidth));

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotate);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  String _compactLabel(GenealogyPerson person) {
    final name = person.fullName.trim();
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length <= 2) return name;
    return '${parts.first} ${parts.sublist(1, math.min(parts.length, 3)).join(' ')}';
  }

  @override
  bool shouldRepaint(covariant _RadialFanChartPainter oldDelegate) {
    return oldDelegate.sectors != sectors ||
        oldDelegate.selectedPersonId != selectedPersonId;
  }
}

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/extensions/genealogy_person_extensions.dart';
import '../../data/database/app_database.dart';
import '../settings/app_settings_provider.dart';
import '../settings/display_formatters.dart';
import 'generation_tree_layout.dart';

/// Renders a computed chart layout to a PNG file, for printing and sharing.
///
/// The bitmap paints the same geometry the interactive canvas draws —
/// connectors under flat cards with name, lifespan and gender tint — onto an
/// offscreen canvas at [pixelRatio], so what is exported is what is on
/// screen, minus the pan/zoom. A white ground keeps it printable.
Future<File> renderChartPng({
  required Size canvasSize,
  required void Function(ui.Canvas canvas, Size size) paint,
  required DateDisplayFormat dateFormat,
  String fileNamePrefix = 'vanshvriksh_chart',
  double pixelRatio = 2,
  Directory? outputDirectory,
}) async {
  if (canvasSize.isEmpty) {
    throw StateError('Nothing to export: the chart is empty.');
  }

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(pixelRatio);
  canvas.drawRect(Offset.zero & canvasSize, ui.Paint()..color = Colors.white);
  paint(canvas, canvasSize);
  final picture = recorder.endRecording();

  final image = await picture.toImage(
    (canvasSize.width * pixelRatio).ceil(),
    (canvasSize.height * pixelRatio).ceil(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    throw StateError('Could not encode the chart image.');
  }

  final docs = outputDirectory ?? await getApplicationDocumentsDirectory();
  final exportDir = Directory(p.join(docs.path, 'exports'));
  if (!await exportDir.exists()) {
    await exportDir.create(recursive: true);
  }
  final now = DateTime.now();
  final fileName =
      '${fileNamePrefix}_${now.year}_${_two(now.month)}_${_two(now.day)}'
      '_${_two(now.hour)}${_two(now.minute)}.png';
  final file = File(p.join(exportDir.path, fileName));
  await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
  return file;
}

/// Convenience wrapper that paints a [GenerationTreeLayout] with the standard
/// flat cards — what the pedigree, descendant, hourglass, bow-tie and
/// generation-tree views share.
Future<File> renderLayoutPng({
  required GenerationTreeLayout layout,
  required Map<String, GenealogyPerson> people,
  required String rootId,
  required DateDisplayFormat dateFormat,
  bool hideYearsForLiving = false,
  ColorScheme? colorScheme,
  String fileNamePrefix = 'vanshvriksh_chart',
  Directory? outputDirectory,
}) {
  return renderChartPng(
    canvasSize: layout.canvasSize,
    dateFormat: dateFormat,
    fileNamePrefix: fileNamePrefix,
    outputDirectory: outputDirectory,
    paint: (canvas, size) {
      ChartBitmapPainter(
        layout: layout,
        people: people,
        rootId: rootId,
        dateFormat: dateFormat,
        hideYearsForLiving: hideYearsForLiving,
        palette: colorScheme ?? _printPalette,
      ).paint(canvas, size);
    },
  );
}

/// Readable print palette for when no theme is at hand (and for tests).
const ColorScheme _printPalette = ColorScheme.light(
  primary: Color(0xFF445E4B),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFD9E5DB),
  onPrimaryContainer: Color(0xFF1B2E20),
  tertiary: Color(0xFF8A4A5E),
  tertiaryContainer: Color(0xFFF3D6DD),
  surface: Colors.white,
  onSurface: Color(0xFF1B1B1B),
  onSurfaceVariant: Color(0xFF5A5A5A),
  outlineVariant: Color(0xFFC9C9C9),
);

/// The bitmap form of the chart canvas: connectors beneath flat cards.
class ChartBitmapPainter {
  const ChartBitmapPainter({
    required this.layout,
    required this.people,
    required this.rootId,
    required this.dateFormat,
    required this.hideYearsForLiving,
    required this.palette,
  });

  final GenerationTreeLayout layout;
  final Map<String, GenealogyPerson> people;
  final String rootId;
  final DateDisplayFormat dateFormat;
  final bool hideYearsForLiving;
  final ColorScheme palette;

  void paint(ui.Canvas canvas, ui.Size size) {
    _paintConnectors(canvas);
    for (final entry in layout.cardRects.entries) {
      final person = people[entry.key];
      if (person != null) {
        _paintCard(canvas, person, entry.value, isRoot: entry.key == rootId);
      }
    }
  }

  void _paintConnectors(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = palette.primary.withValues(alpha: 0.6)
      ..strokeWidth = 2.2
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;
    for (final points in layout.connectors) {
      if (points.length < 2) continue;
      final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintCard(
    ui.Canvas canvas,
    GenealogyPerson person,
    Rect rect, {
    required bool isRoot,
  }) {
    final accent = switch (person.gender.trim().toLowerCase()) {
      final g when g.startsWith('m') => palette.tertiaryContainer,
      final g when g.startsWith('f') => palette.tertiaryContainer,
      _ => palette.surface,
    };
    final radius = const Radius.circular(14);
    final rrect = ui.RRect.fromRectAndRadius(rect, radius);

    canvas.drawRRect(
      rrect,
      ui.Paint()
        ..color = isRoot
            ? palette.primaryContainer
            : (accent == palette.surface ? Colors.white : accent)
        ..style = ui.PaintingStyle.fill,
    );
    canvas.drawRRect(
      rrect,
      ui.Paint()
        ..color = isRoot
            ? palette.primary.withValues(alpha: 0.9)
            : palette.outlineVariant
        ..strokeWidth = isRoot ? 2.4 : 1.2
        ..style = ui.PaintingStyle.stroke,
    );

    final pad = 8.0;
    final nameSpan = TextPainter(
      text: TextSpan(
        text: person.fullName,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isRoot ? FontWeight.w900 : FontWeight.w700,
          color: palette.onSurface,
        ),
      ),
      maxLines: 2,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - pad * 2);

    final lifespan = formatLifespanForDisplay(
      person.birthDate,
      person.deathDate,
      dateFormat,
      isLiving: person.isLiving,
      hideYearsForLiving: hideYearsForLiving,
    );
    TextPainter? lifespanSpan;
    if (lifespan.isNotEmpty && lifespan != 'Not available') {
      lifespanSpan = TextPainter(
        text: TextSpan(
          text: lifespan,
          style: TextStyle(fontSize: 10.5, color: palette.onSurfaceVariant),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - pad * 2);
    }

    final blockHeight =
        nameSpan.height + (lifespanSpan == null ? 0 : lifespanSpan.height + 2);
    var y = rect.center.dy - blockHeight / 2;
    nameSpan.paint(canvas, Offset(rect.left + pad, y));
    y += nameSpan.height + 2;
    lifespanSpan?.paint(canvas, Offset(rect.left + pad, y));

    nameSpan.dispose();
    lifespanSpan?.dispose();
  }
}

String _two(int value) => value.toString().padLeft(2, '0');

/// The largest rectangle actually used by the cards — kept for callers that
/// want a tight crop. Unused today; the full canvas keeps all padding.
math.Rectangle<double> usedBounds(GenerationTreeLayout layout) {
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final rect in layout.cardRects.values) {
    left = math.min(left, rect.left);
    top = math.min(top, rect.top);
    right = math.max(right, rect.right);
    bottom = math.max(bottom, rect.bottom);
  }
  return math.Rectangle(left, top, right - left, bottom - top);
}

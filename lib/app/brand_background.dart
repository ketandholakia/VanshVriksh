import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF141A15), Color(0xFF18211B), Color(0xFF1B231D)]
              : const [Color(0xFFFFF8E7), Color(0xFFFFFCF6), Color(0xFFF8F4EA)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: isDark ? 0.05 : 0.08,
            child: Image.asset(
              'assets/vanshvriksh_app_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: colorScheme.surface.withValues(alpha: isDark ? 0.16 : 0.10),
          ),
          child,
        ],
      ),
    );
  }
}

class BrandWatermark extends StatelessWidget {
  const BrandWatermark({
    super.key,
    this.alignment = Alignment.bottomRight,
    this.opacity = 0.055,
    this.scale = 1.0,
    this.padding = const EdgeInsets.all(20),
  });

  final Alignment alignment;
  final double opacity;
  final double scale;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: SvgPicture.asset(
                'assets/logo/tree_mark.svg',
                width: 120,
                height: 120,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

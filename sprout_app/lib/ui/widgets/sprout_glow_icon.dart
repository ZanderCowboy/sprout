import 'package:flutter/material.dart';

/// Circular icon disc: 10% fill + solid glyph, matching Stitch / Figma SVGs.
class SproutGlowIcon extends StatelessWidget {
  const SproutGlowIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

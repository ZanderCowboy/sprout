import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class UnallocatedFundsCard extends StatelessWidget {
  const UnallocatedFundsCard({
    super.key,
    required this.unallocatedCents,
    required this.onTap,
  });

  final int unallocatedCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceContainerHighest;
    final border = scheme.tertiary;

    return Semantics(
      button: true,
      label: 'Unallocated funds',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _DashedRoundedRectPainter(
              color: border,
              strokeWidth: 2,
              dashLength: 7,
              gapLength: 5,
              radius: 16,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: border,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ready to Sprout! You have ${formatZarFromCents(unallocatedCents)} waiting to be assigned.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.radius != radius;
  }
}


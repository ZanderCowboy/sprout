import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class OverviewHero extends StatelessWidget {
  const OverviewHero({
    super.key,
    required this.totalCents,
    this.lastActivityAt,
  });

  final int totalCents;
  final DateTime? lastActivityAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final updated = lastActivityAt != null
        ? formatDateTime(lastActivityAt!)
        : AppStrings.neverUpdated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.portfolioTotal.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatZarFromCents(totalCents),
            style: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.lastUpdated}: $updated',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

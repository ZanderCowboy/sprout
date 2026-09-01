import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class OverallGoalsProgressHeader extends StatelessWidget {
  const OverallGoalsProgressHeader({
    super.key,
    required this.overallPercent,
    required this.totalSavedCents,
    required this.totalTargetCents,
    required this.totalRemainingCents,
    required this.title,
    this.onTap,
    this.semanticsIdentifier,
  });

  final int overallPercent;
  final int totalSavedCents;
  final int totalTargetCents;
  final int totalRemainingCents;
  final String title;
  final VoidCallback? onTap;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (overallPercent / 100).clamp(0.0, 1.0);

    return Semantics(
      identifier: semanticsIdentifier,
      button: onTap != null,
      label: AppStrings.overallGoalsProgressSemantics(
        percent: overallPercent,
        saved: formatZarFromCents(totalSavedCents),
        target: formatZarFromCents(totalTargetCents),
      ),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        clipBehavior: onTap != null ? Clip.antiAlias : Clip.none,
        child: onTap != null
            ? InkWell(onTap: onTap, child: _content(context, scheme, progress))
            : _content(context, scheme, progress),
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme scheme, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$overallPercent%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            borderRadius: BorderRadius.circular(8),
            color: scheme.primary,
            backgroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.savedAmount(formatZarFromCents(totalSavedCents)),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                AppStrings.targetAmountLabel(
                  formatZarFromCents(totalTargetCents),
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.toGoCompleteAllGoals(
                    formatZarFromCents(totalRemainingCents),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

import '../../domain/overall_goals_totals.dart';

class OverallGoalsProgressHeader extends StatelessWidget {
  const OverallGoalsProgressHeader({
    super.key,
    required this.totals,
    required this.title,
    this.onTap,
    this.semanticsIdentifier,
  });

  final OverallGoalsTotals totals;
  final String title;
  final VoidCallback? onTap;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (totals.overallPercent / 100).clamp(0.0, 1.0);

    return Semantics(
      identifier: semanticsIdentifier,
      button: onTap != null,
      label: AppStrings.overallGoalsProgressSemantics(
        percent: totals.overallPercent,
        saved: formatZarFromCents(totals.totalSavedCents),
        target: formatZarFromCents(totals.totalTargetCents),
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
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${totals.overallPercent}%',
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
                  AppStrings.savedAmount(
                    formatZarFromCents(totals.totalSavedCents),
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                AppStrings.targetAmountLabel(
                  formatZarFromCents(totals.totalTargetCents),
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                    formatZarFromCents(totals.totalRemainingCents),
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

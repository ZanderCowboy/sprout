import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';

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
    return SproutProgressCard(
      title: title,
      percent: totals.overallPercent,
      savedLabel: AppStrings.savedAmount(
        formatZarFromCents(totals.totalSavedCents),
      ),
      targetLabel: AppStrings.targetAmountLabel(
        formatZarFromCents(totals.totalTargetCents),
      ),
      detail: AppStrings.toGoCompleteAllGoals(
        formatZarFromCents(totals.totalRemainingCents),
      ),
      onTap: onTap,
      identifier: semanticsIdentifier,
      semanticsLabel: AppStrings.overallGoalsProgressSemantics(
        percent: totals.overallPercent,
        saved: formatZarFromCents(totals.totalSavedCents),
        target: formatZarFromCents(totals.totalTargetCents),
      ),
    );
  }
}

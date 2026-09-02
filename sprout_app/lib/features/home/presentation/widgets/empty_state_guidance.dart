import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/goals/presentation/goals_bloc.dart';
import 'overview_quick_actions.dart';

class EmptyStateGuidance extends StatelessWidget {
  const EmptyStateGuidance({
    super.key,
    required this.onOpenAccount,
    required this.onOpenGoal,
    required this.onOpenDeposit,
  });

  final VoidCallback onOpenAccount;
  final VoidCallback onOpenGoal;
  final VoidCallback onOpenDeposit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final stepStyle = Theme.of(context).textTheme.titleMedium;
    final detailStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, goalsState) {
        final hasGoals =
            goalsState is GoalsReady && goalsState.progressList.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      identifier: SemanticsIds.overviewEmptyTitle,
                      header: true,
                      child: Text(
                        AppStrings.overviewEmptyTitle,
                        key: const Key('overview_empty_title'),
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GuidanceStep(
                      stepText: AppStrings.overviewEmptyStep1,
                      detailText: AppStrings.overviewEmptyStep1Detail,
                      icon: Icons.account_balance_wallet_outlined,
                      stepStyle: stepStyle,
                      detailStyle: detailStyle,
                      scheme: scheme,
                    ),
                    const SizedBox(height: 16),
                    GuidanceStep(
                      stepText: AppStrings.overviewEmptyStep2,
                      detailText: AppStrings.overviewEmptyStep2Detail,
                      icon: Icons.flag_outlined,
                      stepStyle: stepStyle,
                      detailStyle: detailStyle,
                      scheme: scheme,
                    ),
                    const SizedBox(height: 16),
                    GuidanceStep(
                      stepText: AppStrings.overviewEmptyStep3,
                      detailText: AppStrings.overviewEmptyStep3Detail,
                      icon: Icons.payments_outlined,
                      stepStyle: stepStyle,
                      detailStyle: detailStyle,
                      scheme: scheme,
                      disabledCaption: hasGoals
                          ? null
                          : AppStrings.overviewEmptyDepositDisabled,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OverviewQuickActions(
              depositIdentifier: SemanticsIds.overviewEmptyDeposit,
              accountIdentifier: SemanticsIds.overviewEmptyNewAccount,
              goalIdentifier: SemanticsIds.overviewEmptyNewGoal,
              onDeposit: onOpenDeposit,
              onNewAccount: onOpenAccount,
              onNewGoal: onOpenGoal,
              depositEnabled: hasGoals,
              depositKey: const Key('overview_empty_deposit'),
              accountKey: const Key('overview_empty_new_account'),
              goalKey: const Key('overview_empty_new_goal'),
            ),
          ],
        );
      },
    );
  }
}

class GuidanceStep extends StatelessWidget {
  const GuidanceStep({
    super.key,
    required this.stepText,
    required this.detailText,
    required this.icon,
    required this.stepStyle,
    required this.detailStyle,
    required this.scheme,
    this.disabledCaption,
  });

  final String stepText;
  final String detailText;
  final IconData icon;
  final TextStyle? stepStyle;
  final TextStyle? detailStyle;
  final ColorScheme scheme;
  final String? disabledCaption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stepText, style: stepStyle),
              const SizedBox(height: 4),
              Text(detailText, style: detailStyle),
              if (disabledCaption != null) ...[
                const SizedBox(height: 4),
                Text(
                  disabledCaption!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

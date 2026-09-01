import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/goals/presentation/goals_bloc.dart';
import 'package:sprout/ui/export.dart';

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
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800);
    final stepStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final detailStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, goalsState) {
        final hasGoals =
            goalsState is GoalsReady && goalsState.progressList.isNotEmpty;

        return Card(
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
                  actionLabel: AppStrings.newAccount,
                  onAction: onOpenAccount,
                  actionKey: const Key('overview_empty_new_account'),
                  actionIdentifier: SemanticsIds.overviewEmptyNewAccount,
                ),
                const SizedBox(height: 16),
                GuidanceStep(
                  stepText: AppStrings.overviewEmptyStep2,
                  detailText: AppStrings.overviewEmptyStep2Detail,
                  icon: Icons.flag_outlined,
                  stepStyle: stepStyle,
                  detailStyle: detailStyle,
                  scheme: scheme,
                  actionLabel: AppStrings.newGoal,
                  onAction: onOpenGoal,
                  enabled: true,
                  actionKey: const Key('overview_empty_new_goal'),
                  actionIdentifier: SemanticsIds.overviewEmptyNewGoal,
                ),
                const SizedBox(height: 16),
                GuidanceStep(
                  stepText: AppStrings.overviewEmptyStep3,
                  detailText: AppStrings.overviewEmptyStep3Detail,
                  icon: Icons.payments_outlined,
                  stepStyle: stepStyle,
                  detailStyle: detailStyle,
                  scheme: scheme,
                  actionLabel: AppStrings.deposit,
                  onAction: onOpenDeposit,
                  enabled: hasGoals,
                  actionKey: const Key('overview_empty_deposit'),
                  actionIdentifier: SemanticsIds.overviewEmptyDeposit,
                  disabledCaption: hasGoals
                      ? null
                      : AppStrings.overviewEmptyDepositDisabled,
                ),
              ],
            ),
          ),
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
    required this.actionLabel,
    required this.onAction,
    this.enabled = true,
    this.actionKey,
    this.actionIdentifier,
    this.disabledCaption,
  });

  final String stepText;
  final String detailText;
  final IconData icon;
  final TextStyle? stepStyle;
  final TextStyle? detailStyle;
  final ColorScheme scheme;
  final String actionLabel;
  final VoidCallback onAction;
  final bool enabled;
  final Key? actionKey;
  final String? actionIdentifier;
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
              const SizedBox(height: 8),
              if (actionIdentifier != null)
                SproutTextButton.icon(
                  key: actionKey,
                  identifier: actionIdentifier!,
                  label: actionLabel,
                  onPressed: enabled ? onAction : null,
                  icon: Icon(Icons.add_rounded, size: 18),
                  labelWidget: Text(actionLabel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                )
              else
                TextButton.icon(
                  key: actionKey,
                  onPressed: enabled ? onAction : null,
                  icon: Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              if (!enabled && disabledCaption != null) ...[
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

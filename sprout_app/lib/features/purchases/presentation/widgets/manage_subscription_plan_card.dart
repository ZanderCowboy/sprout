import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/features/purchases/domain/enums/manage_subscription_period.dart';
import 'package:sprout/features/purchases/domain/enums/manage_subscription_status.dart';
import 'package:sprout/features/purchases/domain/manage_subscription_plan.dart';
import 'package:sprout/features/purchases/domain/manage_subscription_plan_mapper.dart';
import 'package:sprout/features/purchases/presentation/utils/manage_subscription_colors.dart';
import 'package:sprout/features/purchases/presentation/utils/manage_subscription_date_format.dart';

class ManageSubscriptionPlanCard extends StatelessWidget {
  const ManageSubscriptionPlanCard({super.key, required this.plan});

  final ManageSubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final dateLine = ManageSubscriptionPlanMapper.dateLine(
      status: plan.status,
      willRenew: plan.willRenew,
      expirationDate: plan.expirationDate,
      formatDate: formatManageSubscriptionDate,
    );
    final statusLabel = switch (plan.status) {
      ManageSubscriptionStatus.trial => AppStrings.manageSubscriptionStatusTrial,
      ManageSubscriptionStatus.active =>
        AppStrings.manageSubscriptionStatusActive,
    };
    final periodSuffix = switch (plan.period) {
      ManageSubscriptionPeriod.annual => AppStrings.manageSubscriptionPerYear,
      ManageSubscriptionPeriod.monthly => AppStrings.manageSubscriptionPerMonth,
    };
    final renewsCopy = switch (plan.period) {
      ManageSubscriptionPeriod.annual =>
        AppStrings.manageSubscriptionRenewsYearly,
      ManageSubscriptionPeriod.monthly =>
        AppStrings.manageSubscriptionRenewsMonthly,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ManageSubscriptionColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 6,
                child: ColoredBox(color: ManageSubscriptionColors.primary),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ManageSubscriptionColors.primary.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: ManageSubscriptionColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: ManageSubscriptionColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.manageSubscriptionSproutTier
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.05 * 12,
                                      color: ManageSubscriptionColors.primary,
                                    ),
                                  ),
                                  Text(
                                    plan.planName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      height: 28 / 20,
                                      fontWeight: FontWeight.w600,
                                      color: ManageSubscriptionColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              ManageSubscriptionColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: ManageSubscriptionColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.05 * 12,
                                  color: ManageSubscriptionColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (plan.priceString != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          plan.priceString!,
                          style: const TextStyle(
                            fontSize: 36,
                            height: 44 / 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.02 * 36,
                            color: ManageSubscriptionColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          periodSuffix,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            fontWeight: FontWeight.w400,
                            color: ManageSubscriptionColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (dateLine != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          plan.status == ManageSubscriptionStatus.trial
                              ? Icons.event_rounded
                              : Icons.event_repeat_rounded,
                          color: ManageSubscriptionColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateLineText(dateLine: dateLine),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ManageSubscriptionColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.shop_two_outlined,
                              size: 18,
                              color: ManageSubscriptionColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${AppStrings.manageSubscriptionPlayBillingNote} $renewsCopy',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.05 * 12,
                                color:
                                    ManageSubscriptionColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLineText extends StatelessWidget {
  const _DateLineText({required this.dateLine});

  final String dateLine;

  @override
  Widget build(BuildContext context) {
    // Emphasize the trailing date portion after the last space group.
    final parts = dateLine.split(' on ');
    if (parts.length != 2) {
      return Text(
        dateLine,
        style: const TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05 * 12,
          color: ManageSubscriptionColors.onSurfaceVariant,
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05 * 12,
          color: ManageSubscriptionColors.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: '${parts[0]} on '),
          TextSpan(
            text: parts[1],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: ManageSubscriptionColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

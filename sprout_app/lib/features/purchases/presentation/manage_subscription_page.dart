import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/purchases/application/premium_service.dart';
import 'package:sprout/features/purchases/domain/manage_subscription_plan.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';
import 'package:sprout/features/purchases/presentation/utils/manage_subscription_colors.dart';
import 'package:sprout/features/purchases/presentation/utils/play_subscriptions_launcher.dart';
import 'package:sprout/features/purchases/presentation/widgets/manage_subscription_action_row.dart';
import 'package:sprout/features/purchases/presentation/widgets/manage_subscription_context_strip.dart';
import 'package:sprout/features/purchases/presentation/widgets/manage_subscription_footer.dart';
import 'package:sprout/features/purchases/presentation/widgets/manage_subscription_plan_card.dart';

/// Full-screen Manage Subscription (Path B). Opens from Settings → Manage.
class ManageSubscriptionPage extends StatefulWidget {
  const ManageSubscriptionPage({super.key});

  @override
  State<ManageSubscriptionPage> createState() => _ManageSubscriptionPageState();
}

class _ManageSubscriptionPageState extends State<ManageSubscriptionPage> {
  ManageSubscriptionPlan? _plan;
  bool _loading = true;
  bool _restoring = false;
  bool _helping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final premiumService = sl<PremiumService>();
      final canShow = await premiumService.canShowPaywall();
      if (!mounted) return;
      if (!canShow) {
        _failAndPop(AppStrings.subscriptionUpdateFailed);
        return;
      }

      final hasPremium = await PremiumPaywall.hasPremiumAfterRefresh();
      if (!mounted) return;
      if (!hasPremium) {
        _failAndPop(AppStrings.premiumNoLongerActive);
        return;
      }

      final plan = await PremiumPaywall.loadManageSubscriptionPlan();
      if (!mounted) return;
      if (plan == null) {
        _failAndPop(AppStrings.subscriptionUpdateFailed);
        return;
      }

      setState(() {
        _plan = plan;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      _failAndPop(AppStrings.subscriptionUpdateFailed);
    }
  }

  void _failAndPop(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
    if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _openGooglePlay() async {
    try {
      final launched = await PlaySubscriptionsLauncher.openManage();
      if (!mounted) return;
      if (!launched) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
        );
      }
    } on Object {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
      );
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await PremiumPaywall.restorePurchases();
      if (!mounted) return;

      switch (outcome) {
        case RestorePurchasesOutcome.restored:
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(content: Text(AppStrings.premiumUnlocked)),
          );
          final plan = await PremiumPaywall.loadManageSubscriptionPlan();
          if (!mounted) return;
          if (plan != null) {
            setState(() => _plan = plan);
          }
        case RestorePurchasesOutcome.noPremium:
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(content: Text(AppStrings.premiumNoLongerActive)),
          );
          if (context.canPop()) context.pop();
        case RestorePurchasesOutcome.failed:
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
          );
      }
    } on Object {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _needHelp() async {
    if (_helping) return;
    setState(() => _helping = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await PremiumPaywall.presentCustomerCenter();
      if (!mounted) return;

      final hasPremium = await PremiumPaywall.hasPremium();
      if (!mounted) return;
      if (!hasPremium) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.premiumNoLongerActive)),
        );
        if (context.canPop()) context.pop();
        return;
      }

      switch (outcome) {
        case CustomerCenterOutcome.restored:
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(content: Text(AppStrings.premiumUnlocked)),
          );
          final plan = await PremiumPaywall.loadManageSubscriptionPlan();
          if (!mounted) return;
          if (plan != null) setState(() => _plan = plan);
        case CustomerCenterOutcome.restoreFailed:
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
          );
        case CustomerCenterOutcome.dismissed:
          break;
      }
    } on Object {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
      );
    } finally {
      if (mounted) setState(() => _helping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;

    return Scaffold(
      backgroundColor: ManageSubscriptionColors.background,
      appBar: AppBar(
        backgroundColor: ManageSubscriptionColors.background.withValues(
          alpha: 0.8,
        ),
        foregroundColor: ManageSubscriptionColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          AppStrings.manageSubscriptionTitle,
          style: TextStyle(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w600,
            color: ManageSubscriptionColors.onSurface,
          ),
        ),
      ),
      body: _loading || plan == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const ManageSubscriptionContextStrip(),
                const SizedBox(height: 24),
                ManageSubscriptionPlanCard(plan: plan),
                const SizedBox(height: 24),
                Text(
                  AppStrings.manageSubscriptionSettingsSection.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05 * 12,
                    color: ManageSubscriptionColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ManageSubscriptionActionRow(
                  identifier: SemanticsIds.manageSubscriptionGooglePlay,
                  label: AppStrings.manageSubscriptionOnGooglePlay,
                  subtitle: AppStrings.manageSubscriptionOnGooglePlaySubtitle,
                  leadingIcon: Icons.credit_card_rounded,
                  trailingIcon: Icons.open_in_new_rounded,
                  onTap: _openGooglePlay,
                ),
                const SizedBox(height: 8),
                ManageSubscriptionActionRow(
                  identifier: SemanticsIds.manageSubscriptionRestore,
                  label: AppStrings.manageSubscriptionRestore,
                  subtitle: AppStrings.manageSubscriptionRestoreSubtitle,
                  leadingIcon: Icons.history_rounded,
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: _restore,
                  busy: _restoring,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.manageSubscriptionSupportSection.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05 * 12,
                    color: ManageSubscriptionColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ManageSubscriptionActionRow(
                  identifier: SemanticsIds.manageSubscriptionNeedHelp,
                  label: AppStrings.manageSubscriptionNeedHelp,
                  subtitle: AppStrings.manageSubscriptionNeedHelpSubtitle,
                  leadingIcon: Icons.help_outline_rounded,
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: _needHelp,
                  busy: _helping,
                ),
                const SizedBox(height: 24),
                const ManageSubscriptionFooter(),
              ],
            ),
    );
  }
}

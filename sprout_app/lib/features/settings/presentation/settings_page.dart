import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:sprout/bootstrap.dart';
import 'package:sprout/core/core.dart';
import 'package:sprout/core/debug/sprout_debug_lens.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/play_prompts/export.dart';
import 'package:sprout/features/purchases/export.dart';
import 'package:sprout/ui/export.dart';

import 'widgets/settings_finance_section.dart';
import 'widgets/settings_footer.dart';
import 'widgets/settings_nav_row.dart';
import 'widgets/settings_premium_card.dart';
import 'widgets/settings_profile_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showPremiumCard = false;
  bool _loadingPremiumStatus = true;
  bool _hasPremium = false;
  String? _versionLabel;
  bool _debugBubbleVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _loadVersion();
    if (shouldEnableDebugLens()) {
      _loadDebugBubbleVisibility();
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLabel = AppStrings.appVersionLabel(
          info.version,
          info.buildNumber,
        );
      });
    } on Object {
      // Leave the version line hidden when the plugin is unavailable.
    }
  }

  void _loadDebugBubbleVisibility() {
    setState(() {
      _debugBubbleVisible = SproutDebugLens.isBubbleVisible;
    });
  }

  Future<void> _toggleDebugBubble(bool visible) async {
    await SproutDebugLens.setBubbleVisible(visible);
    if (!mounted) return;
    setState(() {
      _debugBubbleVisible = visible;
    });
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final premiumService = sl<PremiumService>();
      final canShow = await premiumService.canShowPaywall();
      if (!mounted) return;
      if (!canShow) {
        setState(() {
          _showPremiumCard = false;
          _loadingPremiumStatus = false;
          _hasPremium = false;
        });
        return;
      }

      final hasPremium = await premiumService.hasPremiumEntitlement();
      if (!mounted) return;
      setState(() {
        _showPremiumCard = true;
        _loadingPremiumStatus = false;
        _hasPremium = hasPremium;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _showPremiumCard = false;
        _loadingPremiumStatus = false;
        _hasPremium = false;
      });
    }
  }

  Future<void> _presentPaywall() async {
    final result = await PremiumPaywall.presentPremiumPaywall();
    if (!mounted) return;

    final premiumService = sl<PremiumService>();
    final hasPremium = await premiumService.hasPremiumEntitlement();
    if (!mounted) return;
    setState(() => _hasPremium = hasPremium);

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case PaywallResult.purchased:
      case PaywallResult.restored:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.premiumUnlocked)),
        );
      case PaywallResult.cancelled:
      case PaywallResult.notPresented:
        break;
      case PaywallResult.error:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
        );
    }
  }

  Future<void> _openManageSubscription() async {
    final premiumService = sl<PremiumService>();

    // Gate: respect the kill switch (Purchases not ready or flag off).
    final canShow = await premiumService.canShowPaywall();
    if (!mounted) return;
    if (!canShow) return;

    // Refresh CustomerInfo to avoid identity/entitlement race after purchase.
    try {
      final hasPremiumNow = await PremiumPaywall.hasPremiumAfterRefresh();
      if (!mounted) return;
      if (!hasPremiumNow) {
        setState(() => _hasPremium = false);
        return;
      }
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
      );
      return;
    }

    await context.push(AppRoute.manageSubscription.path);
    if (!mounted) return;

    // After dismiss, refresh tile (Upgrade if entitlement gone).
    try {
      final hasPremium = await premiumService.hasPremiumEntitlement();
      if (!mounted) return;
      setState(() => _hasPremium = hasPremium);
    } on Object {
      if (!mounted) return;
      setState(() => _hasPremium = false);
    }
  }

  void _openAccount() {
    context.push(AppRoute.account.path);
  }

  void _openTerms() {
    context.push(AppRoute.terms.path);
  }

  void _openPrivacy() {
    context.push(AppRoute.privacy.path);
  }

  void _openDebugLens() {
    SproutDebugLens.show(context);
  }

  /// Hidden App version gesture (#114). Silent no-op when the RC gate is off.
  void _onVersionDebugEntry() {
    if (!shouldEnableDebugLens()) return;
    SproutDebugLens.show(context);
  }

  Future<void> _showDebugUpdatePrompt() async {
    final result = await showPlayUpdatePromptSheet(context);
    if (!mounted) return;
    if (result == PlayUpdatePromptResult.update) {
      await sl<PlayUpdatePromptService>().openStoreListing();
    }
  }

  Future<void> _showDebugReviewPrompt() async {
    final result = await showPlayReviewPromptSheet(context);
    if (!mounted) return;
    if (result == PlayReviewPromptResult.rate) {
      await sl<PlayReviewPromptService>().requestReview(
        forceStoreListing: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthViewState>(
        listenWhen: (previous, current) {
          if (current is! AuthViewSignedIn) return false;
          final message = current.errorMessage;
          if (message == null || message.isEmpty) return false;
          if (previous is AuthViewSignedIn &&
              previous.errorMessage == message) {
            return false;
          }
          return true;
        },
        listener: (context, state) {
          final message = (state as AuthViewSignedIn).errorMessage;
          if (message == null || message.isEmpty) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          final signedIn = state is AuthViewSignedIn ? state : null;
          final user = signedIn?.user;
          final busy = signedIn?.busy ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              const SproutShellHeader(),
              const SizedBox(height: 16),
              SettingsProfileHeader(user: user, onEditProfile: _openAccount),
              if (_showPremiumCard) ...[
                const SizedBox(height: 24),
                SettingsPremiumCard(
                  loading: _loadingPremiumStatus,
                  hasPremium: _hasPremium,
                  onTap: _hasPremium ? _openManageSubscription : _presentPaywall,
                ),
              ],
              const SizedBox(height: 28),
              const SettingsFinanceSection(),
              if (shouldEnableDebugLens()) ...[
                const SizedBox(height: 28),
                Text(
                  AppStrings.debugTools,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsNavRow(
                  identifier: SemanticsIds.settingsDebugLens,
                  label: AppStrings.debugLens,
                  subtitle: AppStrings.debugLensSubtitle,
                  icon: Icons.bug_report_outlined,
                  onTap: _openDebugLens,
                ),
                const SizedBox(height: 8),
                SproutSwitchTile(
                  identifier: SemanticsIds.settingsDebugBubbleToggle,
                  label: AppStrings.debugBubbleVisible,
                  value: _debugBubbleVisible,
                  onChanged: _toggleDebugBubble,
                  title: const Text(AppStrings.debugBubbleVisible),
                  subtitle: const Text(AppStrings.debugBubbleSubtitle),
                ),
                const SizedBox(height: 8),
                SettingsNavRow(
                  identifier: SemanticsIds.settingsDebugShowUpdatePrompt,
                  label: AppStrings.debugShowUpdatePrompt,
                  subtitle: AppStrings.debugShowUpdatePromptSubtitle,
                  icon: Icons.system_update_alt_outlined,
                  onTap: _showDebugUpdatePrompt,
                ),
                const SizedBox(height: 8),
                SettingsNavRow(
                  identifier: SemanticsIds.settingsDebugShowReviewPrompt,
                  label: AppStrings.debugShowReviewPrompt,
                  subtitle: AppStrings.debugShowReviewPromptSubtitle,
                  icon: Icons.star_outline_rounded,
                  onTap: _showDebugReviewPrompt,
                ),
              ],
              const SizedBox(height: 32),
              SettingsFooter(
                versionLabel: _versionLabel,
                busy: busy,
                onSignOut: () => context.read<AuthCubit>().signOut(),
                onPrivacy: _openPrivacy,
                onTerms: _openTerms,
                onVersionDebugEntry: _onVersionDebugEntry,
              ),
              const SizedBox(height: 96),
            ],
          );
        },
      ),
    );
  }
}

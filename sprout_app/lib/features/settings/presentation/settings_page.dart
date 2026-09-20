import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/debug/sprout_debug_lens.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/purchases/presentation/premium_paywall_helper.dart';
import 'package:sprout/ui/export.dart';
import 'package:sprout/bootstrap.dart';
import 'widgets/settings_finance_section.dart';
import 'widgets/settings_footer.dart';
import 'widgets/settings_premium_card.dart';
import 'widgets/settings_profile_header.dart';
import 'widgets/settings_nav_row.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _purchasesReady = false;
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
      final ready = await PremiumPaywall.isPurchasesReady();
      if (!mounted) return;
      if (!ready) {
        setState(() {
          _purchasesReady = false;
          _loadingPremiumStatus = false;
          _hasPremium = false;
        });
        return;
      }

      final hasPremium = await PremiumPaywall.hasPremium();
      if (!mounted) return;
      setState(() {
        _purchasesReady = true;
        _loadingPremiumStatus = false;
        _hasPremium = hasPremium;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _purchasesReady = false;
        _loadingPremiumStatus = false;
        _hasPremium = false;
      });
    }
  }

  Future<void> _presentPaywall() async {
    final result = await PremiumPaywall.presentPremiumPaywall();
    if (!mounted) return;

    final hasPremium = await PremiumPaywall.hasPremium();
    if (!mounted) return;
    setState(() => _hasPremium = hasPremium);

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case PaywallResult.purchased:
      case PaywallResult.restored:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.premiumUnlocked)),
        );
        break;
      case PaywallResult.cancelled:
      case PaywallResult.notPresented:
        break;
      case PaywallResult.error:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
        );
        break;
    }
  }

  Future<void> _presentCustomerCenter() async {
    final hadPremium = _hasPremium;
    final outcome = await PremiumPaywall.presentCustomerCenter();
    if (!mounted) return;

    final hasPremium = await PremiumPaywall.hasPremium();
    if (!mounted) return;
    setState(() => _hasPremium = hasPremium);

    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case CustomerCenterOutcome.restored:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.premiumUnlocked)),
        );
      case CustomerCenterOutcome.restoreFailed:
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.subscriptionUpdateFailed)),
        );
      case CustomerCenterOutcome.dismissed:
        if (hadPremium && !hasPremium) {
          messenger.showSnackBar(
            const SnackBar(content: Text(AppStrings.premiumNoLongerActive)),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthCubit, AuthViewState>(
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
              if (_purchasesReady) ...[
                const SizedBox(height: 24),
                SettingsPremiumCard(
                  loading: _loadingPremiumStatus,
                  hasPremium: _hasPremium,
                  onTap: _hasPremium ? _presentCustomerCenter : _presentPaywall,
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
                  icon: Icons.bug_report_outlined,
                  onTap: _openDebugLens,
                ),
                const SizedBox(height: 8),
                SproutCard(
                  child: SwitchListTile(
                    value: _debugBubbleVisible,
                    onChanged: _toggleDebugBubble,
                    title: Text(AppStrings.debugBubbleVisible),
                    subtitle: Text(AppStrings.debugBubbleSubtitle),
                    secondary: const Icon(Icons.bubble_chart_outlined),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                  identifier: SemanticsIds.settingsDebugBubbleToggle,
                ),
              ],
              const SizedBox(height: 32),
              SettingsFooter(
                versionLabel: _versionLabel,
                busy: busy,
                onSignOut: () => context.read<AuthCubit>().signOut(),
                onPrivacy: _openPrivacy,
                onTerms: _openTerms,
              ),
              const SizedBox(height: 96),
            ],
          );
        },
      ),
    );
  }
}

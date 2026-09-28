import 'package:flutter/material.dart';

import 'package:sprout/bootstrap.dart';
import 'package:sprout/core/core.dart';
import 'package:sprout/core/debug/sprout_debug_lens.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/play_prompts/export.dart';
import 'package:sprout/features/settings/presentation/widgets/settings_nav_row.dart';
import 'package:sprout/ui/export.dart';

/// QA / break-glass tools relocated off main Settings (#114).
///
/// Opened via Settings App version gesture when `environment_page_enabled`
/// allows it (always on in DEV). Hosts soft-prompt previews and, when
/// `debug_lens_enabled` allows, Debug Lens + bubble toggle.
class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key, this.showDebugLensTools});

  /// Override for tests. When null, uses [shouldEnableDebugLens].
  final bool? showDebugLensTools;

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  late final bool _showDebugLensTools;
  bool _debugBubbleVisible = true;

  @override
  void initState() {
    super.initState();
    _showDebugLensTools =
        widget.showDebugLensTools ?? shouldEnableDebugLens();
    if (_showDebugLensTools) {
      _debugBubbleVisible = SproutDebugLens.isBubbleVisible;
    }
  }

  Future<void> _toggleDebugBubble(bool visible) async {
    await SproutDebugLens.setBubbleVisible(visible);
    if (!mounted) return;
    setState(() => _debugBubbleVisible = visible);
  }

  void _openDebugLens() {
    SproutDebugLens.show(context);
  }

  Future<void> _showUpdatePrompt() async {
    final result = await showPlayUpdatePromptSheet(context);
    if (!mounted) return;
    if (result == PlayUpdatePromptResult.update) {
      await sl<PlayUpdatePromptService>().openStoreListing();
    }
  }

  Future<void> _showReviewPrompt() async {
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.environmentPageTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            AppStrings.environmentPageSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (_showDebugLensTools) ...[
            const SizedBox(height: 24),
            Text(
              AppStrings.debugTools,
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
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
          ],
          const SizedBox(height: 24),
          Text(
            AppStrings.environmentPlayPromptsSection,
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SettingsNavRow(
            identifier: SemanticsIds.settingsDebugShowUpdatePrompt,
            label: AppStrings.debugShowUpdatePrompt,
            subtitle: AppStrings.debugShowUpdatePromptSubtitle,
            icon: Icons.system_update_alt_outlined,
            onTap: _showUpdatePrompt,
          ),
          const SizedBox(height: 8),
          SettingsNavRow(
            identifier: SemanticsIds.settingsDebugShowReviewPrompt,
            label: AppStrings.debugShowReviewPrompt,
            subtitle: AppStrings.debugShowReviewPromptSubtitle,
            icon: Icons.star_outline_rounded,
            onTap: _showReviewPrompt,
          ),
        ],
      ),
    );
  }
}

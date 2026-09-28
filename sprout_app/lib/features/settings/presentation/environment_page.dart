import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/play_prompts/export.dart';
import 'package:sprout/features/settings/presentation/widgets/settings_nav_row.dart';

/// QA / break-glass tools relocated off main Settings (#114).
///
/// Opened via Settings App version gesture when `environment_page_enabled`
/// allows it (always on in DEV). Hosts test-only soft-prompt previews.
class EnvironmentPage extends StatelessWidget {
  const EnvironmentPage({super.key});

  Future<void> _showUpdatePrompt(BuildContext context) async {
    final result = await showPlayUpdatePromptSheet(context);
    if (!context.mounted) return;
    if (result == PlayUpdatePromptResult.update) {
      await sl<PlayUpdatePromptService>().openStoreListing();
    }
  }

  Future<void> _showReviewPrompt(BuildContext context) async {
    final result = await showPlayReviewPromptSheet(context);
    if (!context.mounted) return;
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
            onTap: () => _showUpdatePrompt(context),
          ),
          const SizedBox(height: 8),
          SettingsNavRow(
            identifier: SemanticsIds.settingsDebugShowReviewPrompt,
            label: AppStrings.debugShowReviewPrompt,
            subtitle: AppStrings.debugShowReviewPromptSubtitle,
            icon: Icons.star_outline_rounded,
            onTap: () => _showReviewPrompt(context),
          ),
        ],
      ),
    );
  }
}

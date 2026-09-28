import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/core/theme/app_radii.dart';
import 'package:sprout/features/play_prompts/presentation/enums/play_update_prompt_result.dart';
import 'package:sprout/features/play_prompts/presentation/widgets/play_prompt_badge.dart';
import 'package:sprout/ui/export.dart';

export 'package:sprout/features/play_prompts/presentation/enums/play_update_prompt_result.dart';

/// Shows the dark M3 Play update bottom sheet. Returns the user action.
Future<PlayUpdatePromptResult> showPlayUpdatePromptSheet(
  BuildContext context,
) async {
  final result = await showModalBottomSheet<PlayUpdatePromptResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceMuted,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final textTheme = Theme.of(sheetContext).textTheme;
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;

      final pillShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      );

      return Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlayPromptBadge(kind: PlayPromptBadgeKind.update),
            const SizedBox(height: 20),
            Text(
              AppStrings.playUpdateTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.playUpdateBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: SproutFilledButton.icon(
                identifier: SemanticsIds.playUpdateCta,
                label: AppStrings.playUpdateCta,
                icon: const Icon(Icons.download_rounded),
                labelWidget: const Text(AppStrings.playUpdateCta),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.seed,
                  foregroundColor: Colors.white,
                  shape: pillShape,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () =>
                    Navigator.pop(sheetContext, PlayUpdatePromptResult.update),
              ),
            ),
            const SizedBox(height: 8),
            SproutTextButton(
              identifier: SemanticsIds.playUpdateLater,
              label: AppStrings.playUpdateLater,
              onPressed: () =>
                  Navigator.pop(sheetContext, PlayUpdatePromptResult.later),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: AppColors.seed.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppStrings.playUpdateCaption,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? PlayUpdatePromptResult.dismissed;
}

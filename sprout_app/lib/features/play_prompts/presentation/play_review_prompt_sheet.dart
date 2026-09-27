import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/core/theme/app_radii.dart';
import 'package:sprout/features/play_prompts/presentation/enums/play_review_prompt_result.dart';
import 'package:sprout/features/play_prompts/presentation/widgets/play_prompt_badge.dart';
import 'package:sprout/ui/export.dart';

export 'package:sprout/features/play_prompts/presentation/enums/play_review_prompt_result.dart';

/// Shows the dark M3 Play review soft-prompt bottom sheet.
Future<PlayReviewPromptResult> showPlayReviewPromptSheet(
  BuildContext context,
) async {
  final result = await showModalBottomSheet<PlayReviewPromptResult>(
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
            const PlayPromptBadge(kind: PlayPromptBadgeKind.review),
            const SizedBox(height: 20),
            Text(
              AppStrings.playReviewTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.playReviewBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: SproutFilledButton.icon(
                identifier: SemanticsIds.playReviewRate,
                label: AppStrings.playReviewRateCta,
                icon: const Icon(Icons.play_arrow_rounded),
                labelWidget: const Text(AppStrings.playReviewRateCta),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.seed,
                  foregroundColor: Colors.white,
                  shape: pillShape,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () =>
                    Navigator.pop(sheetContext, PlayReviewPromptResult.rate),
              ),
            ),
            const SizedBox(height: 8),
            SproutTextButton(
              identifier: SemanticsIds.playReviewNotNow,
              label: AppStrings.playReviewNotNow,
              onPressed: () =>
                  Navigator.pop(sheetContext, PlayReviewPromptResult.notNow),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.playReviewCaption,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    },
  );
  return result ?? PlayReviewPromptResult.dismissed;
}

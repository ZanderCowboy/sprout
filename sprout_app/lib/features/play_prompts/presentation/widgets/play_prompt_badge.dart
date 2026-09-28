import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_assets.dart';
import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/theme/app_radii.dart';
import 'package:sprout/features/play_prompts/presentation/enums/play_prompt_badge_kind.dart';

export 'package:sprout/features/play_prompts/presentation/enums/play_prompt_badge_kind.dart';

/// Soft eco / celebration badge for Play soft-prompt sheets.
class PlayPromptBadge extends StatelessWidget {
  const PlayPromptBadge({super.key, required this.kind});

  final PlayPromptBadgeKind kind;

  @override
  Widget build(BuildContext context) {
    const teal = AppColors.seed;
    final isReview = kind == PlayPromptBadgeKind.review;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isReview)
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teal.withValues(alpha: 0.18),
              ),
            ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: teal.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: AppAssets.sproutIcon.image(width: 40, height: 40),
          ),
          Positioned(
            right: isReview ? 8 : 10,
            bottom: isReview ? null : 10,
            top: isReview ? 8 : null,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: teal,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceMuted, width: 2),
              ),
              child: Icon(
                isReview ? Icons.add_rounded : Icons.sync_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

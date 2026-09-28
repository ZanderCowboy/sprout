import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/utils/account_identity_labels.dart';

/// Circular profile avatar with optional network image and loading overlay.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.imageUrl,
    this.radius = 48,
    this.loading = false,
    this.onTap,
    this.showEditBadge = false,
    this.semanticsIdentifier = SemanticsIds.settingsAccountAvatar,
  });

  final AuthUser? user;
  final String? imageUrl;
  final double radius;
  final bool loading;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final String semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initial = user == null ? 'A' : accountAvatarInitial(user!);
    final diameter = radius * 2;
    final hasPhoto = imageUrl != null && imageUrl!.isNotEmpty;

    final avatarCore = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.seed.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: hasPhoto ? NetworkImage(imageUrl!) : null,
        onBackgroundImageError: hasPhoto
            ? (Object error, StackTrace? stackTrace) {}
            : null,
        child: hasPhoto
            ? null
            : Text(initial, style: textTheme.headlineMedium),
      ),
    );

    final stacked = SizedBox(
      width: diameter + 16,
      height: diameter + 16,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatarCore,
          if (loading)
            SizedBox(
              width: diameter,
              height: diameter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
          if (showEditBadge)
            Positioned(
              right: 4,
              bottom: 4,
              child: Material(
                color: scheme.surfaceContainerHighest,
                shape: const CircleBorder(),
                child: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: scheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return stacked;

    return Semantics(
      button: true,
      identifier: semanticsIdentifier,
      label: AppStrings.accountSectionProfile,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: loading ? null : onTap,
          child: stacked,
        ),
      ),
    );
  }
}

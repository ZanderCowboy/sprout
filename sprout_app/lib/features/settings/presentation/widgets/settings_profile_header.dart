import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/ui/export.dart';

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({
    super.key,
    required this.user,
    required this.onEditProfile,
  });

  final AuthUser? user;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = user == null ? AppStrings.account : accountTileTitle(user!);
    final subtitle = user == null ? null : accountTileSubtitle(user!);
    final initial = user == null ? 'A' : accountAvatarInitial(user!);

    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.center,
                child: DecoratedBox(
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
                    radius: 48,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Text(initial, style: textTheme.headlineMedium),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  shape: const CircleBorder(),
                  child: SproutIconButton(
                    identifier: SemanticsIds.settingsAccountAvatar,
                    label: AppStrings.accountSectionProfile,
                    onPressed: onEditProfile,
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SproutOutlinedButton.icon(
          identifier: SemanticsIds.settingsAccount,
          label: AppStrings.accountSectionProfile,
          onPressed: onEditProfile,
          icon: Icon(Icons.edit_rounded, color: scheme.primary, size: 18),
          labelWidget: Text(
            AppStrings.accountSectionProfile,
            style: textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.primary),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}

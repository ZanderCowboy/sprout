import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/settings/presentation/widgets/profile_avatar.dart';
import 'package:sprout/ui/export.dart';

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({
    super.key,
    required this.user,
    required this.onEditProfile,
    this.avatarUrl,
    this.avatarLoading = false,
    this.onAvatarTap,
  });

  final AuthUser? user;
  final VoidCallback onEditProfile;
  final String? avatarUrl;
  final bool avatarLoading;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = user == null ? AppStrings.account : accountTileTitle(user!);
    final subtitle = user == null ? null : accountTileSubtitle(user!);

    return Column(
      children: [
        ProfileAvatar(
          user: user,
          imageUrl: avatarUrl,
          radius: 48,
          loading: avatarLoading,
          showEditBadge: user != null && user!.isVerified,
          onTap: user != null && user!.isVerified ? onAvatarTap : null,
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

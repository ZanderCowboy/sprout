import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/theme/app_radii.dart';
import 'package:sprout/ui/export.dart';

class SettingsPremiumCard extends StatelessWidget {
  const SettingsPremiumCard({
    super.key,
    required this.loading,
    required this.hasPremium,
    required this.onTap,
  });

  final bool loading;
  final bool hasPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = AppColors.seed;
    final subtitle = loading
        ? AppStrings.checkingSubscription
        : hasPremium
        ? AppStrings.premiumStatusActive
        : AppStrings.unlockPremium;
    final actionLabel = hasPremium ? AppStrings.manage : AppStrings.upgrade;
    final radius = BorderRadius.circular(AppRadii.card);
    final tileBase = Color.alphaBlend(
      color.withValues(alpha: 0.06),
      Color.alphaBlend(
        AppColors.surfaceMuted.withValues(alpha: 0.42),
        AppColors.surfaceDeep,
      ),
    );

    return Material(
      color: tileBase,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: SproutListTile(
                  identifier: SemanticsIds.settingsPremium,
                  label: AppStrings.sproutPremium,
                  leading: SproutGlowIcon(
                    icon: Icons.workspace_premium_rounded,
                    color: color,
                  ),
                  title: Text(
                    AppStrings.sproutPremium,
                    style: textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    subtitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: hasPremium && !loading ? 1.2 : null,
                    ),
                  ),
                  trailing: Text(
                    actionLabel,
                    style: textTheme.labelLarge?.copyWith(color: color),
                  ),
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

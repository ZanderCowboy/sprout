import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/theme/app_radii.dart';
import 'package:sprout/ui/export.dart';

class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.identifier,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String identifier;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadii.card);
    final tileBase = Color.alphaBlend(
      AppColors.surfaceMuted.withValues(alpha: 0.42),
      AppColors.surfaceDeep,
    );

    return Material(
      color: tileBase,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: SproutListTile(
        identifier: identifier,
        label: label,
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(label),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

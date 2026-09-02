import 'package:flutter/material.dart';

import 'package:sprout/core/theme/app_radii.dart';

import '_semantic.dart';
import 'sprout_glow_icon.dart';

/// Icon + label on a rounded surface (Overview quick-action row).
class SproutQuickActionTile extends StatelessWidget {
  const SproutQuickActionTile({
    super.key,
    required this.identifier,
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.iconColor,
  });

  final String identifier;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = enabled
        ? (iconColor ?? scheme.primary)
        : scheme.onSurfaceVariant;
    final labelStyle = enabled
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant);

    return semanticButton(
      identifier: identifier,
      label: label,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SproutGlowIcon(icon: icon, color: accent),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

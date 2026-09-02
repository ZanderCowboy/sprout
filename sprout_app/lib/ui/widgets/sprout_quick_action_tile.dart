import 'package:flutter/material.dart';

import 'package:sprout/core/theme/app_radii.dart';

import '_semantic.dart';

/// Icon + label on a rounded surface (Overview quick-action row).
class SproutQuickActionTile extends StatelessWidget {
  const SproutQuickActionTile({
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

    return semanticButton(
      identifier: identifier,
      label: label,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: scheme.primary, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

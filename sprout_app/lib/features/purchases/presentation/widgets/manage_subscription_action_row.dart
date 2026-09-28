import 'package:flutter/material.dart';

import 'package:sprout/features/purchases/presentation/utils/manage_subscription_colors.dart';
import 'package:sprout/ui/export.dart';

class ManageSubscriptionActionRow extends StatelessWidget {
  const ManageSubscriptionActionRow({
    super.key,
    required this.identifier,
    required this.label,
    required this.subtitle,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.onTap,
    this.busy = false,
  });

  final String identifier;
  final String label;
  final String subtitle;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ManageSubscriptionColors.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: SproutListTile(
          identifier: identifier,
          label: label,
          enabled: !busy,
          onTap: busy ? null : onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ManageSubscriptionColors.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              leadingIcon,
              color: ManageSubscriptionColors.primary,
              size: 22,
            ),
          ),
          title: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w600,
              color: ManageSubscriptionColors.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.05 * 12,
              color: ManageSubscriptionColors.onSurfaceVariant,
            ),
          ),
          trailing: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  trailingIcon,
                  color: ManageSubscriptionColors.onSurfaceVariant,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

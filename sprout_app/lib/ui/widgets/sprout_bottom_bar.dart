import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/theme/app_radii.dart';

import '_semantic.dart';
import 'enticing_add_button.dart';

/// One signed-in tab destination. The host owns selection and navigation.
class SproutBottomBarDestination {
  const SproutBottomBarDestination({
    required this.identifier,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String identifier;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// Lush Growth chrome: destinations as data. Host overlays the center Add.
class SproutBottomBar extends StatelessWidget {
  const SproutBottomBar({
    super.key,
    required this.destinations,
  });

  final List<SproutBottomBarDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final addIndex = destinations.length ~/ 2;
    final tabRow = <Widget>[
      for (var i = 0; i < destinations.length; i++) ...[
        if (i == addIndex) const SizedBox(width: EnticingAddButton.size),
        Expanded(child: _SproutBottomBarItem(destination: destinations[i])),
      ],
    ];

    return Material(
      elevation: 0,
      color: AppColors.surfaceBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: tabRow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SproutBottomBarItem extends StatelessWidget {
  const _SproutBottomBarItem({required this.destination});

  final SproutBottomBarDestination destination;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    final icon = destination.selected
        ? Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navSelected,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navSelected.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              destination.selectedIcon,
              color: AppColors.surfaceDeep,
              size: 22,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Icon(destination.icon, color: muted, size: 26),
          );

    return semanticButton(
      identifier: destination.identifier,
      label: destination.label,
      selected: destination.selected,
      child: InkWell(
        onTap: destination.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: destination.selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: destination.selected ? AppColors.navSelected : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

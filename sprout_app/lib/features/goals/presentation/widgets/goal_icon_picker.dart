import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

/// Curated Material rounded icons for goals (create + edit).
class GoalIconPicker extends StatelessWidget {
  const GoalIconPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.accent,
  });

  final IconData selected;
  final ValueChanged<IconData> onSelected;
  final Color accent;

  static const defaultIcon = Icons.savings_rounded;

  static const icons = <IconData>[
    Icons.savings_rounded,
    Icons.laptop_mac_rounded,
    Icons.flight_takeoff_rounded,
    Icons.health_and_safety_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.school_rounded,
    Icons.card_giftcard_rounded,
    Icons.beach_access_rounded,
    Icons.restaurant_rounded,
    Icons.pets_rounded,
    Icons.fitness_center_rounded,
    Icons.phone_iphone_rounded,
    Icons.shopping_bag_rounded,
    Icons.celebration_rounded,
    Icons.weekend_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < icons.length; i++)
          Semantics(
            identifier: SemanticsIds.goalIconAt(i + 1),
            button: true,
            label: AppStrings.iconNumber(i + 1),
            selected: selected == icons[i],
            child: InkResponse(
              onTap: () => onSelected(icons[i]),
              radius: 28,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected == icons[i]
                      ? accent
                      : scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  icons[i],
                  color: selected == icons[i]
                      ? Colors.white
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Maps persisted code points back to a const [IconData] from [GoalIconPicker.icons].
///
/// Release builds tree-shake icon fonts and reject `IconData(...)` constructed
/// from runtime values.
IconData goalIconFromStored({int? codePoint}) {
  if (codePoint == null) return GoalIconPicker.defaultIcon;
  for (final icon in GoalIconPicker.icons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return GoalIconPicker.defaultIcon;
}

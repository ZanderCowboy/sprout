import 'package:flutter/material.dart';

/// Icon grid used for budget groups (inline card and full add sheet).
class BudgetGroupIconPicker extends StatelessWidget {
  const BudgetGroupIconPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.accent,
  });

  final IconData selected;
  final ValueChanged<IconData> onSelected;
  final Color accent;

  static const icons = <IconData>[
    Icons.category_rounded,
    Icons.trending_up_rounded,
    Icons.payments_outlined,
    Icons.work_rounded,
    Icons.home_rounded,
    Icons.electric_bolt_rounded,
    Icons.water_drop_rounded,
    Icons.wifi_rounded,
    Icons.directions_car_rounded,
    Icons.local_grocery_store_rounded,
    Icons.school_rounded,
    Icons.local_cafe_rounded,
    Icons.restaurant_rounded,
    Icons.fitness_center_rounded,
    Icons.movie_rounded,
    Icons.shopping_bag_rounded,
    Icons.card_giftcard_rounded,
    Icons.pets_rounded,
    Icons.health_and_safety_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final i in icons)
          InkResponse(
            onTap: () => onSelected(i),
            radius: 28,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected == i ? accent : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                i,
                color: selected == i ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

String budgetGroupColorToHex(Color c) {
  final v = c.toARGB32();
  final hex = v.toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#$hex';
}

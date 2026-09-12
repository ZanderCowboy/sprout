import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

/// Palette swatches used on create/edit sheets and the first-run wizard.
class SproutColorSwatches extends StatelessWidget {
  const SproutColorSwatches({
    super.key,
    required this.selectedArgb,
    required this.onSelected,
  });

  final int selectedArgb;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < AppColors.cardPalette.length; i++)
          Semantics(
            identifier: SemanticsIds.colorSwatchAt(i + 1),
            button: true,
            label: AppStrings.colorNumber(i + 1),
            selected: selectedArgb == AppColors.cardPalette[i].toARGB32(),
            child: GestureDetector(
              onTap: () => onSelected(AppColors.cardPalette[i].toARGB32()),
              child: CircleAvatar(
                backgroundColor: AppColors.cardPalette[i],
                child: selectedArgb == AppColors.cardPalette[i].toARGB32()
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

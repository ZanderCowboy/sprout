import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sprout/core/core.dart';

import '_semantic.dart';

/// Center nav action: solid teal disc, dark plus, haptic tap.
class EnticingAddButton extends StatelessWidget {
  const EnticingAddButton({
    super.key,
    required this.onPressed,
    this.identifier = SemanticsIds.shellAdd,
  });

  static const double size = 56;

  final VoidCallback onPressed;
  final String identifier;

  void _onTap() {
    HapticFeedback.lightImpact();
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.actionAdd,
      child: semanticButton(
        identifier: identifier,
        label: AppStrings.actionAdd,
        child: GestureDetector(
          onTap: _onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.seed,
              boxShadow: [
                BoxShadow(
                  color: AppColors.seed.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.surfaceDeep,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

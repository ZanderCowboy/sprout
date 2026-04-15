import 'package:flutter/material.dart';

import 'package:sprout/core/constants/constants.dart';

/// Primary deposit action for entity detail screens — full-width, high contrast.
class DetailDepositCallout extends StatelessWidget {
  const DetailDepositCallout({
    super.key,
    required this.accentColor,
    required this.caption,
    required this.onPressed,
  });

  final Color accentColor;
  final String caption;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(20);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          splashColor: accentColor.withValues(alpha: 0.2),
          highlightColor: accentColor.withValues(alpha: 0.08),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.5),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.28),
                  scheme.surfaceContainerHigh,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.accentLime,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentLime.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        Icons.add_card_rounded,
                        color: AppColors.surfaceDeep,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.addDeposit,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                                color: scheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          caption,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                    size: 28,
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

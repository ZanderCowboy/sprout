import 'package:flutter/material.dart';

import 'package:sprout/core/theme/app_radii.dart';

import '_semantic.dart';

class ColoredEntityCard extends StatelessWidget {
  const ColoredEntityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.trailing,
    this.amount,
    this.progress,
    this.progressLabel,
    this.glow = false,
    this.identifier,
    this.semanticsLabel,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? amount;
  final double? progress;
  final String? progressLabel;
  final bool glow;
  final String? identifier;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress?.clamp(0.0, 1.0);
    final showAmountInColumn =
        amount != null && (trailing != null || progress != null);
    final Widget? end =
        trailing ??
        (clamped != null
            ? _ProgressRing(
                value: clamped,
                label: progressLabel ?? '${(clamped * 100).round()}%',
                color: color,
              )
            : amount != null
            ? Text(
                amount!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              )
            : null);

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (showAmountInColumn) ...[
                      const SizedBox(height: 6),
                      Text(
                        amount!,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (end != null) ...[const SizedBox(width: 12), end],
            ],
          ),
        ),
      ),
    );

    final wrapped = glow
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: card,
          )
        : card;

    if (identifier != null) {
      return semanticButton(
        identifier: identifier!,
        label: semanticsLabel ?? title,
        child: wrapped,
      );
    }

    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? title,
      child: wrapped,
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.value,
    required this.label,
    required this.color,
  });

  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 5,
            backgroundColor: scheme.surfaceContainerHighest.withValues(
              alpha: 0.8,
            ),
            color: color,
          ),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

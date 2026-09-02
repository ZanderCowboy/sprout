import 'package:flutter/material.dart';

class SproutProgressCard extends StatelessWidget {
  const SproutProgressCard({
    super.key,
    required this.title,
    required this.percent,
    required this.savedCaption,
    required this.savedValue,
    required this.targetCaption,
    required this.targetValue,
    this.subtitle,
    this.detail,
    this.onTap,
    this.identifier,
    this.semanticsLabel,
    this.accentColor,
  });

  final String title;
  final int percent;
  final String savedCaption;
  final String savedValue;
  final String targetCaption;
  final String targetValue;
  final String? subtitle;
  final String? detail;
  final VoidCallback? onTap;
  final String? identifier;
  final String? semanticsLabel;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.primary;
    final progress = (percent / 100).clamp(0.0, 1.0);

    final card = Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: accent, width: 6)),
                ),
                child: _content(context, scheme, accent, progress),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: accent, width: 6)),
              ),
              child: _content(context, scheme, accent, progress),
            ),
    );

    return Semantics(
      identifier: identifier,
      button: onTap != null,
      label: semanticsLabel ?? title,
      child: card,
    );
  }

  Widget _content(
    BuildContext context,
    ColorScheme scheme,
    Color accent,
    double progress,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: muted),
                    ],
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            color: accent,
            backgroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(savedCaption, style: muted),
                    const SizedBox(height: 4),
                    Text(savedValue, style: textTheme.titleSmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(targetCaption, style: muted),
                  const SizedBox(height: 4),
                  Text(targetValue, style: textTheme.titleSmall),
                ],
              ),
            ],
          ),
          if (detail != null || onTap != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (detail != null)
                  Expanded(
                    child: Text(
                      detail!,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

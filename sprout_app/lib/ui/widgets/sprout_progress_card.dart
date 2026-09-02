import 'package:flutter/material.dart';

class SproutProgressCard extends StatelessWidget {
  const SproutProgressCard({
    super.key,
    required this.title,
    required this.percent,
    required this.savedLabel,
    required this.targetLabel,
    this.detail,
    this.onTap,
    this.identifier,
    this.semanticsLabel,
  });

  final String title;
  final int percent;
  final String savedLabel;
  final String targetLabel;
  final String? detail;
  final VoidCallback? onTap;
  final String? identifier;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (percent / 100).clamp(0.0, 1.0);

    final card = Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      clipBehavior: onTap != null ? Clip.antiAlias : Clip.none,
      child: onTap != null
          ? InkWell(onTap: onTap, child: _content(context, scheme, progress))
          : _content(context, scheme, progress),
    );

    return Semantics(
      identifier: identifier,
      button: onTap != null,
      label: semanticsLabel ?? title,
      child: card,
    );
  }

  Widget _content(BuildContext context, ColorScheme scheme, double progress) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleSmall)),
              Text(
                '$percent%',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            color: scheme.primary,
            backgroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(savedLabel, style: textTheme.titleSmall)),
              Text(
                targetLabel,
                style: textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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

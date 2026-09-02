import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/theme/app_radii.dart';

import '_semantic.dart';

enum _EntityCardVariant { account, goal }

class ColoredEntityCard extends StatelessWidget {
  const ColoredEntityCard._({
    super.key,
    required _EntityCardVariant variant,
    required this.title,
    required this.color,
    this.kind,
    this.subtitle,
    this.amount,
    this.changeLabel,
    this.onTap,
    this.trailing,
    this.progress,
    this.progressLabel,
    this.identifier,
    this.semanticsLabel,
  }) : _variant = variant;

  /// Tinted account card: color dot + kind, name, [amount], optional change/footer.
  factory ColoredEntityCard.account({
    Key? key,
    required String name,
    required String kind,
    required String amount,
    required Color color,
    String? changeLabel,
    String? footer,
    VoidCallback? onTap,
    String? identifier,
    String? semanticsLabel,
  }) {
    return ColoredEntityCard._(
      key: key,
      variant: _EntityCardVariant.account,
      title: name,
      kind: kind,
      amount: amount,
      changeLabel: changeLabel,
      subtitle: footer,
      color: color,
      onTap: onTap,
      identifier: identifier,
      semanticsLabel: semanticsLabel,
    );
  }

  /// Goal card: 6px stripe, title + subtitle, trailing ring or [progress].
  factory ColoredEntityCard.goal({
    Key? key,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    double? progress,
    String? progressLabel,
    VoidCallback? onTap,
    String? identifier,
    String? semanticsLabel,
  }) {
    return ColoredEntityCard._(
      key: key,
      variant: _EntityCardVariant.goal,
      title: title,
      subtitle: subtitle,
      color: color,
      trailing: trailing,
      progress: progress,
      progressLabel: progressLabel,
      onTap: onTap,
      identifier: identifier,
      semanticsLabel: semanticsLabel,
    );
  }

  final _EntityCardVariant _variant;
  final String title;
  final String? kind;
  final String? subtitle;
  final String? amount;
  final String? changeLabel;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double? progress;
  final String? progressLabel;
  final String? identifier;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final card = _variant == _EntityCardVariant.account
        ? _AccountCardBody(
            title: title,
            kind: kind ?? '',
            amount: amount ?? '',
            color: color,
            changeLabel: changeLabel,
            footer: subtitle,
            onTap: onTap,
          )
        : _GoalCardBody(
            title: title,
            subtitle: subtitle,
            color: color,
            trailing: trailing,
            progress: progress,
            progressLabel: progressLabel,
            onTap: onTap,
          );

    if (identifier != null) {
      return semanticButton(
        identifier: identifier!,
        label: semanticsLabel ?? title,
        child: card,
      );
    }

    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? title,
      child: card,
    );
  }
}

class _AccountCardBody extends StatelessWidget {
  const _AccountCardBody({
    required this.title,
    required this.kind,
    required this.amount,
    required this.color,
    required this.onTap,
    this.changeLabel,
    this.footer,
  });

  final String title;
  final String kind;
  final String amount;
  final Color color;
  final String? changeLabel;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tileBase = Color.alphaBlend(
      color.withValues(alpha: 0.06),
      Color.alphaBlend(
        AppColors.surfaceMuted.withValues(alpha: 0.42),
        AppColors.surfaceDeep,
      ),
    );
    final radius = BorderRadius.circular(AppRadii.card);
    final muted = textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      letterSpacing: 1.3,
    );

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: tileBase,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: color.withValues(alpha: 0.16)),
              gradient: RadialGradient(
                center: const Alignment(0.92, -1.05),
                radius: 1.2,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.07),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.48, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kind.toUpperCase(),
                          style: muted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  if (changeLabel != null && changeLabel!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ChangePill(label: changeLabel!, color: color),
                  ],
                  if (footer != null && footer!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      footer!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.12),
          AppColors.surfaceDeep,
        ),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _GoalCardBody extends StatelessWidget {
  const _GoalCardBody({
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.progress,
    this.progressLabel,
  });

  final String title;
  final String? subtitle;
  final Color color;
  final Widget? trailing;
  final double? progress;
  final String? progressLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress?.clamp(0.0, 1.0);
    final Widget? end =
        trailing ??
        (clamped != null
            ? _ProgressRing(
                value: clamped,
                label: progressLabel ?? '${(clamped * 100).round()}%',
                color: color,
              )
            : null);

    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (end != null) ...[const SizedBox(width: 12), end],
              ],
            ),
          ),
        ),
      ),
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

import 'package:flutter/material.dart';

import '_semantic.dart';

class ColoredEntityCard extends StatelessWidget {
  const ColoredEntityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.trailing,
    this.identifier,
    this.semanticsLabel,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? identifier;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              ?trailing,
            ],
          ),
        ),
      ),
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

import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

import '_semantic.dart';

/// Tab-root chrome: optional leading, centered Sprout wordmark, optional trailing.
class SproutShellHeader extends StatelessWidget {
  const SproutShellHeader({
    super.key,
    this.leading,
    this.trailing,
    this.identifier = SemanticsIds.shellHeader,
  });

  final Widget? leading;
  final Widget? trailing;
  final String identifier;

  @override
  Widget build(BuildContext context) {
    final wordmark = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.eco_rounded, color: AppColors.seed, size: 22),
        const SizedBox(width: 6),
        Text(
          AppStrings.appTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );

    return semanticHeader(
      identifier: identifier,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              wordmark,
              Row(
                children: [
                  leading ?? const SizedBox(width: 48),
                  const Spacer(),
                  trailing ?? const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

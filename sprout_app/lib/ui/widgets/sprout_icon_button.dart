import 'package:flutter/material.dart';

import '_semantic.dart';

class SproutIconButton extends StatelessWidget {
  const SproutIconButton({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  final String identifier;
  final String label;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return semanticButton(
      identifier: identifier,
      label: label,
      child: IconButton(
        tooltip: tooltip ?? label,
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}

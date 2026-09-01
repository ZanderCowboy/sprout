import 'package:flutter/material.dart';

import '_semantic.dart';

class SproutTextButton extends StatelessWidget {
  const SproutTextButton({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
    this.style,
    this.child,
  }) : icon = null,
       labelWidget = null,
       _iconButton = false;

  const SproutTextButton.icon({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.labelWidget,
    this.style,
  }) : child = null,
       _iconButton = true;

  final String identifier;
  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? child;
  final Widget? icon;
  final Widget? labelWidget;
  final bool _iconButton;

  @override
  Widget build(BuildContext context) {
    final Widget button = _iconButton
        ? TextButton.icon(
            onPressed: onPressed,
            style: style,
            icon: icon!,
            label: labelWidget!,
          )
        : TextButton(
            onPressed: onPressed,
            style: style,
            child: child ?? Text(label),
          );

    return semanticButton(identifier: identifier, label: label, child: button);
  }
}

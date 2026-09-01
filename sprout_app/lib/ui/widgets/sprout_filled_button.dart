import 'package:flutter/material.dart';

import '_semantic.dart';

class SproutFilledButton extends StatelessWidget {
  const SproutFilledButton({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
    this.style,
    this.child,
  }) : icon = null,
       labelWidget = null,
       _tonal = false,
       _iconButton = false;

  const SproutFilledButton.icon({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.labelWidget,
    this.style,
  }) : child = null,
       _tonal = false,
       _iconButton = true;

  const SproutFilledButton.tonal({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
    this.style,
    this.child,
  }) : icon = null,
       labelWidget = null,
       _tonal = true,
       _iconButton = false;

  const SproutFilledButton.tonalIcon({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.labelWidget,
    this.style,
  }) : child = null,
       _tonal = true,
       _iconButton = true;

  final String identifier;
  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? child;
  final Widget? icon;
  final Widget? labelWidget;
  final bool _tonal;
  final bool _iconButton;

  @override
  Widget build(BuildContext context) {
    final Widget button;
    if (_iconButton && _tonal) {
      button = FilledButton.tonalIcon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: labelWidget!,
      );
    } else if (_iconButton) {
      button = FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: labelWidget!,
      );
    } else if (_tonal) {
      button = FilledButton.tonal(
        onPressed: onPressed,
        style: style,
        child: child ?? Text(label),
      );
    } else {
      button = FilledButton(
        onPressed: onPressed,
        style: style,
        child: child ?? Text(label),
      );
    }

    return semanticButton(identifier: identifier, label: label, child: button);
  }
}

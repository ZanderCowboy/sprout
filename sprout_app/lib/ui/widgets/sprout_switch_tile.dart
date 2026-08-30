import 'package:flutter/material.dart';

import '_semantic.dart';

class SproutSwitchTile extends StatelessWidget {
  const SproutSwitchTile({
    super.key,
    required this.identifier,
    required this.label,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.contentPadding,
  });

  final String identifier;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return semanticButton(
      identifier: identifier,
      label: label,
      child: SwitchListTile.adaptive(
        contentPadding: contentPadding,
        value: value,
        onChanged: onChanged,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

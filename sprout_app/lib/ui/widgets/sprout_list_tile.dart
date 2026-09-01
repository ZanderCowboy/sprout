import 'package:flutter/material.dart';

import '_semantic.dart';

class SproutListTile extends StatelessWidget {
  const SproutListTile({
    super.key,
    required this.identifier,
    required this.label,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.enabled,
    this.onTap,
  });

  final String identifier;
  final String label;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool? enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return semanticButton(
      identifier: identifier,
      label: label,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        enabled: enabled ?? true,
        onTap: onTap,
      ),
    );
  }
}

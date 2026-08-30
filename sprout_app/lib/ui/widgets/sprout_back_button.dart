import 'package:flutter/material.dart';

import '_semantic.dart';

class SproutBackButton extends StatelessWidget {
  const SproutBackButton({
    super.key,
    required this.identifier,
    required this.label,
    required this.onPressed,
  });

  final String identifier;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return semanticButton(
      identifier: identifier,
      label: label,
      child: BackButton(onPressed: onPressed),
    );
  }
}

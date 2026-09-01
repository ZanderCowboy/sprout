import 'package:flutter/material.dart';

import '_semantic.dart';

class SproutDropdownField<T> extends StatelessWidget {
  const SproutDropdownField({
    super.key,
    required this.identifier,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.decoration,
  });

  final String identifier;
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return semanticButton(
      identifier: identifier,
      label: label,
      child: DropdownButtonFormField<T>(
        value: value, // ignore: deprecated_member_use
        decoration: decoration,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '_semantic.dart';

class SproutTextField extends StatelessWidget {
  const SproutTextField({
    super.key,
    required this.identifier,
    required this.controller,
    this.fieldKey,
    this.decoration,
    this.enabled,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.minLines,
    this.maxLines = 1,
  });

  final String identifier;
  final TextEditingController controller;
  final Key? fieldKey;
  final InputDecoration? decoration;
  final bool? enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return semanticTextField(
      identifier: identifier,
      child: TextField(
        key: fieldKey,
        controller: controller,
        decoration: decoration,
        enabled: enabled,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        minLines: minLines,
        maxLines: maxLines,
      ),
    );
  }
}

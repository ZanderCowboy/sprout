import 'package:flutter/material.dart';

Widget semanticButton({
  required String identifier,
  required String label,
  required Widget child,
  bool selected = false,
}) => Semantics(
  identifier: identifier,
  button: true,
  label: label,
  selected: selected,
  child: child,
);

Widget semanticTextField({required String identifier, required Widget child}) =>
    Semantics(identifier: identifier, textField: true, child: child);

Widget semanticHeader({required String identifier, required Widget child}) =>
    Semantics(identifier: identifier, header: true, child: child);

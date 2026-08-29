import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/features/budget/presentation/widgets/budget_group_icon_picker.dart';

void main() {
  test('returns category when nothing is stored', () {
    expect(budgetGroupIconFromStored(), Icons.category_rounded);
  });

  test('resolves a picker icon by code point without constructing IconData', () {
    const stored = Icons.pets_rounded;
    expect(
      budgetGroupIconFromStored(
        codePoint: stored.codePoint,
        fontFamily: stored.fontFamily,
      ),
      stored,
    );
  });

  test('falls back when the code point is unknown', () {
    expect(
      budgetGroupIconFromStored(codePoint: 1, fontFamily: 'MaterialIcons'),
      Icons.category_rounded,
    );
  });
}

import 'package:intl/intl.dart';

/// [amountCents] minor units (ZAR cents).
String formatZarFromCents(int amountCents) {
  final major = amountCents / 100;
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: 'R',
    decimalDigits: 2,
  ).format(major);
}

/// Parses user input like "1234.56" or "1 234,56" to cents; null if invalid.
int? parseZarToCents(String input) {
  final normalized = input.replaceAll(' ', '').replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}

/// Live validation for a strictly positive ZAR amount (e.g. goal target).
enum PositiveZarFieldState {
  empty,
  incomplete,
  invalid,
  negative,
  notPositive,
  ok,
}

PositiveZarFieldState classifyPositiveZarField(String input) {
  final t = input.trim();
  if (t.isEmpty) return PositiveZarFieldState.empty;
  final normalized = t.replaceAll(' ', '').replaceAll(',', '.');
  if (normalized == '-' ||
      normalized == '-.' ||
      normalized == '+' ||
      normalized == '+.') {
    return PositiveZarFieldState.incomplete;
  }
  final value = double.tryParse(normalized);
  if (value == null) return PositiveZarFieldState.invalid;
  if (value < 0) return PositiveZarFieldState.negative;
  final cents = (value * 100).round();
  if (cents <= 0) return PositiveZarFieldState.notPositive;
  return PositiveZarFieldState.ok;
}

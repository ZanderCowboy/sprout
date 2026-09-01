import 'package:flutter/material.dart';

class AccountValueRow extends StatelessWidget {
  const AccountValueRow({
    super.key,
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final valueStyle =
        (isEmphasis ? Theme.of(context).textTheme.titleMedium : style)
            ?.copyWith(
              fontWeight: isEmphasis ? FontWeight.w900 : FontWeight.w700,
            );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}

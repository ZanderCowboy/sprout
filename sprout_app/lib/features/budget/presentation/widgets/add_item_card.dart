import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class AddItemCard extends StatelessWidget {
  const AddItemCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: scheme.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                AppStrings.addItem,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

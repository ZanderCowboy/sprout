import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

class NameColorFormSheet extends StatelessWidget {
  const NameColorFormSheet({
    super.key,
    required this.title,
    required this.nameLabel,
    required this.nameController,
    required this.nameErrorText,
    required this.colorArgb,
    required this.onColorSelected,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.primaryActionEnabled,
    this.body,
  });

  final String title;
  final String nameLabel;
  final TextEditingController nameController;
  final String? nameErrorText;

  final int colorArgb;
  final ValueChanged<int> onColorSelected;

  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final bool primaryActionEnabled;

  /// Optional extra UI between name field and color picker (e.g. goal target).
  final List<Widget>? body;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: nameLabel,
              errorText: nameErrorText,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          if (body != null) ...body!,
          const SizedBox(height: 16),
          Text(
            'Color',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < AppColors.cardPalette.length; i++)
                GestureDetector(
                  onTap: () => onColorSelected(AppColors.cardPalette[i].toARGB32()),
                  child: CircleAvatar(
                    backgroundColor: AppColors.cardPalette[i],
                    child: colorArgb == AppColors.cardPalette[i].toARGB32()
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: primaryActionEnabled ? onPrimaryAction : null,
            child: Text(primaryActionLabel),
          ),
        ],
      ),
    );
  }
}


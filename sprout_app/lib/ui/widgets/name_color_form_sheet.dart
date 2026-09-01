import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';

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
    this.nameFieldKey,
    this.nameFieldIdentifier,
    this.primaryActionIdentifier,
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

  /// Optional key for the name text field (for testing).
  final Key? nameFieldKey;

  /// Optional semantics identifier for the name text field (for Maestro).
  final String? nameFieldIdentifier;

  /// Optional semantics identifier for the primary save button.
  final String? primaryActionIdentifier;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;
    final nameField = nameFieldIdentifier == null
        ? TextField(
            key: nameFieldKey,
            controller: nameController,
            decoration: InputDecoration(
              labelText: nameLabel,
              errorText: nameErrorText,
            ),
            textCapitalization: TextCapitalization.words,
          )
        : SproutTextField(
            identifier: nameFieldIdentifier!,
            fieldKey: nameFieldKey,
            controller: nameController,
            decoration: InputDecoration(
              labelText: nameLabel,
              errorText: nameErrorText,
            ),
            textCapitalization: TextCapitalization.words,
          );

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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          nameField,
          if (body != null) ...body!,
          const SizedBox(height: 16),
          Text(AppStrings.color, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < AppColors.cardPalette.length; i++)
                Semantics(
                  identifier: SemanticsIds.colorSwatchAt(i + 1),
                  button: true,
                  label: AppStrings.colorNumber(i + 1),
                  selected: colorArgb == AppColors.cardPalette[i].toARGB32(),
                  child: GestureDetector(
                    onTap: () =>
                        onColorSelected(AppColors.cardPalette[i].toARGB32()),
                    child: CircleAvatar(
                      backgroundColor: AppColors.cardPalette[i],
                      child: colorArgb == AppColors.cardPalette[i].toARGB32()
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SproutFilledButton(
            identifier: primaryActionIdentifier ?? SemanticsIds.formSave,
            label: primaryActionLabel,
            onPressed: primaryActionEnabled ? onPrimaryAction : null,
          ),
        ],
      ),
    );
  }
}

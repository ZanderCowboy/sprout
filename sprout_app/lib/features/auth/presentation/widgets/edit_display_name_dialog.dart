import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/ui/export.dart';

class EditDisplayNameDialog extends StatefulWidget {
  const EditDisplayNameDialog({super.key, required this.initialName});

  final String initialName;

  @override
  State<EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<EditDisplayNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.editDisplayName),
      content: SproutTextField(
        identifier: SemanticsIds.accountEditNameField,
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: AppStrings.displayName),
        onSubmitted: (_) => _submit(),
      ),
      actions: SproutDialogActions.cancelSave(
        onCancel: () => Navigator.pop(context),
        onSave: _submit,
        cancelIdentifier: SemanticsIds.accountEditNameCancel,
        saveIdentifier: SemanticsIds.accountEditNameSave,
      ),
    );
  }
}

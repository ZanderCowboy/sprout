import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';

import 'sprout_filled_button.dart';
import 'sprout_outlined_button.dart';
import 'sprout_text_button.dart';

/// Standard alert-dialog action rows with Maestro semantics baked in.
class SproutDialogActions {
  SproutDialogActions._();

  static List<Widget> cancelDelete({
    required VoidCallback onCancel,
    required VoidCallback onDelete,
    String cancelIdentifier = SemanticsIds.dialogCancel,
    String deleteIdentifier = SemanticsIds.dialogDelete,
    String cancelLabel = AppStrings.cancel,
    String deleteLabel = AppStrings.delete,
  }) => [
    SproutTextButton(
      identifier: cancelIdentifier,
      label: cancelLabel,
      onPressed: onCancel,
    ),
    SproutFilledButton(
      identifier: deleteIdentifier,
      label: deleteLabel,
      onPressed: onDelete,
    ),
  ];

  static List<Widget> cancelSave({
    required VoidCallback onCancel,
    required VoidCallback onSave,
    String cancelIdentifier = SemanticsIds.dialogCancel,
    String saveIdentifier = SemanticsIds.dialogSave,
    String cancelLabel = AppStrings.cancel,
    String saveLabel = AppStrings.save,
  }) => [
    SproutTextButton(
      identifier: cancelIdentifier,
      label: cancelLabel,
      onPressed: onCancel,
    ),
    SproutFilledButton(
      identifier: saveIdentifier,
      label: saveLabel,
      onPressed: onSave,
    ),
  ];

  static List<Widget> cancelConfirm({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    String cancelIdentifier = SemanticsIds.dialogCancel,
    String confirmIdentifier = SemanticsIds.dialogDelete,
    String cancelLabel = AppStrings.cancel,
    required String confirmLabel,
  }) => [
    SproutTextButton(
      identifier: cancelIdentifier,
      label: cancelLabel,
      onPressed: onCancel,
    ),
    SproutFilledButton(
      identifier: confirmIdentifier,
      label: confirmLabel,
      onPressed: onConfirm,
    ),
  ];

  static List<Widget> cancelOutlinedDelete({
    required VoidCallback onCancel,
    required VoidCallback onDelete,
    String cancelIdentifier = SemanticsIds.dialogCancel,
    String deleteIdentifier = SemanticsIds.dialogDelete,
    String cancelLabel = AppStrings.cancel,
    String deleteLabel = AppStrings.delete,
  }) => [
    SproutOutlinedButton(
      identifier: cancelIdentifier,
      label: cancelLabel,
      onPressed: onCancel,
    ),
    SproutFilledButton(
      identifier: deleteIdentifier,
      label: deleteLabel,
      onPressed: onDelete,
    ),
  ];
}

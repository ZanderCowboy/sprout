import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/ui/export.dart';

/// Confirms account deletion. Returns `true` when the user confirms.
Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.deleteAccountConfirmTitle,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(AppStrings.deleteAccountWarning),
            const SizedBox(height: 12),
            const Text(AppStrings.deleteAccountPremiumNote),
            const SizedBox(height: 24),
            SproutOutlinedButton(
              identifier: SemanticsIds.accountDeleteCancel,
              label: AppStrings.cancel,
              onPressed: () => Navigator.pop(sheetContext, false),
            ),
            const SizedBox(height: 8),
            SproutFilledButton(
              identifier: SemanticsIds.accountDeleteConfirm,
              label: AppStrings.deleteAccount,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(sheetContext, true),
            ),
          ],
        ),
      );
    },
  );
  return confirmed == true;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/ui/export.dart';

/// Confirms account deletion. Returns `true` when the user confirms.
///
/// Delete stays disabled until the field exactly equals
/// [AppStrings.deleteAccountConfirmToken] (case-sensitive ASCII).
Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const _DeleteAccountSheet(),
  );
  return confirmed == true;
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  late final TextEditingController _confirmController;

  bool get _canDelete =>
      _confirmController.text == AppStrings.deleteAccountConfirmToken;

  @override
  void initState() {
    super.initState();
    _confirmController = TextEditingController();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomPad + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.deleteAccountConfirmTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(AppStrings.deleteAccountWarning),
            const SizedBox(height: 12),
            const Text(AppStrings.deleteAccountPremiumNote),
            const SizedBox(height: 20),
            Text(
              AppStrings.deleteAccountConfirmHelper,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SproutTextField(
              identifier: SemanticsIds.accountDeleteConfirmField,
              controller: _confirmController,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[ -~]')),
              ],
              decoration: const InputDecoration(
                hintText: AppStrings.deleteAccountConfirmHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SproutOutlinedButton(
              identifier: SemanticsIds.accountDeleteCancel,
              label: AppStrings.cancel,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
            SproutFilledButton(
              identifier: SemanticsIds.accountDeleteConfirm,
              label: AppStrings.deleteAccount,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                disabledBackgroundColor: scheme.error.withValues(alpha: 0.4),
                disabledForegroundColor: scheme.onError.withValues(alpha: 0.7),
              ),
              onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
            ),
          ],
        ),
      ),
    );
  }
}

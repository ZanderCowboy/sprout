import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/utils/account_identity_labels.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _editDisplayName(BuildContext context, AuthUser user) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _EditDisplayNameDialog(initialName: user.displayName ?? ''),
    );
    if (result == null || !context.mounted) return;
    await context.read<AuthCubit>().updateDisplayName(result);
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
              OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text(AppStrings.cancel),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text(AppStrings.deleteAccount),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthCubit>().deleteAccount();
  }

  void _openTerms(BuildContext context) {
    context.push(AppRoute.terms.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.account)),
      body: BlocBuilder<AuthCubit, AuthViewState>(
        builder: (context, state) {
          return switch (state) {
            AuthViewLoading() ||
            AuthViewGuest() => const Center(child: CircularProgressIndicator()),
            AuthViewSignedIn(:final user, :final busy, :final errorMessage) =>
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (busy) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      child: Text(
                        accountAvatarInitial(user),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    accountTileTitle(user),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    accountTileSubtitle(user),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text(AppStrings.editDisplayName),
                    enabled: !busy,
                    onTap: busy ? null : () => _editDisplayName(context, user),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text(AppStrings.signOut),
                    enabled: !busy,
                    onTap: busy
                        ? null
                        : () => context.read<AuthCubit>().signOut(),
                  ),
                  Text(
                    AppStrings.signOutKeepsLocalData,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.article_outlined),
                    title: const Text(AppStrings.termsOfService),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    enabled: !busy,
                    onTap: busy ? null : () => _openTerms(context),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_forever_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      AppStrings.deleteAccount,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    enabled: !busy,
                    onTap: busy ? null : () => _confirmDelete(context),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

class _EditDisplayNameDialog extends StatefulWidget {
  const _EditDisplayNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
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
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: AppStrings.displayName),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _submit, child: const Text(AppStrings.save)),
      ],
    );
  }
}

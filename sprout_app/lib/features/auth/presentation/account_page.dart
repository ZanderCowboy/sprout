import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/utils/account_identity_labels.dart';
import 'package:sprout/features/auth/presentation/widgets/account_section_card.dart';
import 'package:sprout/features/auth/presentation/widgets/delete_account_sheet.dart';
import 'package:sprout/features/auth/presentation/widgets/edit_display_name_dialog.dart';
import 'package:sprout/ui/export.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _editDisplayName(BuildContext context, AuthUser user) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          EditDisplayNameDialog(initialName: user.displayName ?? ''),
    );
    if (result == null || !context.mounted) return;
    await context.read<AuthCubit>().updateDisplayName(result);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDeleteAccountSheet(context);
    if (!confirmed || !context.mounted) return;
    await context.read<AuthCubit>().deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accountSectionProfile)),
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
                    AccountErrorBanner(message: errorMessage),
                  ],
                  const SizedBox(height: 24),
                  AccountSectionCard(
                    title: AppStrings.accountSectionProfile,
                    children: [
                      SproutListTile(
                        identifier: SemanticsIds.accountEditDisplayName,
                        label: AppStrings.editDisplayName,
                        leading: const Icon(Icons.edit_rounded),
                        title: const Text(AppStrings.editDisplayName),
                        enabled: !busy,
                        onTap: busy
                            ? null
                            : () => _editDisplayName(context, user),
                      ),
                      SproutListTile(
                        identifier: SemanticsIds.accountChangeEmail,
                        label: AppStrings.changeEmail,
                        leading: const Icon(Icons.alternate_email_rounded),
                        title: const Text(AppStrings.changeEmail),
                        subtitle: user.email?.trim().isNotEmpty == true
                            ? Text(user.email!)
                            : null,
                        enabled: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.changeEmailComingSoon,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AccountSectionCard(
                    title: AppStrings.accountSectionDanger,
                    children: [
                      SproutListTile(
                        identifier: SemanticsIds.accountDelete,
                        label: AppStrings.deleteAccount,
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
                ],
              ),
          };
        },
      ),
    );
  }
}

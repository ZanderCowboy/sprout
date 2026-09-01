import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import '../application/accounts_service.dart';
import '../domain/account.dart';
import 'account_form_sheet.dart';
import 'bloc/account_detail_bloc.dart';
import 'widgets/account_detail_view.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountDetailBloc(
        accountsService: sl<AccountsService>(),
        transactionsService: sl<TransactionsService>(),
        goalsService: sl<GoalsService>(),
      )..add(AccountDetailSubscriptionRequested(accountId: accountId)),
      child: const _AccountDetailListener(),
    );
  }
}

class _AccountDetailListener extends StatelessWidget {
  const _AccountDetailListener();

  Future<void> _edit(BuildContext context, Account account) async {
    await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountFormSheet(
        initial: account,
        defaultColor: Color(account.color),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Account account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(AppStrings.removeAccountConfirm),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AccountDetailBloc>().add(const AccountDetailDeleteRequested());
    }
  }

  Future<void> _openDeposit(BuildContext context, Account account) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepositBottomSheet(
        initialAccountId: account.id,
        initialMode: DepositBottomSheetMode.depositToAccountThenAllocate,
        lockAccountSelection: true,
        forceQuickAccountDepositUi: true,
        showRecurringToggle: true,
      ),
    );
  }

  Future<void> _clearScheduled(
    BuildContext context,
    AccountDetailReady state,
  ) async {
    final scheduledIds = state.scheduledTransactions.map((t) => t.id).toList();
    if (scheduledIds.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.clearScheduledTransactions),
        content: Text(
          AppStrings.clearScheduledBody(
            count: scheduledIds.length,
            scope: 'account',
          ),
        ),
        actions: SproutDialogActions.cancelDelete(
          onCancel: () => Navigator.pop(ctx, false),
          onDelete: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;

    context.read<AccountDetailBloc>().add(
      AccountDetailClearScheduledRequested(transactionIds: scheduledIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountDetailBloc, AccountDetailState>(
      listenWhen: (previous, current) => current is AccountDetailDeleted,
      listener: (context, state) {
        Navigator.of(context).pop();
      },
      builder: (context, state) {
        if (state is AccountDetailLoading || state is AccountDetailInitial) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AccountDetailNotFound || state is AccountDetailDeleted) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text(AppStrings.accountNotFound)),
          );
        }

        if (state is! AccountDetailReady) {
          return Scaffold(appBar: AppBar());
        }

        final account = state.account;

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name),
            actions: [
              SproutIconButton(
                identifier: SemanticsIds.accountDetailEdit,
                label: AppStrings.edit,
                onPressed: () => _edit(context, account),
                icon: const Icon(Icons.edit_rounded),
              ),
              SproutIconButton(
                identifier: SemanticsIds.accountDetailDelete,
                label: AppStrings.delete,
                onPressed: () => _delete(context, account),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: AccountDetailView(
            account: account,
            transactions: state.transactions,
            goals: state.goalsById,
            currentTotalCents: state.currentTotalCents,
            scheduledTotalCents: state.scheduledTotalCents,
            grandTotalCents: state.grandTotalCents,
            showRecurringLink: state.hasRecurringDeposits,
            onRefresh: () async {
              context.read<AccountDetailBloc>().add(
                const AccountDetailRefreshRequested(),
              );
            },
            onDeposit: () => _openDeposit(context, account),
            onClearScheduled: () => _clearScheduled(context, state),
          ),
        );
      },
    );
  }
}

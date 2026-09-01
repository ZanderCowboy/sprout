import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';
import 'bloc/transaction_detail_bloc.dart';
import 'utils/transaction_frequency_label.dart';
import 'widgets/transaction_allocation_row.dart';
import 'widgets/transaction_info_card.dart';
import 'widgets/transaction_section_card.dart';
import 'package:sprout/ui/export.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionDetailBloc(
        transactionId: transactionId,
        transactionsService: sl<TransactionsService>(),
        goalsService: sl<GoalsService>(),
        accountsService: sl<AccountsService>(),
      )..add(const TransactionDetailSubscriptionRequested()),
      child: BlocBuilder<TransactionDetailBloc, TransactionDetailState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.transaction)),
            body: switch (state) {
              TransactionDetailReady s => _TransactionDetailBody(state: s),
              TransactionDetailMissing _ => const Center(
                  child: Text(AppStrings.transactionNotFound),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        },
      ),
    );
  }
}

class _TransactionDetailBody extends StatefulWidget {
  const _TransactionDetailBody({required this.state});

  final TransactionDetailReady state;

  @override
  State<_TransactionDetailBody> createState() => _TransactionDetailBodyState();
}

class _TransactionDetailBodyState extends State<_TransactionDetailBody> {
  late final TextEditingController _note;
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.state.transaction.note ?? '');
  }

  @override
  void didUpdateWidget(covariant _TransactionDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.transaction.note != widget.state.transaction.note) {
      final next = widget.state.transaction.note ?? '';
      if (_note.text != next) _note.text = next;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    try {
      await sl<TransactionsService>().updateNote(
        transactionId: widget.state.transaction.id,
        note: _note.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.noteSaved)),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.couldNotSaveNotePrefix}$e')),
      );
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.state.transaction;
    final accountName = widget.state.accountsById[t.accountId]?.name ??
        AppStrings.unknownAccount;
    final goalName = t.goalId == null
        ? AppStrings.unallocated
        : (widget.state.goalsById[t.goalId!]?.name ?? AppStrings.unknownGoal);
    final kindLabel = switch (t.kind) {
      TransactionKind.deposit => AppStrings.deposit,
      TransactionKind.allocation => AppStrings.allocation,
    };

    final group = widget.state.groupTransactions;
    final hasGroup = group != null && group.isNotEmpty;
    final depositInGroup = hasGroup
        ? group.where((x) => x.kind == TransactionKind.deposit).toList()
        : const <Transaction>[];
    final allocationsInGroup = hasGroup
        ? group.where((x) => x.kind == TransactionKind.allocation).toList()
        : const <Transaction>[];

    final groupDepositCents =
        depositInGroup.fold<int>(0, (sum, x) => sum + x.amountCents);
    final groupAllocatedCents =
        allocationsInGroup.fold<int>(0, (sum, x) => sum + x.amountCents);
    final groupRemainingCents = groupDepositCents - groupAllocatedCents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TransactionInfoCard(
          title: formatZarFromCents(t.amountCents),
          subtitle: '$kindLabel · $accountName · $goalName',
        ),
        const SizedBox(height: 10),
        TransactionSectionCard(
          title: AppStrings.details,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv(AppStrings.kind, kindLabel),
              _kv(AppStrings.selectAccount, accountName),
              _kv(AppStrings.selectGoal, goalName),
              _kv(AppStrings.date, formatDate(t.occurredAt)),
              _kv(AppStrings.time, formatDateTime(t.occurredAt)),
              _kv(
                AppStrings.recurring,
                t.isRecurring && t.frequency != TransactionFrequency.none
                    ? AppStrings.yesWithFrequency(
                        transactionFrequencyLabel(t.frequency),
                      )
                    : AppStrings.no,
              ),
              if (t.nextScheduledDate != null)
                _kv(
                  AppStrings.nextScheduled,
                  formatDateTime(t.nextScheduledDate!),
                ),
              _kv(
                AppStrings.pendingSync,
                t.pendingSync ? AppStrings.yes : AppStrings.no,
              ),
              if (t.groupId != null) _kv(AppStrings.group, t.groupId!),
            ],
          ),
        ),
        if (t.isRecurring && t.frequency != TransactionFrequency.none) ...[
          const SizedBox(height: 10),
          TransactionSectionCard(
            title: AppStrings.recurringPayment,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SproutFilledButton.icon(
                identifier: SemanticsIds.transactionManageRecurring,
                label: AppStrings.manageRecurringPayments,
                onPressed: () {
                  context.push(AppRoute.recurring.path);
                },
                icon: const Icon(Icons.autorenew_rounded),
                labelWidget: const Text(AppStrings.manageRecurringPayments),
              ),
            ),
          ),
        ],
        if (hasGroup) ...[
          const SizedBox(height: 10),
          TransactionSectionCard(
            title: AppStrings.splitGroup,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (groupDepositCents > 0) ...[
                  _kv(
                    AppStrings.depositTotal,
                    formatZarFromCents(groupDepositCents),
                  ),
                  _kv(
                    AppStrings.allocatedTotal,
                    formatZarFromCents(groupAllocatedCents),
                  ),
                  _kv(
                    AppStrings.remaining,
                    formatZarFromCents(
                      groupRemainingCents < 0 ? 0 : groupRemainingCents,
                    ),
                  ),
                  const Divider(height: 20),
                ],
                for (final a in allocationsInGroup) ...[
                  TransactionAllocationRow(
                    amount: formatZarFromCents(a.amountCents),
                    goalName: a.goalId == null
                        ? AppStrings.unallocated
                        : (widget.state.goalsById[a.goalId!]?.name ??
                            AppStrings.unknownGoal),
                    occurredAt: a.occurredAt,
                  ),
                  const SizedBox(height: 8),
                ],
                if (allocationsInGroup.isEmpty)
                  Text(
                    AppStrings.noAllocationsInGroup,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        TransactionSectionCard(
          title: AppStrings.note,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SproutTextField(
                identifier: SemanticsIds.transactionNoteField,
                controller: _note,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: AppStrings.addANoteHint,
                ),
              ),
              const SizedBox(height: 12),
              SproutFilledButton(
                identifier: SemanticsIds.transactionNoteSave,
                label: AppStrings.save,
                onPressed: _savingNote ? null : _saveNote,
                child: Text(
                  _savingNote ? AppStrings.saving : AppStrings.save,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

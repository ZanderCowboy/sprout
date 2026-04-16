import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/presentation/recurring_payments_page.dart';
import 'package:sprout/features/transactions/export.dart';
import 'bloc/transaction_detail_bloc.dart';
import 'utils/transaction_frequency_label.dart';

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
            appBar: AppBar(title: const Text('Transaction')),
            body: switch (state) {
              TransactionDetailReady s => _TransactionDetailBody(state: s),
              TransactionDetailMissing _ => const Center(
                  child: Text('Transaction not found.'),
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
        const SnackBar(content: Text('Note saved.')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save note: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.state.transaction;
    final accountName =
        widget.state.accountsById[t.accountId]?.name ?? 'Unknown account';
    final goalName = t.goalId == null
        ? 'Unallocated'
        : (widget.state.goalsById[t.goalId!]?.name ?? 'Unknown goal');
    final kindLabel = switch (t.kind) {
      TransactionKind.deposit => 'Deposit',
      TransactionKind.allocation => 'Allocation',
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
        _InfoCard(
          title: formatZarFromCents(t.amountCents),
          subtitle: '$kindLabel · $accountName · $goalName',
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Kind', kindLabel),
              _kv('Account', accountName),
              _kv('Goal', goalName),
              _kv('Date', formatDate(t.occurredAt)),
              _kv('Time', formatDateTime(t.occurredAt)),
              _kv(
                'Recurring',
                t.isRecurring && t.frequency != TransactionFrequency.none
                    ? 'Yes (${transactionFrequencyLabel(t.frequency)})'
                    : 'No',
              ),
              if (t.nextScheduledDate != null)
                _kv('Next scheduled', formatDateTime(t.nextScheduledDate!)),
              _kv('Pending sync', t.pendingSync ? 'Yes' : 'No'),
              if (t.groupId != null) _kv('Group', t.groupId!),
            ],
          ),
        ),
        if (t.isRecurring && t.frequency != TransactionFrequency.none) ...[
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Recurring payment',
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecurringPaymentsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.autorenew_rounded),
                label: const Text('Manage recurring payments'),
              ),
            ),
          ),
        ],
        if (hasGroup) ...[
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Split (group)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (groupDepositCents > 0) ...[
                  _kv('Deposit total', formatZarFromCents(groupDepositCents)),
                  _kv('Allocated total', formatZarFromCents(groupAllocatedCents)),
                  _kv(
                    'Remaining',
                    formatZarFromCents(groupRemainingCents < 0 ? 0 : groupRemainingCents),
                  ),
                  const Divider(height: 20),
                ],
                for (final a in allocationsInGroup) ...[
                  _AllocationRowView(
                    amount: formatZarFromCents(a.amountCents),
                    goalName: a.goalId == null
                        ? 'Unallocated'
                        : (widget.state.goalsById[a.goalId!]?.name ?? 'Unknown goal'),
                    occurredAt: a.occurredAt,
                  ),
                  const SizedBox(height: 8),
                ],
                if (allocationsInGroup.isEmpty)
                  Text(
                    'No allocations in this group.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Note',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Add a note…',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _savingNote ? null : _saveNote,
                child: Text(_savingNote ? 'Saving…' : AppStrings.save),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AllocationRowView extends StatelessWidget {
  const _AllocationRowView({
    required this.amount,
    required this.goalName,
    required this.occurredAt,
  });

  final String amount;
  final String goalName;
  final DateTime occurredAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$goalName · ${formatDate(occurredAt)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

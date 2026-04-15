import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/accounts.dart';
import 'package:sprout/features/goals/goals.dart';
import 'package:sprout/features/transactions/transactions.dart';

class RecurringPaymentsPage extends StatelessWidget {
  const RecurringPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _RecurringPaymentsBloc(
        transactionsService: sl<TransactionsService>(),
        goalsService: sl<GoalsService>(),
        accountsService: sl<AccountsService>(),
      )..add(const _RecurringPaymentsSubscriptionRequested()),
      child: BlocBuilder<_RecurringPaymentsBloc, _RecurringPaymentsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Recurring payments')),
            body: switch (state) {
              _RecurringPaymentsReady s => _RecurringPaymentsBody(state: s),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        },
      ),
    );
  }
}

class _RecurringPaymentsBody extends StatelessWidget {
  const _RecurringPaymentsBody({required this.state});

  final _RecurringPaymentsReady state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return Center(
        child: Text(
          'No recurring deposits yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = state.items[i];
        final goalName = item.goalId == null
            ? 'Unallocated'
            : (state.goalsById[item.goalId!]?.name ?? 'Unknown goal');
        final accountName =
            state.accountsById[item.accountId]?.name ?? 'Unknown account';

        return ListTile(
          leading: const Icon(Icons.autorenew_rounded),
          title: Text(formatZarFromCents(item.amountCents)),
          subtitle: Text(
            '$goalName · $accountName · ${_labelForFrequency(item.frequency)}'
            '${item.nextScheduledDate != null ? ' · next ${formatDateTime(item.nextScheduledDate!)}' : ''}',
          ),
          trailing: IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _openEdit(context, item),
          ),
          onTap: () => _openEdit(context, item),
        );
      },
    );
  }

  String _labelForFrequency(TransactionFrequency f) {
    return switch (f) {
      TransactionFrequency.daily => 'Daily',
      TransactionFrequency.weekly => 'Weekly',
      TransactionFrequency.monthly => 'Monthly',
      TransactionFrequency.yearly => 'Yearly',
      TransactionFrequency.none => 'None',
    };
  }

  Future<void> _openEdit(BuildContext context, Transaction tx) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditRecurringSheet(transaction: tx),
    );
  }
}

class _EditRecurringSheet extends StatefulWidget {
  const _EditRecurringSheet({required this.transaction});

  final Transaction transaction;

  @override
  State<_EditRecurringSheet> createState() => _EditRecurringSheetState();
}

class _EditRecurringSheetState extends State<_EditRecurringSheet> {
  late bool _isRecurring;
  late TransactionFrequency _frequency;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isRecurring = widget.transaction.isRecurring;
    _frequency = widget.transaction.frequency == TransactionFrequency.none
        ? TransactionFrequency.monthly
        : widget.transaction.frequency;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await sl<TransactionsService>().updateRecurringDeposit(
        transactionId: widget.transaction.id,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : TransactionFrequency.none,
      );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelRecurring() async {
    setState(() {
      _isRecurring = false;
      _frequency = TransactionFrequency.none;
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recurring deposit',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _isRecurring,
            onChanged: _saving ? null : (v) => setState(() => _isRecurring = v),
            title: const Text('Enabled'),
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<TransactionFrequency>(
              value: _frequency, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(
                  value: TransactionFrequency.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.monthly,
                  child: Text('Monthly'),
                ),
                DropdownMenuItem(
                  value: TransactionFrequency.yearly,
                  child: Text('Yearly'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _frequency = v);
                    },
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelRecurring,
                  child: const Text('Cancel recurring'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text(AppStrings.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

sealed class _RecurringPaymentsEvent {
  const _RecurringPaymentsEvent();
}

final class _RecurringPaymentsSubscriptionRequested
    extends _RecurringPaymentsEvent {
  const _RecurringPaymentsSubscriptionRequested();
}

sealed class _RecurringPaymentsState {
  const _RecurringPaymentsState();
}

final class _RecurringPaymentsInitial extends _RecurringPaymentsState {
  const _RecurringPaymentsInitial();
}

final class _RecurringPaymentsReady extends _RecurringPaymentsState {
  const _RecurringPaymentsReady({
    required this.items,
    required this.goalsById,
    required this.accountsById,
  });

  final List<Transaction> items;
  final Map<String, Goal> goalsById;
  final Map<String, Account> accountsById;
}

class _RecurringPaymentsBloc
    extends Bloc<_RecurringPaymentsEvent, _RecurringPaymentsState> {
  _RecurringPaymentsBloc({
    required TransactionsService transactionsService,
    required GoalsService goalsService,
    required AccountsService accountsService,
  })  : _transactionsService = transactionsService,
        _goalsService = goalsService,
        _accountsService = accountsService,
        super(const _RecurringPaymentsInitial()) {
    on<_RecurringPaymentsSubscriptionRequested>(_onSubscribe);
  }

  final TransactionsService _transactionsService;
  final GoalsService _goalsService;
  final AccountsService _accountsService;

  Future<void> _onSubscribe(
    _RecurringPaymentsSubscriptionRequested event,
    Emitter<_RecurringPaymentsState> emit,
  ) {
    return emit.forEach<_RecurringPaymentsReady>(
      _watchReady(),
      onData: (ready) => ready,
    );
  }

  Stream<_RecurringPaymentsReady> _watchReady() {
    return Stream<_RecurringPaymentsReady>.multi((controller) {
      List<Transaction>? txs;
      List<Goal>? goals;
      List<Account>? accounts;

      void tryEmit() {
        if (txs == null || goals == null || accounts == null) return;

        final items = txs!
            .where(
              (t) =>
                  t.isRecurring &&
                  t.frequency != TransactionFrequency.none &&
                  t.kind == TransactionKind.deposit,
            )
            .toList()
          ..sort((a, b) {
            final ad = a.nextScheduledDate ?? DateTime(9999);
            final bd = b.nextScheduledDate ?? DateTime(9999);
            return ad.compareTo(bd);
          });

        controller.add(
          _RecurringPaymentsReady(
            items: items,
            goalsById: {for (final g in goals!) g.id: g},
            accountsById: {for (final a in accounts!) a.id: a},
          ),
        );
      }

      final txSub = _transactionsService.watchTransactions().listen(
        (t) {
          txs = t;
          tryEmit();
        },
        onError: controller.addError,
      );
      final goalsSub = _goalsService.watchGoals().listen(
        (g) {
          goals = g;
          tryEmit();
        },
        onError: controller.addError,
      );
      final accountsSub = _accountsService.watchAccounts().listen(
        (a) {
          accounts = a;
          tryEmit();
        },
        onError: controller.addError,
      );

      controller.onCancel = () {
        txSub.cancel();
        goalsSub.cancel();
        accountsSub.cancel();
      };
    });
  }
}



import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

enum DepositBottomSheetMode {
  /// Current behavior: deposit and immediately assign to a single goal.
  fullDepositToGoal,

  /// Deposit to account, then optionally allocate some/all of it to goals.
  depositToAccountThenAllocate,

  /// Allocate existing unallocated funds into one or more goals (no new deposit).
  allocateExistingUnallocated,
}

class DepositBottomSheet extends StatefulWidget {
  const DepositBottomSheet({
    super.key,
    this.initialAccountId,
    this.initialGoalId,
    this.initialAmountCents,
    this.maxAllocatableCents,
    this.initialMode = DepositBottomSheetMode.fullDepositToGoal,
    this.lockAccountSelection = false,
    this.forceQuickAccountDepositUi = false,
    this.lockGoalSelection = false,
    this.forceQuickGoalDepositUi = false,
    this.allowUseUnallocatedWhenGoalLocked = true,
    this.showRecurringToggle = true,
  });

  /// When set and still present in the loaded list, selects this account.
  final String? initialAccountId;

  /// When set and still present in the loaded list, selects this goal.
  final String? initialGoalId;

  /// When set, pre-fills the amount field.
  final int? initialAmountCents;

  /// When set (allocate mode), caps allocations against existing unallocated funds.
  final int? maxAllocatableCents;

  final DepositBottomSheetMode initialMode;

  /// When true, disables the account picker (e.g. when launched from an account
  /// detail page).
  final bool lockAccountSelection;

  /// When true, shows a minimal "quick deposit" UI: current account + amount.
  /// Deposits go to the account as unallocated (goalId null).
  final bool forceQuickAccountDepositUi;

  /// When true, disables the goal picker (e.g. when launched from a goal detail
  /// page).
  final bool lockGoalSelection;

  /// When true, shows a goal-focused UI: pick an account + enter amount (goal is
  /// locked) and optionally choose "use unallocated" instead of adding new money.
  final bool forceQuickGoalDepositUi;

  /// When goal-locked, whether to expose the "Use unallocated" option.
  final bool allowUseUnallocatedWhenGoalLocked;

  /// Whether to show the recurring toggle / frequency picker.
  final bool showRecurringToggle;

  @override
  State<DepositBottomSheet> createState() => _DepositBottomSheetState();
}

class _AllocationRow {
  _AllocationRow({required this.goalId, required this.amountController});

  String? goalId;
  final TextEditingController amountController;
}

class _DepositBottomSheetState extends State<DepositBottomSheet> {
  static const _uuid = Uuid();
  List<Account> _accounts = [];
  List<Goal> _goals = [];
  String? _accountId;
  String? _goalId;
  final _amount = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late DepositBottomSheetMode _mode;
  final List<_AllocationRow> _allocations = [];
  bool _isRecurring = false;
  TransactionFrequency _frequency = TransactionFrequency.monthly;
  int? _availableUnallocatedForAccountCents;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedDate = DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    for (final r in _allocations) {
      r.amountController.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final accounts = await sl<AccountsService>().getAccounts();
    final goals = await sl<GoalsService>().getGoals();
    if (!mounted) return;
    final initialAccount = widget.initialAccountId;
    final initialGoal = widget.initialGoalId;
    setState(() {
      _accounts = accounts;
      _goals = goals;
      _accountId = initialAccount != null && accounts.any((a) => a.id == initialAccount)
          ? initialAccount
          : (accounts.isNotEmpty ? accounts.first.id : null);
      _goalId = initialGoal != null && goals.any((g) => g.id == initialGoal)
          ? initialGoal
          : (goals.isNotEmpty ? goals.first.id : null);
      final initialAmount = widget.initialAmountCents;
      if (initialAmount != null && _amount.text.trim().isEmpty) {
        _amount.text = (initialAmount / 100).toStringAsFixed(2);
      }
      if (_allocations.isEmpty) {
        _allocations.add(_AllocationRow(goalId: _goalId, amountController: TextEditingController()));
      }
      _loading = false;
    });

    if (_mode == DepositBottomSheetMode.allocateExistingUnallocated && _accountId != null) {
      await _refreshAvailableUnallocatedForSelectedAccount();
    }
  }

  Future<void> _refreshAvailableUnallocatedForSelectedAccount() async {
    final accountId = _accountId;
    if (accountId == null) return;
    final txs = await sl<TransactionsService>().getForAccount(accountId);
    final now = DateTime.now();
    var depositedUnallocated = 0;
    var allocated = 0;
    for (final t in txs) {
      if (TransactionDisplay.isPendingByDate(t, now)) continue;
      switch (t.kind) {
        case TransactionKind.deposit:
          final gid = t.goalId;
          if (gid == null || gid.isEmpty) {
            depositedUnallocated += t.amountCents;
          }
          break;
        case TransactionKind.allocation:
          allocated += t.amountCents;
          break;
      }
    }
    final available = depositedUnallocated - allocated;
    if (!mounted) return;
    setState(() {
      _availableUnallocatedForAccountCents = available > 0 ? available : 0;
    });
  }

  Future<void> _submit() async {
    final cents = parseZarToCents(_amount.text);
    if (_accountId == null) {
      setState(() => _error = 'Pick an account.');
      return;
    }

    setState(() => _error = null);
    final tx = sl<TransactionsService>();
    final accountId = _accountId!;
    final occurredAt = _selectedDate;

    if (_mode == DepositBottomSheetMode.fullDepositToGoal) {
      if (cents == null || cents <= 0) {
        setState(() => _error = 'Enter a valid amount.');
        return;
      }
      if (_goalId == null) {
        setState(() => _error = 'Pick a goal.');
        return;
      }
      await tx.recordDeposit(
        accountId: accountId,
        goalId: _goalId!,
        groupId: null,
        amountCents: cents,
        occurredAt: occurredAt,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : TransactionFrequency.none,
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_mode == DepositBottomSheetMode.allocateExistingUnallocated) {
      final maxAllowed = _availableUnallocatedForAccountCents;
      if (maxAllowed == null || maxAllowed <= 0) {
        setState(() => _error = 'No unallocated funds available for this account.');
        return;
      }
      var allocatedTotal = 0;
      for (final row in _allocations) {
        final goalId = row.goalId;
        final aCents = parseZarToCents(row.amountController.text) ?? 0;
        if (goalId == null || aCents <= 0) continue;
        allocatedTotal += aCents;
      }
      if (allocatedTotal <= 0) {
        setState(() => _error = 'Enter at least one allocation amount.');
        return;
      }
      if (allocatedTotal > maxAllowed) {
        setState(() => _error = 'Allocations exceed available unallocated funds.');
        return;
      }
      final groupId = _uuid.v4();
      for (final row in _allocations) {
        final goalId = row.goalId;
        final aCents = parseZarToCents(row.amountController.text) ?? 0;
        if (goalId == null || aCents <= 0) continue;
        await tx.recordAllocation(
          accountId: accountId,
          goalId: goalId,
          groupId: groupId,
          amountCents: aCents,
          occurredAt: occurredAt,
        );
      }
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Deposit to account (unallocated), then optionally allocate/split.
    if (cents == null || cents <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    final groupId = _uuid.v4();
    await tx.recordAccountDeposit(
      accountId: accountId,
      groupId: groupId,
      amountCents: cents,
      occurredAt: occurredAt,
      isRecurring: _isRecurring,
      frequency: _isRecurring ? _frequency : TransactionFrequency.none,
    );

    var allocatedTotal = 0;
    for (final row in _allocations) {
      final goalId = row.goalId;
      final aCents = parseZarToCents(row.amountController.text) ?? 0;
      if (goalId == null || aCents <= 0) continue;
      allocatedTotal += aCents;
    }
    if (allocatedTotal > cents) {
      setState(() => _error = 'Allocations exceed deposited amount.');
      return;
    }
    for (final row in _allocations) {
      final goalId = row.goalId;
      final aCents = parseZarToCents(row.amountController.text) ?? 0;
      if (goalId == null || aCents <= 0) continue;
      await tx.recordAllocation(
        accountId: accountId,
        goalId: goalId,
        groupId: groupId,
        amountCents: aCents,
        occurredAt: occurredAt,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Add at least one account before depositing.', style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    final quickAccount = widget.forceQuickAccountDepositUi;
    final quickGoal = widget.forceQuickGoalDepositUi;
    final isQuickUi = quickAccount || quickGoal;
    final canDepositToGoal = _goals.isNotEmpty;
    final dateLabel = formatDateTime(_selectedDate);
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.deposit,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (quickGoal) ...[
            SegmentedButton<DepositBottomSheetMode>(
              segments: [
                const ButtonSegment(
                  value: DepositBottomSheetMode.fullDepositToGoal,
                  label: Text('Add new money'),
                  icon: Icon(Icons.add_rounded),
                ),
                if (widget.allowUseUnallocatedWhenGoalLocked)
                  const ButtonSegment(
                    value: DepositBottomSheetMode.allocateExistingUnallocated,
                    label: Text('Use unallocated'),
                    icon: Icon(Icons.savings_outlined),
                  ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) async {
                final next = s.first;
                setState(() => _mode = next);
                if (next == DepositBottomSheetMode.allocateExistingUnallocated) {
                  await _refreshAvailableUnallocatedForSelectedAccount();
                }
              },
            ),
            const SizedBox(height: 12),
          ] else if (!quickAccount) ...[
            SegmentedButton<DepositBottomSheetMode>(
              segments: [
                if (canDepositToGoal)
                  const ButtonSegment(
                    value: DepositBottomSheetMode.fullDepositToGoal,
                    label: Text('To goal'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                const ButtonSegment(
                  value: DepositBottomSheetMode.depositToAccountThenAllocate,
                  label: Text('To account'),
                  icon: Icon(Icons.account_balance_wallet_outlined),
                ),
                if (widget.maxAllocatableCents != null && (widget.maxAllocatableCents ?? 0) > 0 && _goals.isNotEmpty)
                  const ButtonSegment(
                    value: DepositBottomSheetMode.allocateExistingUnallocated,
                    label: Text('Use unallocated'),
                    icon: Icon(Icons.savings_outlined),
                  ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) async {
                final next = s.first;
                setState(() => _mode = next);
                if (next == DepositBottomSheetMode.allocateExistingUnallocated) {
                  await _refreshAvailableUnallocatedForSelectedAccount();
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
            value: _accountId, // ignore: deprecated_member_use
            decoration: const InputDecoration(labelText: AppStrings.selectAccount),
            items: [for (final a in _accounts) DropdownMenuItem(value: a.id, child: Text(a.name))],
            onChanged: widget.lockAccountSelection
                ? null
                : (v) async {
                    setState(() => _accountId = v);
                    if (_mode == DepositBottomSheetMode.allocateExistingUnallocated) {
                      await _refreshAvailableUnallocatedForSelectedAccount();
                    }
                  },
          ),
          const SizedBox(height: 12),
          if (_mode == DepositBottomSheetMode.fullDepositToGoal) ...[
            if (!canDepositToGoal) ...[
              Text('Add a goal first to deposit directly to a goal.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _goalId, // ignore: deprecated_member_use
                decoration: const InputDecoration(labelText: AppStrings.selectGoal),
                items: [for (final g in _goals) DropdownMenuItem(value: g.id, child: Text(g.name))],
                onChanged: widget.lockGoalSelection ? null : (v) => setState(() => _goalId = v),
              ),
              const SizedBox(height: 12),
            ],
          ],
          if (_mode != DepositBottomSheetMode.allocateExistingUnallocated) ...[
            TextField(
              controller: _amount,
              decoration: const InputDecoration(labelText: AppStrings.amount),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ] else ...[
            // In allocate-only mode we don’t create a new deposit; the user allocates
            // from existing available unallocated funds.
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Available unallocated'),
              child: Text(
                formatZarFromCents(_availableUnallocatedForAccountCents ?? 0),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (widget.showRecurringToggle && _mode != DepositBottomSheetMode.allocateExistingUnallocated) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(DateTime.now().year + 10),
                );
                if (picked == null) return;
                setState(() => _selectedDate = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Date · $dateLabel'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
              title: const Text('Make this a recurring deposit'),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<TransactionFrequency>(
                value: _frequency, // ignore: deprecated_member_use
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: TransactionFrequency.daily, child: Text('Daily')),
                  DropdownMenuItem(value: TransactionFrequency.weekly, child: Text('Weekly')),
                  DropdownMenuItem(value: TransactionFrequency.monthly, child: Text('Monthly')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _frequency = v);
                },
              ),
            ],
          ],
          if (!isQuickUi && _mode != DepositBottomSheetMode.fullDepositToGoal) ...[
            const SizedBox(height: 16),
            Text(
              'Allocate now (optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_goals.isEmpty) ...[
              Text('No goals yet — this deposit will stay unallocated.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
            ] else ...[
              for (var i = 0; i < _allocations.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _allocations[i].goalId, // ignore: deprecated_member_use
                        decoration: const InputDecoration(labelText: 'Goal'),
                        items: [for (final g in _goals) DropdownMenuItem(value: g.id, child: Text(g.name))],
                        onChanged: (v) => setState(() => _allocations[i].goalId = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _allocations[i].amountController,
                        decoration: const InputDecoration(labelText: AppStrings.amount),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: _allocations.length <= 1
                          ? null
                          : () {
                              setState(() {
                                final removed = _allocations.removeAt(i);
                                removed.amountController.dispose();
                              });
                            },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _allocations.add(_AllocationRow(goalId: _goalId, amountController: TextEditingController()));
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add another goal'),
                ),
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _submit, child: const Text(AppStrings.save)),
        ],
      ),
    );
  }
}

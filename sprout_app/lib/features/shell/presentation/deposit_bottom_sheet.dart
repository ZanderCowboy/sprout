import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import 'deposit_cubit.dart';
import 'enums/deposit_bottom_sheet_mode.dart';

export 'enums/deposit_bottom_sheet_mode.dart';

class DepositBottomSheet extends StatelessWidget {
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

  final String? initialAccountId;
  final String? initialGoalId;
  final int? initialAmountCents;
  final int? maxAllocatableCents;
  final DepositBottomSheetMode initialMode;
  final bool lockAccountSelection;
  final bool forceQuickAccountDepositUi;
  final bool lockGoalSelection;
  final bool forceQuickGoalDepositUi;
  final bool allowUseUnallocatedWhenGoalLocked;
  final bool showRecurringToggle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DepositCubit(
        accountsService: sl<AccountsService>(),
        goalsService: sl<GoalsService>(),
        transactionsService: sl<TransactionsService>(),
        initialAccountId: initialAccountId,
        initialGoalId: initialGoalId,
        initialAmountCents: initialAmountCents,
        initialMode: initialMode,
      )..load(),
      child: BlocListener<DepositCubit, DepositState>(
        listenWhen: (prev, next) => next is DepositSubmitSuccess,
        listener: (context, state) {
          if (state is DepositSubmitSuccess) {
            Navigator.of(context).pop();
          }
        },
        child: _DepositBottomSheetBody(
          maxAllocatableCents: maxAllocatableCents,
          lockAccountSelection: lockAccountSelection,
          forceQuickAccountDepositUi: forceQuickAccountDepositUi,
          lockGoalSelection: lockGoalSelection,
          forceQuickGoalDepositUi: forceQuickGoalDepositUi,
          allowUseUnallocatedWhenGoalLocked: allowUseUnallocatedWhenGoalLocked,
          showRecurringToggle: showRecurringToggle,
        ),
      ),
    );
  }
}

class _AllocationRow {
  _AllocationRow({required this.goalId, required this.amountController});

  String? goalId;
  final TextEditingController amountController;
}

class _DepositBottomSheetBody extends StatefulWidget {
  const _DepositBottomSheetBody({
    required this.maxAllocatableCents,
    required this.lockAccountSelection,
    required this.forceQuickAccountDepositUi,
    required this.lockGoalSelection,
    required this.forceQuickGoalDepositUi,
    required this.allowUseUnallocatedWhenGoalLocked,
    required this.showRecurringToggle,
  });

  final int? maxAllocatableCents;
  final bool lockAccountSelection;
  final bool forceQuickAccountDepositUi;
  final bool lockGoalSelection;
  final bool forceQuickGoalDepositUi;
  final bool allowUseUnallocatedWhenGoalLocked;
  final bool showRecurringToggle;

  @override
  State<_DepositBottomSheetBody> createState() => _DepositBottomSheetBodyState();
}

class _DepositBottomSheetBodyState extends State<_DepositBottomSheetBody> {
  final _amount = TextEditingController();
  final _allocations = <_AllocationRow>[];
  var _formInitialized = false;

  @override
  void dispose() {
    _amount.dispose();
    for (final row in _allocations) {
      row.amountController.dispose();
    }
    super.dispose();
  }

  void _ensureFormInitialized(DepositReady ready) {
    if (_formInitialized) return;
    _amount.text = ready.amountText;
    _allocations
      ..clear()
      ..addAll(
        ready.allocations.map(
          (row) => _AllocationRow(
            goalId: row.goalId,
            amountController: TextEditingController(text: row.amountText),
          ),
        ),
      );
    _formInitialized = true;
  }

  Future<void> _submit(DepositCubit cubit, DepositReady ready) async {
    await cubit.submitForm(
      amountText: _amount.text,
      allocationRows: [
        for (final row in _allocations)
          (goalId: row.goalId, amountText: row.amountController.text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepositCubit, DepositState>(
      builder: (context, state) {
        final mq = MediaQuery.of(context);
        final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;
        final cubit = context.read<DepositCubit>();

        if (state is DepositLoading || state is DepositInitial) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DepositNoAccounts) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.createAccountFirstShort,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.addAccountBeforeDepositing,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                SproutFilledButton.icon(
                  identifier: SemanticsIds.depositNoAccountsNewAccount,
                  label: AppStrings.newAccount,
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => AccountFormSheet(defaultColor: AppColors.cardColorAt(0)),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  labelWidget: const Text(AppStrings.newAccount),
                ),
              ],
            ),
          );
        }

        if (state is! DepositReady) {
          return const SizedBox.shrink();
        }

        _ensureFormInitialized(state);

        final quickAccount = widget.forceQuickAccountDepositUi;
        final quickGoal = widget.forceQuickGoalDepositUi;
        final isQuickUi = quickAccount || quickGoal;
        final canDepositToGoal = state.goals.isNotEmpty;
        final dateLabel = formatDateTime(state.selectedDate);

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
                    ButtonSegment(
                      value: DepositBottomSheetMode.fullDepositToGoal,
                      label: Semantics(
                        identifier: SemanticsIds.depositModeAddNewMoney,
                        button: true,
                        label: AppStrings.addNewMoney,
                        child: const Text(AppStrings.addNewMoney),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                    if (widget.allowUseUnallocatedWhenGoalLocked)
                      ButtonSegment(
                        value: DepositBottomSheetMode.allocateExistingUnallocated,
                        label: Semantics(
                          identifier: SemanticsIds.depositModeUseUnallocated,
                          button: true,
                          label: AppStrings.useUnallocated,
                          child: const Text(AppStrings.useUnallocated),
                        ),
                        icon: const Icon(Icons.savings_outlined),
                      ),
                  ],
                  selected: {state.mode},
                  onSelectionChanged: (s) => cubit.setMode(s.first),
                ),
                const SizedBox(height: 12),
              ] else if (!quickAccount) ...[
                SegmentedButton<DepositBottomSheetMode>(
                  segments: [
                    if (canDepositToGoal)
                      ButtonSegment(
                        value: DepositBottomSheetMode.fullDepositToGoal,
                        label: Semantics(
                          identifier: SemanticsIds.depositModeToGoal,
                          button: true,
                          label: AppStrings.toGoal,
                          child: const Text(AppStrings.toGoal),
                        ),
                        icon: const Icon(Icons.flag_outlined),
                      ),
                    ButtonSegment(
                      value: DepositBottomSheetMode.depositToAccountThenAllocate,
                      label: Semantics(
                        identifier: SemanticsIds.depositModeToAccount,
                        button: true,
                        label: AppStrings.toAccount,
                        child: const Text(AppStrings.toAccount),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    if (widget.maxAllocatableCents != null &&
                        (widget.maxAllocatableCents ?? 0) > 0 &&
                        state.goals.isNotEmpty)
                      ButtonSegment(
                        value: DepositBottomSheetMode.allocateExistingUnallocated,
                        label: Semantics(
                          identifier: SemanticsIds.depositModeUseUnallocated,
                          button: true,
                          label: AppStrings.useUnallocated,
                          child: const Text(AppStrings.useUnallocated),
                        ),
                        icon: const Icon(Icons.savings_outlined),
                      ),
                  ],
                  selected: {state.mode},
                  onSelectionChanged: (s) => cubit.setMode(s.first),
                ),
                const SizedBox(height: 12),
              ],
              SproutDropdownField<String>(
                identifier: SemanticsIds.depositAccountDropdown,
                label: AppStrings.selectAccount,
                value: state.accountId,
                decoration: const InputDecoration(labelText: AppStrings.selectAccount),
                items: [
                  for (final a in state.accounts)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: widget.lockAccountSelection
                    ? null
                    : (v) async {
                        cubit.setAccountId(v);
                        if (state.mode ==
                            DepositBottomSheetMode.allocateExistingUnallocated) {
                          await cubit.refreshAvailableUnallocated();
                        }
                      },
              ),
              const SizedBox(height: 12),
              if (state.mode == DepositBottomSheetMode.fullDepositToGoal) ...[
                if (!canDepositToGoal) ...[
                  Text(AppStrings.addGoalFirstToDeposit, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                ] else ...[
                  SproutDropdownField<String>(
                    identifier: SemanticsIds.depositGoalDropdown,
                    label: AppStrings.selectGoal,
                    value: state.goalId,
                    decoration: const InputDecoration(labelText: AppStrings.selectGoal),
                    items: [
                      for (final g in state.goals)
                        DropdownMenuItem(value: g.id, child: Text(g.name)),
                    ],
                    onChanged: widget.lockGoalSelection ? null : cubit.setGoalId,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              if (state.mode != DepositBottomSheetMode.allocateExistingUnallocated) ...[
                SproutTextField(
                  identifier: SemanticsIds.depositAmountField,
                  fieldKey: const Key('deposit_amount_field'),
                  controller: _amount,
                  decoration: const InputDecoration(labelText: AppStrings.amount),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ] else ...[
                InputDecorator(
                  decoration: const InputDecoration(labelText: AppStrings.availableUnallocated),
                  child: Text(
                    formatZarFromCents(state.availableUnallocatedForAccountCents ?? 0),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              if (widget.showRecurringToggle &&
                  state.mode != DepositBottomSheetMode.allocateExistingUnallocated) ...[
                const SizedBox(height: 12),
                SproutOutlinedButton.icon(
                  identifier: SemanticsIds.depositDatePicker,
                  label: AppStrings.date,
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(DateTime.now().year + 10),
                    );
                    if (picked == null) return;
                    cubit.setSelectedDate(picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  labelWidget: Text(AppStrings.dateWithLabel(dateLabel)),
                ),
                SproutSwitchTile(
                  identifier: SemanticsIds.depositRecurringToggle,
                  label: AppStrings.makeRecurringDeposit,
                  value: state.isRecurring,
                  onChanged: cubit.setRecurring,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.makeRecurringDeposit),
                ),
                if (state.isRecurring) ...[
                  const SizedBox(height: 8),
                  SproutDropdownField<TransactionFrequency>(
                    identifier: SemanticsIds.depositFrequencyDropdown,
                    label: AppStrings.frequency,
                    value: state.frequency,
                    decoration: const InputDecoration(labelText: AppStrings.frequency),
                    items: const [
                      DropdownMenuItem(value: TransactionFrequency.daily, child: Text(AppStrings.frequencyDaily)),
                      DropdownMenuItem(value: TransactionFrequency.weekly, child: Text(AppStrings.frequencyWeekly)),
                      DropdownMenuItem(value: TransactionFrequency.monthly, child: Text(AppStrings.frequencyMonthly)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      cubit.setFrequency(v);
                    },
                  ),
                ],
              ],
              if (!isQuickUi &&
                  state.mode != DepositBottomSheetMode.fullDepositToGoal) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.allocateNowOptional,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (state.goals.isEmpty) ...[
                  Text(AppStrings.noGoalsYetUnallocated, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                ] else ...[
                  for (var i = 0; i < _allocations.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: SproutDropdownField<String>(
                            identifier: SemanticsIds.depositGoalDropdown,
                            label: AppStrings.selectGoal,
                            value: _allocations[i].goalId,
                            decoration: const InputDecoration(labelText: AppStrings.selectGoal),
                            items: [
                              for (final g in state.goals)
                                DropdownMenuItem(value: g.id, child: Text(g.name)),
                            ],
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
                        SproutIconButton(
                          identifier: SemanticsIds.depositRemoveAllocation,
                          label: AppStrings.removeAllocation,
                          tooltip: AppStrings.remove,
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
                    child: SproutTextButton.icon(
                      identifier: SemanticsIds.depositAddAllocation,
                      label: AppStrings.addAnotherGoal,
                      onPressed: () {
                        setState(() {
                          _allocations.add(
                            _AllocationRow(
                              goalId: state.goalId,
                              amountController: TextEditingController(),
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                      labelWidget: const Text(AppStrings.addAnotherGoal),
                    ),
                  ),
                ],
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              SproutFilledButton(
                identifier: SemanticsIds.depositSave,
                label: AppStrings.save,
                onPressed: state.submitting ? null : () => _submit(cubit, state),
              ),
            ],
          ),
        );
      },
    );
  }
}

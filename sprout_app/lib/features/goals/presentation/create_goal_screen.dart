import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import '../application/goals_service.dart';
import 'create_goal_bloc.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key, required this.defaultColor});

  final Color defaultColor;

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _alreadySaved;

  late int _colorArgb;
  int _alreadySavedCents = 0;
  String? _alreadySavedAccountId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _target = TextEditingController();
    _alreadySaved = TextEditingController();
    _name.addListener(_onFieldChanged);
    _target.addListener(_onFieldChanged);
    _alreadySaved.addListener(_onAlreadySavedChanged);
    _colorArgb = widget.defaultColor.toARGB32();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onAlreadySavedChanged() {
    final cents = parseZarToCents(_alreadySaved.text) ?? 0;
    if (mounted) {
      setState(() {
        _alreadySavedCents = cents > 0 ? cents : 0;
        if (_alreadySavedCents == 0) _alreadySavedAccountId = null;
      });
    }
  }

  String? get _targetError {
    final state = classifyPositiveZarField(_target.text);
    return switch (state) {
      PositiveZarFieldState.empty => null,
      PositiveZarFieldState.incomplete => null,
      PositiveZarFieldState.invalid => AppStrings.invalidAmount,
      PositiveZarFieldState.negative => AppStrings.amountCannotBeNegative,
      PositiveZarFieldState.notPositive => AppStrings.goalTargetMustBePositive,
      PositiveZarFieldState.ok => null,
    };
  }

  String? get _alreadySavedError {
    final t = _alreadySaved.text.trim();
    if (t.isEmpty) return null;
    final normalized = t.replaceAll(' ', '').replaceAll(',', '.');
    if (normalized == '-' ||
        normalized == '-.' ||
        normalized == '+' ||
        normalized == '+.') {
      return null;
    }
    final value = double.tryParse(normalized);
    if (value == null) return AppStrings.invalidAmount;
    if (value < 0) return AppStrings.amountCannotBeNegative;
    return null;
  }

  bool _canSubmit(CreateGoalReady s) {
    final name = _name.text.trim();
    if (name.isEmpty) return false;
    if (classifyPositiveZarField(_target.text) != PositiveZarFieldState.ok) {
      return false;
    }
    if (_alreadySavedError != null) {
      return false;
    }
    if (_alreadySavedCents > 0 && (_alreadySavedAccountId == null)) return false;
    if (s.submitting) return false;
    return true;
  }

  void _submit(BuildContext blocContext, CreateGoalReady s) {
    if (!_canSubmit(s)) return;
    final name = _name.text.trim();
    final targetCents = parseZarToCents(_target.text);
    if (targetCents == null || targetCents <= 0) return;

    blocContext.read<CreateGoalBloc>().add(
          CreateGoalSubmitted(
            name: name,
            targetAmountCents: targetCents,
            colorArgb: _colorArgb,
            alreadySavedAmountCents: _alreadySavedCents,
            alreadySavedAccountId: _alreadySavedAccountId,
          ),
        );
  }

  @override
  void dispose() {
    _name.removeListener(_onFieldChanged);
    _target.removeListener(_onFieldChanged);
    _alreadySaved.removeListener(_onAlreadySavedChanged);
    _name.dispose();
    _target.dispose();
    _alreadySaved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateGoalBloc(
        goalsService: sl<GoalsService>(),
        accountsService: sl<AccountsService>(),
        transactionsService: sl<TransactionsService>(),
        userContext: sl<UserContext>(),
      )..add(const CreateGoalStarted()),
      child: BlocConsumer<CreateGoalBloc, CreateGoalState>(
        listenWhen: (prev, next) => next is CreateGoalSuccess,
        listener: (context, state) {
          if (state is CreateGoalSuccess) {
            Navigator.of(context).pop(state.goalId);
          }
        },
        builder: (context, state) {
          if (state is! CreateGoalReady) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final showOpening = _alreadySavedCents > 0;
          final canSubmit = _canSubmit(state);

          return NameColorFormSheet(
            title: AppStrings.newGoal,
            nameLabel: AppStrings.goalName,
            nameController: _name,
            nameErrorText: null,
            colorArgb: _colorArgb,
            onColorSelected: (argb) => setState(() => _colorArgb = argb),
            primaryActionLabel: AppStrings.save,
            onPrimaryAction: () => _submit(context, state),
            primaryActionEnabled: canSubmit,
            body: [
              const SizedBox(height: 12),
              TextField(
                controller: _target,
                decoration: InputDecoration(
                  labelText: AppStrings.targetAmount,
                  errorText: _targetError,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alreadySaved,
                decoration: InputDecoration(
                  labelText: 'Already Saved Amount (ZAR)',
                  errorText: _alreadySavedError,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              if (showOpening) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _alreadySavedAccountId, // ignore: deprecated_member_use
                  decoration: const InputDecoration(
                    labelText: 'Which Account holds this money?',
                  ),
                  items: [
                    for (final a in state.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _alreadySavedAccountId = v),
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (state.submitting) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
            ],
          );
        },
      ),
    );
  }
}


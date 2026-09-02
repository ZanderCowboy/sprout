import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/ui/export.dart';

import '../application/goals_service.dart';
import 'create_goal_bloc.dart';
import 'widgets/goal_icon_picker.dart';

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
  late IconData _icon;
  late final FocusNode _targetFocus;
  late final FocusNode _alreadySavedFocus;
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
    _icon = GoalIconPicker.defaultIcon;
    _targetFocus = FocusNode()..addListener(_onFieldChanged);
    _alreadySavedFocus = FocusNode()..addListener(_onFieldChanged);
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
    if (_alreadySavedCents > 0 && (_alreadySavedAccountId == null)) {
      return false;
    }
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
        iconCodePoint: _icon.codePoint,
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
    _targetFocus.removeListener(_onFieldChanged);
    _alreadySavedFocus.removeListener(_onFieldChanged);
    _targetFocus.dispose();
    _alreadySavedFocus.dispose();
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

          // If no accounts, show a message with CTA to create one
          if (state.accounts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.newGoal,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.createAccountFirst,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  SproutFilledButton.icon(
                    identifier: SemanticsIds.goalNoAccountsNewAccount,
                    label: AppStrings.newAccount,
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => AccountFormSheet(
                          defaultColor: AppColors.cardColorAt(0),
                        ),
                      );
                      if (context.mounted) {
                        context.read<CreateGoalBloc>().add(
                          const CreateGoalStarted(),
                        );
                      }
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    labelWidget: const Text(AppStrings.newAccount),
                  ),
                  const SizedBox(height: 12),
                  SproutOutlinedButton(
                    identifier: SemanticsIds.goalNoAccountsCancel,
                    label: AppStrings.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }

          final showOpening = _alreadySavedCents > 0;
          final canSubmit = _canSubmit(state);

          return NameColorFormSheet(
            title: AppStrings.newGoal,
            nameLabel: AppStrings.goalName,
            nameController: _name,
            nameErrorText: null,
            nameHelperText: AppStrings.required,
            colorArgb: _colorArgb,
            onColorSelected: (argb) => setState(() => _colorArgb = argb),
            primaryActionLabel: AppStrings.save,
            onPrimaryAction: () => _submit(context, state),
            primaryActionEnabled: canSubmit,
            nameFieldKey: const Key('goal_name_field'),
            nameFieldIdentifier: SemanticsIds.goalNameField,
            body: [
              const SizedBox(height: 12),
              SproutTextField(
                identifier: SemanticsIds.goalTargetField,
                fieldKey: const Key('goal_target_field'),
                controller: _target,
                focusNode: _targetFocus,
                decoration: InputDecoration(
                  labelText: AppStrings.targetAmountShort,
                  errorText: _targetError,
                  helperText: _targetError == null ? AppStrings.required : null,
                  prefixText: _targetFocus.hasFocus || _target.text.isNotEmpty
                      ? AppStrings.currencyPrefix
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              const SizedBox(height: 12),
              SproutTextField(
                identifier: SemanticsIds.goalAlreadySavedField,
                controller: _alreadySaved,
                focusNode: _alreadySavedFocus,
                decoration: InputDecoration(
                  labelText: AppStrings.alreadySavedAmountShort,
                  errorText: _alreadySavedError,
                  prefixText:
                      _alreadySavedFocus.hasFocus ||
                          _alreadySaved.text.isNotEmpty
                      ? AppStrings.currencyPrefix
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              if (showOpening) ...[
                const SizedBox(height: 12),
                SproutDropdownField<String>(
                  identifier: SemanticsIds.goalAlreadySavedAccount,
                  label: AppStrings.whichAccountHoldsMoney,
                  value: _alreadySavedAccountId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.whichAccountHoldsMoney,
                  ),
                  items: [
                    for (final a in state.accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _alreadySavedAccountId = v),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                AppStrings.icon,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              GoalIconPicker(
                selected: _icon,
                accent: Color(_colorArgb),
                onSelected: (icon) => setState(() => _icon = icon),
              ),
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

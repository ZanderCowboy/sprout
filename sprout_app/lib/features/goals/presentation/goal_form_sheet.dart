import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/ui/export.dart';

import '../application/goals_service.dart';
import '../domain/goal.dart';
import 'goal_form_cubit.dart';
import 'widgets/goal_icon_picker.dart';

class GoalFormSheet extends StatelessWidget {
  const GoalFormSheet({super.key, this.initial, required this.defaultColor});

  final Goal? initial;
  final Color defaultColor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GoalFormCubit(
        goalsService: sl<GoalsService>(),
        userContext: sl<UserContext>(),
        initial: initial,
        defaultColorArgb: defaultColor.toARGB32(),
      )..load(),
      child: _GoalFormBody(initial: initial),
    );
  }
}

class _GoalFormBody extends StatefulWidget {
  const _GoalFormBody({required this.initial});

  final Goal? initial;

  @override
  State<_GoalFormBody> createState() => _GoalFormBodyState();
}

class _GoalFormBodyState extends State<_GoalFormBody> {
  late final TextEditingController _name;
  late final TextEditingController _target;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _target = TextEditingController(
      text: widget.initial != null
          ? (widget.initial!.targetAmountCents / 100).toStringAsFixed(2)
          : '',
    );
    _name.addListener(_onNameChanged);
    _target.addListener(_onTargetChanged);
  }

  void _onNameChanged() {
    context.read<GoalFormCubit>().nameChanged(_name.text);
  }

  void _onTargetChanged() {
    context.read<GoalFormCubit>().targetChanged(_target.text);
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _target.removeListener(_onTargetChanged);
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalFormCubit, GoalFormState>(
      listenWhen: (previous, current) =>
          current is GoalFormSaved ||
          (current is GoalFormReady && current.submitError != null),
      listener: (context, state) {
        if (state is GoalFormSaved) {
          Navigator.of(context).pop(state.goal);
          return;
        }
        if (state is GoalFormReady && state.submitError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.submitError!)));
        }
      },
      builder: (context, state) {
        final ready = state is GoalFormReady ? state : null;
        return NameColorFormSheet(
          title: widget.initial == null ? AppStrings.newGoal : AppStrings.edit,
          nameLabel: AppStrings.goalName,
          nameController: _name,
          nameErrorText: ready?.nameError,
          nameFieldIdentifier: SemanticsIds.goalNameField,
          colorArgb: ready?.colorArgb ?? 0,
          onColorSelected: (argb) =>
              context.read<GoalFormCubit>().colorChanged(argb),
          primaryActionLabel: AppStrings.save,
          onPrimaryAction: () => context.read<GoalFormCubit>().submit(),
          primaryActionEnabled: ready?.canSave ?? false,
          body: [
            const SizedBox(height: 12),
            SproutTextField(
              identifier: SemanticsIds.goalTargetField,
              fieldKey: const Key('goal_target_field'),
              controller: _target,
              decoration: InputDecoration(
                labelText: AppStrings.targetAmount,
                errorText: ready?.targetError,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.icon,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            GoalIconPicker(
              selected: goalIconFromStored(codePoint: ready?.iconCodePoint),
              accent: Color(ready?.colorArgb ?? widget.initial?.color ?? 0),
              onSelected: (icon) =>
                  context.read<GoalFormCubit>().iconChanged(icon.codePoint),
            ),
          ],
        );
      },
    );
  }
}

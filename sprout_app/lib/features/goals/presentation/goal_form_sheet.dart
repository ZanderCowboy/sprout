import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/ui/export.dart';
import '../application/goals_service.dart';
import '../domain/goal.dart';

class GoalFormSheet extends StatefulWidget {
  const GoalFormSheet({
    super.key,
    this.initial,
    required this.defaultColor,
  });

  final Goal? initial;
  final Color defaultColor;

  @override
  State<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<GoalFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late int _colorArgb;
  static const _uuid = Uuid();

  List<Goal> _goals = [];
  bool _goalsLoaded = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _target = TextEditingController(
      text: widget.initial != null
          ? (widget.initial!.targetAmountCents / 100).toStringAsFixed(2)
          : '',
    );
    _name.addListener(_onFieldChanged);
    _target.addListener(_onFieldChanged);
    _colorArgb =
        widget.initial?.color ?? widget.defaultColor.toARGB32();
    _loadGoals();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGoals() async {
    final list = await sl<GoalsService>().getGoals();
    if (!mounted) return;
    setState(() {
      _goals = list;
      _goalsLoaded = true;
    });
  }

  String? get _nameError {
    final name = _name.text.trim();
    if (name.isEmpty) return null;
    final key = name.toLowerCase();
    final taken = _goals.any(
      (g) =>
          g.id != widget.initial?.id &&
          g.name.trim().toLowerCase() == key,
    );
    if (taken) return AppStrings.duplicateGoalName;
    return null;
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

  bool get _canSave {
    if (!_goalsLoaded) return false;
    final name = _name.text.trim();
    if (name.isEmpty) return false;
    if (_nameError != null) return false;
    return classifyPositiveZarField(_target.text) == PositiveZarFieldState.ok;
  }

  @override
  void dispose() {
    _name.removeListener(_onFieldChanged);
    _target.removeListener(_onFieldChanged);
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final name = _name.text.trim();
    final cents = parseZarToCents(_target.text);
    if (cents == null || cents <= 0) return;
    final uid = await sl<UserContext>().resolveUserId();
    final now = DateTime.now();
    final goal = Goal(
      id: widget.initial?.id ?? _uuid.v4(),
      userId: uid,
      name: name,
      targetAmountCents: cents,
      color: _colorArgb,
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await sl<GoalsService>().saveGoal(goal);
    } on ValidationAppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop(goal);
  }

  @override
  Widget build(BuildContext context) {
    return NameColorFormSheet(
      title: widget.initial == null ? AppStrings.newGoal : AppStrings.edit,
      nameLabel: AppStrings.goalName,
      nameController: _name,
      nameErrorText: _nameError,
      colorArgb: _colorArgb,
      onColorSelected: (argb) => setState(() => _colorArgb = argb),
      primaryActionLabel: AppStrings.save,
      onPrimaryAction: _save,
      primaryActionEnabled: _canSave,
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
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/ui/export.dart';

import '../../application/budget_service.dart';
import '../../domain/budget_category.dart';
import '../../domain/budget_group.dart';
import '../budget_group_form_cubit.dart';
import 'budget_group_icon_picker.dart';

class AddGroupSheet extends StatelessWidget {
  const AddGroupSheet({super.key, this.initial});

  final BudgetGroup? initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BudgetGroupFormCubit(
        budgetService: sl<BudgetService>(),
        userContext: sl<UserContext>(),
        initial: initial,
      )..load(),
      child: _AddGroupBody(initial: initial),
    );
  }
}

class _AddGroupBody extends StatefulWidget {
  const _AddGroupBody({required this.initial});

  final BudgetGroup? initial;

  @override
  State<_AddGroupBody> createState() => _AddGroupBodyState();
}

class _AddGroupBodyState extends State<_AddGroupBody> {
  late final TextEditingController _name;
  late final TextEditingController _description;

  int _colorArgb = AppColors.cardPalette.first.toARGB32();
  IconData _icon = Icons.category_rounded;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _description = TextEditingController(text: i?.description ?? '');
    _name.addListener(_onNameChanged);
    _description.addListener(_onDescriptionChanged);

    _colorArgb =
        _parseHexColor(i?.colorHex)?.toARGB32() ??
        AppColors.cardColorAt(0).toARGB32();
    _icon = budgetGroupIconFromStored(
      codePoint: i?.iconCodePoint,
      fontFamily: i?.iconFontFamily,
    );
  }

  void _onNameChanged() {
    context.read<BudgetGroupFormCubit>().nameChanged(_name.text);
  }

  void _onDescriptionChanged() {
    context.read<BudgetGroupFormCubit>().descriptionChanged(_description.text);
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _description.removeListener(_onDescriptionChanged);
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    context.read<BudgetGroupFormCubit>().submit(
      iconCodePoint: _icon.codePoint,
      iconFontFamily: _icon.fontFamily,
      colorHex: budgetGroupColorToHex(Color(_colorArgb)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;

    return BlocConsumer<BudgetGroupFormCubit, BudgetGroupFormState>(
      listenWhen: (previous, current) =>
          current is BudgetGroupFormSaved ||
          (current is BudgetGroupFormReady && current.submitError != null),
      listener: (context, state) {
        if (state is BudgetGroupFormSaved) {
          Navigator.of(context).pop(state.group);
          return;
        }
        if (state is BudgetGroupFormReady && state.submitError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.submitError!)));
        }
      },
      builder: (context, state) {
        final ready = state is BudgetGroupFormReady ? state : null;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomPadding + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initial == null
                      ? AppStrings.newBudgetGroup
                      : AppStrings.editGroup,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: AppStrings.groupName,
                    errorText: ready?.nameError,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: AppStrings.descriptionOptional,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BudgetCategory>(
                  initialValue: ready?.category ?? BudgetCategory.income,
                  decoration: const InputDecoration(
                    labelText: AppStrings.category,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: BudgetCategory.income,
                      child: Text(AppStrings.budgetIncome),
                    ),
                    DropdownMenuItem(
                      value: BudgetCategory.essentials,
                      child: Text(AppStrings.budgetEssentials),
                    ),
                    DropdownMenuItem(
                      value: BudgetCategory.lifestyle,
                      child: Text(AppStrings.budgetLifestyle),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    context.read<BudgetGroupFormCubit>().categoryChanged(v);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.color,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in AppColors.cardPalette)
                      GestureDetector(
                        onTap: () => setState(() => _colorArgb = c.toARGB32()),
                        child: CircleAvatar(
                          backgroundColor: c,
                          child: _colorArgb == c.toARGB32()
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.icon,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                BudgetGroupIconPicker(
                  selected: _icon,
                  onSelected: (i) => setState(() => _icon = i),
                  accent: Color(_colorArgb),
                ),
                const SizedBox(height: 24),
                SproutFilledButton(
                  identifier: SemanticsIds.budgetGroupSave,
                  label: AppStrings.save,
                  onPressed: (ready?.canSave ?? false) ? _save : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  var t = hex.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('#')) t = t.substring(1);
  if (t.length == 6) t = 'FF$t';
  if (t.length != 8) return null;
  final v = int.tryParse(t, radix: 16);
  if (v == null) return null;
  return Color(v);
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';

import '../../application/budget_service.dart';
import '../../domain/budget_category.dart';
import '../../domain/budget_group.dart';
import '../budget_bloc.dart';
import 'budget_group_icon_picker.dart';

class AddGroupSheet extends StatefulWidget {
  const AddGroupSheet({super.key, this.initial});

  final BudgetGroup? initial;

  @override
  State<AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends State<AddGroupSheet> {
  static const _uuid = Uuid();

  late final TextEditingController _name;
  late final TextEditingController _description;

  BudgetCategory _category = BudgetCategory.income;
  int _colorArgb = AppColors.cardPalette.first.toARGB32();
  IconData _icon = Icons.category_rounded;

  List<BudgetGroup> _existing = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _description = TextEditingController(text: i?.description ?? '');
    _name.addListener(_onFieldChanged);
    _description.addListener(_onFieldChanged);

    _category = i?.category ?? BudgetCategory.income;
    _colorArgb = _parseHexColor(i?.colorHex)?.toARGB32() ?? AppColors.cardColorAt(0).toARGB32();
    _icon = _iconFromStored(codePoint: i?.iconCodePoint, fontFamily: i?.iconFontFamily) ?? Icons.category_rounded;

    _loadExisting();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadExisting() async {
    final list = await sl<BudgetService>().getBudgetGroups();
    if (!mounted) return;
    setState(() {
      _existing = list;
      _loaded = true;
    });
  }

  String? get _nameError {
    final name = _name.text.trim();
    if (name.isEmpty) return null;
    final key = name.toLowerCase();
    final taken = _existing.any((g) => g.id != widget.initial?.id && g.name.trim().toLowerCase() == key);
    if (taken) return 'You already have a group with this name.';
    return null;
  }

  bool get _canSave {
    if (!_loaded) return false;
    final name = _name.text.trim();
    if (name.isEmpty) return false;
    if (_nameError != null) return false;
    return true;
  }

  @override
  void dispose() {
    _name.removeListener(_onFieldChanged);
    _description.removeListener(_onFieldChanged);
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final uid = await sl<UserContext>().resolveUserId();
    final now = DateTime.now();
    final description = _description.text.trim();
    final group = BudgetGroup(
      id: widget.initial?.id ?? _uuid.v4(),
      userId: uid,
      name: _name.text.trim(),
      description: description.isEmpty ? null : description,
      category: _category,
      colorHex: budgetGroupColorToHex(Color(_colorArgb)),
      iconCodePoint: _icon.codePoint,
      iconFontFamily: _icon.fontFamily,
      items: widget.initial?.items ?? const [],
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
    );

    if (!mounted) return;
    context.read<BudgetBloc>().add(BudgetGroupUpsertRequested(group));
    Navigator.of(context).pop(group);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'New budget group' : 'Edit group',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: 'Group name', errorText: _nameError),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BudgetCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: BudgetCategory.income, child: Text('Income')),
                DropdownMenuItem(value: BudgetCategory.essentials, child: Text('Essentials')),
                DropdownMenuItem(value: BudgetCategory.lifestyle, child: Text('Lifestyle')),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
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
                      child: _colorArgb == c.toARGB32() ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            BudgetGroupIconPicker(
              selected: _icon,
              onSelected: (i) => setState(() => _icon = i),
              accent: Color(_colorArgb),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _canSave ? _save : null, child: const Text(AppStrings.save)),
          ],
        ),
      ),
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

IconData? _iconFromStored({required int? codePoint, required String? fontFamily}) {
  if (codePoint == null) return null;
  return IconData(codePoint, fontFamily: fontFamily ?? 'MaterialIcons');
}

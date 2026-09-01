import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';

import '../utils/budget_sorting.dart';

class BudgetSortModal extends StatefulWidget {
  const BudgetSortModal({
    super.key,
    required this.initialGroupSort,
    required this.initialItemSort,
  });

  final BudgetSortOption initialGroupSort;
  final BudgetSortOption initialItemSort;

  @override
  State<BudgetSortModal> createState() => _BudgetSortModalState();
}

class _BudgetSortModalState extends State<BudgetSortModal> {
  late BudgetSortOption _groupSort;
  late BudgetSortOption _itemSort;

  @override
  void initState() {
    super.initState();
    _groupSort = widget.initialGroupSort;
    _itemSort = widget.initialItemSort;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.sortBudget,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BudgetSortOption>(
              initialValue: _groupSort,
              decoration: const InputDecoration(labelText: AppStrings.groups),
              items: [
                for (final opt in BudgetSortOption.values)
                  DropdownMenuItem(
                    value: opt,
                    child: Text(budgetSortOptionLabel(opt)),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _groupSort = v);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<BudgetSortOption>(
              initialValue: _itemSort,
              decoration: const InputDecoration(labelText: AppStrings.items),
              items: [
                for (final opt in BudgetSortOption.values)
                  DropdownMenuItem(
                    value: opt,
                    child: Text(budgetSortOptionLabel(opt)),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _itemSort = v);
              },
            ),
            const SizedBox(height: 18),
            SproutFilledButton(
              identifier: SemanticsIds.budgetSortSave,
              label: AppStrings.done,
              onPressed: () => Navigator.of(
                context,
              ).pop((groupSort: _groupSort, itemSort: _itemSort)),
              child: const Text(AppStrings.done),
            ),
          ],
        ),
      ),
    );
  }
}

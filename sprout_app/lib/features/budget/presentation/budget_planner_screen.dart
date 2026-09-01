import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';

import '../application/budget_service.dart';
import '../domain/budget_category.dart';
import 'budget_bloc.dart';
import 'utils/budget_sorting.dart';
import 'widgets/budget_category_tab.dart';
import 'widgets/budget_sort_modal.dart';
import 'widgets/budget_summary_header.dart';
import 'widgets/budget_tab_header.dart';
import 'package:sprout/ui/export.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  BudgetSortOption _groupSort = BudgetSortOption.asIs;
  BudgetSortOption _itemSort = BudgetSortOption.asIs;

  Future<void> _openSortModal() async {
    final initialGroupSort = _groupSort;
    final initialItemSort = _itemSort;

    final selected =
        await showModalBottomSheet<
          ({BudgetSortOption groupSort, BudgetSortOption itemSort})
        >(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => BudgetSortModal(
            initialGroupSort: initialGroupSort,
            initialItemSort: initialItemSort,
          ),
        );

    if (!mounted || selected == null) return;
    setState(() {
      _groupSort = selected.groupSort;
      _itemSort = selected.itemSort;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BudgetBloc(budgetService: sl<BudgetService>())
            ..add(const BudgetSubscriptionRequested()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.masterBudget),
            actions: [
              SproutIconButton(
                identifier: SemanticsIds.budgetSort,
                label: AppStrings.sortBudget,
                tooltip: AppStrings.sortBudget,
                onPressed: _openSortModal,
                icon: const Icon(Icons.sort_rounded),
              ),
            ],
          ),
          body: BlocBuilder<BudgetBloc, BudgetState>(
            builder: (context, state) {
              if (state is! BudgetReady) {
                return const Center(child: CircularProgressIndicator());
              }

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: BudgetSummaryHeader(state: state),
                    ),
                    const BudgetTabHeader(),
                    Expanded(
                      child: TabBarView(
                        children: [
                          BudgetCategoryTab(
                            category: BudgetCategory.income,
                            groups: state.groups,
                            totals: state.groupTotals,
                            groupSort: _groupSort,
                            itemSort: _itemSort,
                          ),
                          BudgetCategoryTab(
                            category: BudgetCategory.essentials,
                            groups: state.groups,
                            totals: state.groupTotals,
                            groupSort: _groupSort,
                            itemSort: _itemSort,
                          ),
                          BudgetCategoryTab(
                            category: BudgetCategory.lifestyle,
                            groups: state.groups,
                            totals: state.groupTotals,
                            groupSort: _groupSort,
                            itemSort: _itemSort,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

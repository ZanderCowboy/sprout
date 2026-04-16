import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';

import '../application/budget_service.dart';
import '../domain/budget_category.dart';
import '../domain/budget_group.dart';
import 'budget_bloc.dart';
import 'utils/budget_sorting.dart';
import 'widgets/add_group_card.dart';
import 'widgets/group_card.dart';

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

    final selected = await showModalBottomSheet<({BudgetSortOption groupSort, BudgetSortOption itemSort})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _BudgetSortModal(initialGroupSort: initialGroupSort, initialItemSort: initialItemSort),
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
      create: (_) => BudgetBloc(budgetService: sl<BudgetService>())..add(const BudgetSubscriptionRequested()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Master Budget'),
            actions: [
              IconButton(onPressed: _openSortModal, tooltip: 'Sort budget', icon: const Icon(Icons.sort_rounded)),
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
                      child: _BudgetSummaryHeader(state: state),
                    ),
                    const _BudgetTabHeader(),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _BudgetCategoryTab(
                            category: BudgetCategory.income,
                            groups: state.groups,
                            totals: state.groupTotals,
                            groupSort: _groupSort,
                            itemSort: _itemSort,
                          ),
                          _BudgetCategoryTab(
                            category: BudgetCategory.essentials,
                            groups: state.groups,
                            totals: state.groupTotals,
                            groupSort: _groupSort,
                            itemSort: _itemSort,
                          ),
                          _BudgetCategoryTab(
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

class _BudgetSortModal extends StatefulWidget {
  const _BudgetSortModal({required this.initialGroupSort, required this.initialItemSort});

  final BudgetSortOption initialGroupSort;
  final BudgetSortOption initialItemSort;

  @override
  State<_BudgetSortModal> createState() => _BudgetSortModalState();
}

class _BudgetSortModalState extends State<_BudgetSortModal> {
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Sort budget', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            DropdownButtonFormField<BudgetSortOption>(
              initialValue: _groupSort,
              decoration: const InputDecoration(labelText: 'Groups'),
              items: [
                for (final opt in BudgetSortOption.values)
                  DropdownMenuItem(value: opt, child: Text(budgetSortOptionLabel(opt))),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _groupSort = v);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<BudgetSortOption>(
              initialValue: _itemSort,
              decoration: const InputDecoration(labelText: 'Items'),
              items: [
                for (final opt in BudgetSortOption.values)
                  DropdownMenuItem(value: opt, child: Text(budgetSortOptionLabel(opt))),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _itemSort = v);
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((groupSort: _groupSort, itemSort: _itemSort)),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSummaryHeader extends StatefulWidget {
  const _BudgetSummaryHeader({required this.state});

  final BudgetReady state;

  @override
  State<_BudgetSummaryHeader> createState() => _BudgetSummaryHeaderState();
}

class _BudgetSummaryHeaderState extends State<_BudgetSummaryHeader> {
  bool _showBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = widget.state;
    final disposableCents = (state.disposableIncome * 100).round();
    final isNegative = disposableCents < 0;
    final valueColor = isNegative ? scheme.error : scheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, _showBreakdown ? 14 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _showBreakdown = !_showBreakdown),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.account_tree_rounded, size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Theoretical disposable income',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Icon(
                        _showBreakdown ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatZarFromCents(disposableCents),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: valueColor),
            ),
            if (!_showBreakdown) ...[
              const SizedBox(height: 4),
              Text(
                'Tap above for breakdown',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (_showBreakdown) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MiniTotalPill(
                    label: 'Income',
                    value: formatZarFromCents((state.totalIncome * 100).round()),
                    icon: Icons.trending_up_rounded,
                    color: scheme.primary,
                  ),
                  _MiniTotalPill(
                    label: 'Essentials',
                    value: formatZarFromCents((state.totalEssentials * 100).round()),
                    icon: Icons.home_rounded,
                    color: scheme.tertiary,
                  ),
                  _MiniTotalPill(
                    label: 'Lifestyle',
                    value: formatZarFromCents((state.totalLifestyle * 100).round()),
                    icon: Icons.local_cafe_rounded,
                    color: scheme.secondary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetTabHeader extends StatelessWidget {
  const _BudgetTabHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        tabs: const [
          Tab(height: 42, text: 'Income'),
          Tab(height: 42, text: 'Essentials'),
          Tab(height: 42, text: 'Lifestyle'),
        ],
      ),
    );
  }
}

class _MiniTotalPill extends StatelessWidget {
  const _MiniTotalPill({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
          ),
          Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _BudgetCategoryTab extends StatelessWidget {
  const _BudgetCategoryTab({
    required this.category,
    required this.groups,
    required this.totals,
    required this.groupSort,
    required this.itemSort,
  });

  final BudgetCategory category;
  final List<BudgetGroup> groups;
  final Map<String, double> totals;
  final BudgetSortOption groupSort;
  final BudgetSortOption itemSort;

  @override
  Widget build(BuildContext context) {
    return _BudgetCategoryTabBody(
      category: category,
      groups: groups,
      totals: totals,
      groupSort: groupSort,
      itemSort: itemSort,
    );
  }
}

class _BudgetCategoryTabBody extends StatefulWidget {
  const _BudgetCategoryTabBody({
    required this.category,
    required this.groups,
    required this.totals,
    required this.groupSort,
    required this.itemSort,
  });

  final BudgetCategory category;
  final List<BudgetGroup> groups;
  final Map<String, double> totals;
  final BudgetSortOption groupSort;
  final BudgetSortOption itemSort;

  @override
  State<_BudgetCategoryTabBody> createState() => _BudgetCategoryTabBodyState();
}

class _BudgetCategoryTabBodyState extends State<_BudgetCategoryTabBody> {
  static const _uuid = Uuid();

  final List<BudgetGroup> _draftGroups = [];

  List<BudgetGroup> get _existing => widget.groups.where((g) => g.category == widget.category).toList();

  List<BudgetGroup> get _drafts => _draftGroups.where((g) => g.category == widget.category).toList();

  Future<void> _addDraft() async {
    final uid = await sl<UserContext>().resolveUserId();
    if (!mounted) return;
    setState(() {
      _draftGroups.add(
        BudgetGroup(
          id: _uuid.v4(),
          userId: uid,
          name: '',
          description: null,
          category: widget.category,
          colorHex: '#FF5D6CFF',
          iconCodePoint: Icons.category_rounded.codePoint,
          iconFontFamily: Icons.category_rounded.fontFamily,
          items: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void _removeDraft(String groupId) {
    setState(() => _draftGroups.removeWhere((g) => g.id == groupId));
  }

  void _upsertDraft(BudgetGroup updated) {
    final idx = _draftGroups.indexWhere((g) => g.id == updated.id);
    if (idx == -1) return;
    setState(() => _draftGroups[idx] = updated);
  }

  @override
  Widget build(BuildContext context) {
    final separator = const SizedBox(height: 2);
    final all = [..._existing, ..._drafts];
    final allSorted = sortBudgetGroups(all, widget.groupSort);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset + 18),
      itemCount: allSorted.length + 1,
      separatorBuilder: (context, index) => separator,
      itemBuilder: (context, i) {
        if (i == allSorted.length) {
          return AddGroupCard(onTap: _addDraft);
        }

        final g = allSorted[i];
        final isDraft = _draftGroups.any((d) => d.id == g.id);
        final total = widget.totals[g.id] ?? 0.0;

        return GroupCard(
          key: ValueKey(g.id),
          group: g,
          totalAmount: total,
          itemSort: widget.itemSort,
          initiallyExpanded: isDraft,
          isDraft: isDraft,
          onDiscardDraft: isDraft ? () => _removeDraft(g.id) : null,
          onDraftChanged: isDraft ? _upsertDraft : null,
          allGroupsForNameValidation: widget.groups,
          onUpsertGroup: (updated) => context.read<BudgetBloc>().add(BudgetGroupUpsertRequested(updated)),
          onDeleteGroup: (groupId) => context.read<BudgetBloc>().add(BudgetGroupDeleted(groupId)),
          onUpsertItem: (groupId, item) =>
              context.read<BudgetBloc>().add(BudgetItemUpsertRequested(groupId: groupId, item: item)),
          onDeleteItem: (groupId, itemId) =>
              context.read<BudgetBloc>().add(BudgetItemDeleted(groupId: groupId, itemId: itemId)),
        );
      },
    );
  }
}

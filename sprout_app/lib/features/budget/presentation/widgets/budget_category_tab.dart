import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';

import '../../domain/budget_category.dart';
import '../../domain/budget_group.dart';
import '../budget_bloc.dart';
import '../utils/budget_sorting.dart';
import 'add_group_card.dart';
import 'group_card.dart';

class BudgetCategoryTab extends StatelessWidget {
  const BudgetCategoryTab({
    super.key,
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
    return BudgetCategoryTabBody(
      category: category,
      groups: groups,
      totals: totals,
      groupSort: groupSort,
      itemSort: itemSort,
    );
  }
}

class BudgetCategoryTabBody extends StatefulWidget {
  const BudgetCategoryTabBody({
    super.key,
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
  State<BudgetCategoryTabBody> createState() => _BudgetCategoryTabBodyState();
}

class _BudgetCategoryTabBodyState extends State<BudgetCategoryTabBody> {
  static const _uuid = Uuid();

  final List<BudgetGroup> _draftGroups = [];

  List<BudgetGroup> get _existing =>
      widget.groups.where((g) => g.category == widget.category).toList();

  List<BudgetGroup> get _drafts =>
      _draftGroups.where((g) => g.category == widget.category).toList();

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
          onUpsertGroup: (updated) => context.read<BudgetBloc>().add(
            BudgetGroupUpsertRequested(updated),
          ),
          onDeleteGroup: (groupId) =>
              context.read<BudgetBloc>().add(BudgetGroupDeleted(groupId)),
          onUpsertItem: (groupId, item) => context.read<BudgetBloc>().add(
            BudgetItemUpsertRequested(groupId: groupId, item: item),
          ),
          onDeleteItem: (groupId, itemId) => context.read<BudgetBloc>().add(
            BudgetItemDeleted(groupId: groupId, itemId: itemId),
          ),
        );
      },
    );
  }
}

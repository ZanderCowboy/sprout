import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';

import '../../domain/budget_group.dart';
import '../../domain/budget_item.dart';
import 'budget_group_icon_picker.dart';
import 'budget_item_card.dart';
import '../utils/budget_sorting.dart';

class GroupCard extends StatefulWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.totalAmount,
    required this.itemSort,
    required this.onUpsertGroup,
    required this.onDeleteGroup,
    required this.onUpsertItem,
    required this.onDeleteItem,
    required this.allGroupsForNameValidation,
    this.initiallyExpanded = false,
    this.isDraft = false,
    this.onDiscardDraft,
    this.onDraftChanged,
  });

  final BudgetGroup group;
  final double totalAmount;
  final BudgetSortOption itemSort;

  final ValueChanged<BudgetGroup> onUpsertGroup;
  final ValueChanged<String> onDeleteGroup;
  final void Function(String groupId, BudgetItem item) onUpsertItem;
  final void Function(String groupId, String itemId) onDeleteItem;

  /// Used to prevent dispatching known-invalid group names (duplicates).
  final List<BudgetGroup> allGroupsForNameValidation;

  final bool initiallyExpanded;

  /// Draft groups are local-only until they have a valid name and the user
  /// taps away.
  final bool isDraft;
  final VoidCallback? onDiscardDraft;
  final ValueChanged<BudgetGroup>? onDraftChanged;

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final FocusNode _nameFocus;
  late final FocusNode _descriptionFocus;

  bool _editingName = false;
  bool _editingDescription = false;

  bool _expanded = false;

  final List<BudgetItem> _draftItems = [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group.name);
    _description = TextEditingController(text: widget.group.description ?? '');
    _nameFocus = FocusNode();
    _descriptionFocus = FocusNode();

    _expanded = widget.initiallyExpanded;

    _nameFocus.addListener(_onNameFocusChanged);
    _descriptionFocus.addListener(_onDescriptionFocusChanged);

    if (widget.isDraft && widget.group.name.trim().isEmpty) {
      _editingName = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant GroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the open state when a just-created draft group becomes persisted.
    // The parent uses a stable key so this State can survive that list move.
    if (oldWidget.group.id != widget.group.id ||
        oldWidget.group.name != widget.group.name) {
      if (!_editingName) _name.text = widget.group.name;
    }
    if (oldWidget.group.description != widget.group.description) {
      if (!_editingDescription) {
        _description.text = widget.group.description ?? '';
      }
    }
  }

  void _onNameFocusChanged() {
    if (!_nameFocus.hasFocus && _editingName) {
      _editingName = false;
      _commitGroupChanges();
      if (mounted) setState(() {});
    }
  }

  void _onDescriptionFocusChanged() {
    if (!_descriptionFocus.hasFocus && _editingDescription) {
      _editingDescription = false;
      _commitGroupChanges();
      if (mounted) setState(() {});
    }
  }

  String? _validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return widget.isDraft ? null : 'Name required';
    final key = trimmed.toLowerCase();
    final dup = widget.allGroupsForNameValidation.any(
      (g) => g.id != widget.group.id && g.name.trim().toLowerCase() == key,
    );
    if (dup) return 'You already have a group with this name.';
    return null;
  }

  void _commitGroupChanges() {
    final name = _name.text.trim();
    final description = _description.text.trim();

    if (widget.isDraft) {
      if (name.isEmpty) {
        widget.onDiscardDraft?.call();
        return;
      }
    }

    final err = _validateName(name);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final updated = widget.group.copyWith(
      name: name,
      description: description.isEmpty ? null : description,
      updatedAt: DateTime.now(),
    );

    if (widget.isDraft) {
      // Draft groups are promoted into the persisted list immediately after a
      // valid name is entered, so the card must preserve its expansion state
      // across that transition to keep item entry feeling continuous.
      widget.onDraftChanged?.call(updated);
    }

    widget.onUpsertGroup(updated);
    if (widget.isDraft) {
      widget.onDiscardDraft?.call();
    }
  }

  void _applyAppearance(Color color, IconData icon) {
    final updated = widget.group.copyWith(
      colorHex: budgetGroupColorToHex(color),
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily ?? 'MaterialIcons',
      updatedAt: DateTime.now(),
    );
    if (widget.isDraft) {
      widget.onDraftChanged?.call(updated);
    } else {
      widget.onUpsertGroup(updated);
    }
  }

  Future<void> _showAppearanceSheet() async {
    FocusScope.of(context).unfocus();
    final scheme = Theme.of(context).colorScheme;
    final initialColor =
        _parseHexColor(widget.group.colorHex) ?? scheme.primary;
    var colorArgb = initialColor.toARGB32();
    var icon = _iconForGroup(widget.group);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final accent = Color(colorArgb);
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom:
                      MediaQuery.viewInsetsOf(context).bottom +
                      MediaQuery.paddingOf(context).bottom +
                      20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Color & icon',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in AppColors.cardPalette)
                          GestureDetector(
                            onTap: () =>
                                setModalState(() => colorArgb = c.toARGB32()),
                            child: CircleAvatar(
                              backgroundColor: c,
                              child: colorArgb == c.toARGB32()
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Icon', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    BudgetGroupIconPicker(
                      selected: icon,
                      onSelected: (i) => setModalState(() => icon = i),
                      accent: accent,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        _applyAppearance(Color(colorArgb), icon);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove group?'),
        content: Text(
          'This will remove “${widget.group.name.trim().isEmpty ? 'Untitled group' : widget.group.name}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      widget.onDeleteGroup(widget.group.id);
    }
  }

  void _addDraftItem() {
    setState(() {
      for (var i = 0; i < _draftItems.length; i++) {
        final it = _draftItems[i];
        if (it.name.trim().isEmpty) {
          _draftItems[i] = it.copyWith(name: BudgetItem.defaultDraftName);
        }
      }
      _draftItems.add(
        BudgetItem(id: UniqueKey().toString(), name: '', amount: 0.0),
      );
    });
  }

  void _discardDraftItem(String itemId) {
    setState(() => _draftItems.removeWhere((x) => x.id == itemId));
  }

  void _upsertDraftItem(BudgetItem updated) {
    final idx = _draftItems.indexWhere((x) => x.id == updated.id);
    if (idx == -1) return;
    setState(() => _draftItems[idx] = updated);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocusChanged);
    _descriptionFocus.removeListener(_onDescriptionFocusChanged);
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _parseHexColor(widget.group.colorHex) ?? scheme.primary;
    final icon = _iconForGroup(widget.group);

    final itemsUnsorted = [...widget.group.items, ..._draftItems];
    final items = sortBudgetItems(itemsUnsorted, widget.itemSort);

    return GestureDetector(
      onLongPress: widget.isDraft ? widget.onDiscardDraft : _confirmDeleteGroup,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.20), scheme.surface],
              stops: const [0.0, 0.72],
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: _expanded,
            onExpansionChanged: (v) => setState(() => _expanded = v),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Tooltip(
              message: 'Color & icon',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAppearanceSheet,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            title: _editingName
                ? TextField(
                    controller: _name,
                    focusNode: _nameFocus,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Group name',
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  )
                : InkWell(
                    onTap: () {
                      setState(() {
                        _editingName = true;
                        _expanded = true;
                      });
                      _nameFocus.requestFocus();
                    },
                    child: Text(
                      widget.group.name.trim().isEmpty
                          ? 'Untitled group'
                          : widget.group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
            subtitle: _editingDescription
                ? TextField(
                    controller: _description,
                    focusNode: _descriptionFocus,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Description (optional)',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  )
                : ((widget.group.description == null ||
                          widget.group.description!.trim().isEmpty)
                      ? InkWell(
                          onTap: () {
                            setState(() {
                              _editingDescription = true;
                              _expanded = true;
                            });
                            _descriptionFocus.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Tap to add a description',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.2,
                                  ),
                            ),
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            setState(() {
                              _editingDescription = true;
                              _expanded = true;
                            });
                            _descriptionFocus.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              widget.group.description!.trim(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.2,
                                  ),
                            ),
                          ),
                        )),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatZarFromCents((widget.totalAmount * 100).round()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 2),
                IgnorePointer(
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            children: [
              if (items.isNotEmpty)
                ...items.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: BudgetItemCard(
                      key: ValueKey(i.id),
                      item: i,
                      isDraft: _draftItems.any((d) => d.id == i.id),
                      onDiscardDraft: _draftItems.any((d) => d.id == i.id)
                          ? () => _discardDraftItem(i.id)
                          : null,
                      onDraftChanged: _draftItems.any((d) => d.id == i.id)
                          ? _upsertDraftItem
                          : null,
                      onUpsert: (updated) =>
                          widget.onUpsertItem(widget.group.id, updated),
                      onDelete: () =>
                          widget.onDeleteItem(widget.group.id, i.id),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _AddItemCard(onTap: _addDraftItem),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemCard extends StatelessWidget {
  const _AddItemCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: scheme.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                'Add item',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForGroup(BudgetGroup group) {
  final cp = group.iconCodePoint;
  if (cp == null) return Icons.category_rounded;
  return IconData(cp, fontFamily: group.iconFontFamily ?? 'MaterialIcons');
}

Color? _parseHexColor(String hex) {
  var t = hex.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('#')) t = t.substring(1);
  if (t.length == 6) t = 'FF$t';
  if (t.length != 8) return null;
  final v = int.tryParse(t, radix: 16);
  if (v == null) return null;
  return Color(v);
}

import 'package:flutter/material.dart';

import 'package:sprout/core/utils/money_format.dart';

import '../../domain/budget_item.dart';

class BudgetItemCard extends StatefulWidget {
  const BudgetItemCard({
    super.key,
    required this.item,
    required this.onUpsert,
    required this.onDelete,
    this.isDraft = false,
    this.onDiscardDraft,
    this.onDraftChanged,
  });

  final BudgetItem item;
  final ValueChanged<BudgetItem> onUpsert;
  final VoidCallback onDelete;

  final bool isDraft;
  final VoidCallback? onDiscardDraft;
  final ValueChanged<BudgetItem>? onDraftChanged;

  @override
  State<BudgetItemCard> createState() => _BudgetItemCardState();
}

class _BudgetItemCardState extends State<BudgetItemCard> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final FocusNode _nameFocus;
  late final FocusNode _amountFocus;

  bool _editingName = false;
  bool _editingAmount = false;
  bool _handingOffToAmount = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _amount = TextEditingController(
      text: _amountTextForField(widget.item.amount),
    );
    _nameFocus = FocusNode()..addListener(_onNameFocus);
    _amountFocus = FocusNode()..addListener(_onAmountFocus);

    if (widget.isDraft && widget.item.name.trim().isEmpty) {
      _editingName = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant BudgetItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.name != widget.item.name) {
      if (!_editingName) {
        _name.text = widget.item.name;
      } else if (oldWidget.item.name.trim().isEmpty &&
          widget.item.name == BudgetItem.defaultDraftName) {
        _name.text = widget.item.name;
        setState(() => _editingName = false);
      }
    }
    if (oldWidget.item.amount != widget.item.amount) {
      if (!_editingAmount) {
        _amount.text = _amountTextForField(widget.item.amount);
      }
    }
  }

  void _onNameFocus() {
    if (!_nameFocus.hasFocus && _editingName) {
      if (_handingOffToAmount) return;
      setState(() => _editingName = false);
      _commit();
    }
  }

  void _onAmountFocus() {
    if (!_amountFocus.hasFocus && _editingAmount) {
      setState(() => _editingAmount = false);
      _commit();
    }
  }

  String _formatAmount(double v) {
    final cents = (v * 100).round();
    final raw = formatZarFromCents(cents);
    // We want a clean editable number; keep it simple for now.
    return raw.replaceAll('R', '').trim();
  }

  /// Empty when amount is zero so the field can show a hint instead of "0,00".
  String _amountTextForField(double v) {
    if (v == 0.0) return '';
    return _formatAmount(v);
  }

  String get _amountHint => formatZarFromCents(0).replaceAll('R', '').trim();

  void _requestAmountFocus([int attemptsRemaining = 3]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_amountFocus);
      if (_amountFocus.hasFocus || attemptsRemaining <= 1) {
        _handingOffToAmount = false;
        return;
      }
      _requestAmountFocus(attemptsRemaining - 1);
    });
  }

  void _focusAmountField() {
    _handingOffToAmount = true;
    setState(() {
      _editingName = false;
      _editingAmount = true;
      _amount.text = _amount.text.isEmpty
          ? _amountTextForField(widget.item.amount)
          : _amount.text;
    });
    _requestAmountFocus();
  }

  void _completeNameEditing() {
    if (_name.text.trim().isNotEmpty) {
      _commit();
    }
    _focusAmountField();
  }

  void _commit() {
    final name = _name.text.trim();
    final rawAmount = _amount.text.trim();
    double amount;
    if (rawAmount.isEmpty) {
      amount = 0.0;
    } else {
      final cleaned = rawAmount.replaceAll(',', '');
      final p = double.tryParse(cleaned);
      if (p == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
        return;
      }
      amount = p;
    }

    if (widget.isDraft) {
      if (name.isEmpty && amount == 0.0) {
        widget.onDiscardDraft?.call();
        return;
      }
    }

    if (name.isEmpty) return;
    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount cannot be negative.')),
      );
      return;
    }

    final updated = widget.item.copyWith(name: name, amount: amount);
    if (widget.isDraft) widget.onDraftChanged?.call(updated);
    widget.onUpsert(updated);
    if (widget.isDraft) widget.onDiscardDraft?.call();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text(
          'This will remove “${widget.item.name.trim().isEmpty ? BudgetItem.defaultDraftName : widget.item.name}”.',
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
    if (ok == true && mounted) widget.onDelete();
  }

  @override
  void dispose() {
    _nameFocus
      ..removeListener(_onNameFocus)
      ..dispose();
    _amountFocus
      ..removeListener(_onAmountFocus)
      ..dispose();
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surfaceContainerHighest.withValues(alpha: 0.45);

    return Card(
      elevation: 0,
      color: surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: widget.isDraft ? widget.onDiscardDraft : _confirmDelete,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _editingName
                    ? TextField(
                        controller: _name,
                        focusNode: _nameFocus,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Item name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        onEditingComplete: _completeNameEditing,
                      )
                    : InkWell(
                        onTap: () {
                          setState(() => _editingName = true);
                          _nameFocus.requestFocus();
                        },
                        child: Text(
                          widget.item.name.trim().isEmpty
                              ? BudgetItem.defaultDraftName
                              : widget.item.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.item.name.trim().isEmpty
                                    ? scheme.onSurfaceVariant.withValues(
                                        alpha: 0.55,
                                      )
                                    : null,
                              ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              _editingAmount
                  ? SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _amount,
                        focusNode: _amountFocus,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: _amountHint,
                          hintStyle: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        autofocus: true,
                      ),
                    )
                  : InkWell(
                      onTap: () {
                        setState(() {
                          _editingAmount = true;
                          _amount.text = _amountTextForField(
                            widget.item.amount,
                          );
                        });
                        _amountFocus.requestFocus();
                      },
                      child: Text(
                        widget.item.amount == 0.0
                            ? _amountHint
                            : formatZarFromCents(
                                (widget.item.amount * 100).round(),
                              ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: widget.item.amount == 0.0 ? 0.45 : 1.0,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import '../application/accounts_service.dart';
import '../domain/account.dart';

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({
    super.key,
    this.initial,
    required this.defaultColor,
  });

  final Account? initial;
  final Color defaultColor;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  late final TextEditingController _name;
  late int _colorArgb;
  static const _uuid = Uuid();

  List<Account> _accounts = [];
  bool _accountsLoaded = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _name.addListener(_onFieldChanged);
    _colorArgb =
        widget.initial?.color ?? widget.defaultColor.toARGB32();
    _loadAccounts();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAccounts() async {
    final list = await sl<AccountsService>().getAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = list;
      _accountsLoaded = true;
    });
  }

  String? get _nameError {
    final name = _name.text.trim();
    if (name.isEmpty) return null;
    final key = name.toLowerCase();
    final taken = _accounts.any(
      (a) =>
          a.id != widget.initial?.id &&
          a.name.trim().toLowerCase() == key,
    );
    if (taken) return AppStrings.duplicateAccountName;
    return null;
  }

  bool get _canSave {
    if (!_accountsLoaded) return false;
    final name = _name.text.trim();
    if (name.isEmpty) return false;
    return _nameError == null;
  }

  @override
  void dispose() {
    _name.removeListener(_onFieldChanged);
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final name = _name.text.trim();
    final uid = await sl<UserContext>().resolveUserId();
    final now = DateTime.now();
    final acc = Account(
      id: widget.initial?.id ?? _uuid.v4(),
      userId: uid,
      name: name,
      color: _colorArgb,
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await sl<AccountsService>().saveAccount(acc);
    } on ValidationAppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop(acc);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? AppStrings.newAccount : AppStrings.edit,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: AppStrings.accountName,
              errorText: _nameError,
            ),
            textCapitalization: TextCapitalization.words,
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
              for (var i = 0; i < AppColors.cardPalette.length; i++)
                GestureDetector(
                  onTap: () => setState(
                    () => _colorArgb = AppColors.cardPalette[i].toARGB32(),
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.cardPalette[i],
                    child: _colorArgb == AppColors.cardPalette[i].toARGB32()
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}

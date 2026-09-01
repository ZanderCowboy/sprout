import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/ui/export.dart';

import '../application/accounts_service.dart';
import '../domain/account.dart';
import 'account_form_cubit.dart';

class AccountFormSheet extends StatelessWidget {
  const AccountFormSheet({
    super.key,
    this.initial,
    required this.defaultColor,
  });

  final Account? initial;
  final Color defaultColor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountFormCubit(
        accountsService: sl<AccountsService>(),
        userContext: sl<UserContext>(),
        initial: initial,
        defaultColorArgb: defaultColor.toARGB32(),
      )..load(),
      child: _AccountFormBody(initial: initial),
    );
  }
}

class _AccountFormBody extends StatefulWidget {
  const _AccountFormBody({required this.initial});

  final Account? initial;

  @override
  State<_AccountFormBody> createState() => _AccountFormBodyState();
}

class _AccountFormBodyState extends State<_AccountFormBody> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _name.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    context.read<AccountFormCubit>().nameChanged(_name.text);
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountFormCubit, AccountFormState>(
      listenWhen: (previous, current) =>
          current is AccountFormSaved ||
          (current is AccountFormReady && current.submitError != null),
      listener: (context, state) {
        if (state is AccountFormSaved) {
          Navigator.of(context).pop(state.account);
          return;
        }
        if (state is AccountFormReady && state.submitError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.submitError!)));
        }
      },
      builder: (context, state) {
        final ready = state is AccountFormReady ? state : null;
        return NameColorFormSheet(
          title: widget.initial == null ? AppStrings.newAccount : AppStrings.edit,
          nameLabel: AppStrings.accountName,
          nameController: _name,
          nameErrorText: ready?.nameError,
          colorArgb: ready?.colorArgb ?? 0,
          onColorSelected: (argb) =>
              context.read<AccountFormCubit>().colorChanged(argb),
          primaryActionLabel: AppStrings.save,
          onPrimaryAction: () => context.read<AccountFormCubit>().submit(),
          primaryActionEnabled: ready?.canSave ?? false,
          nameFieldKey: const Key('account_name_field'),
          nameFieldIdentifier: SemanticsIds.accountNameField,
        );
      },
    );
  }
}

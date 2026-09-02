import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';

import '../application/accounts_service.dart';
import '../domain/account.dart';

part 'account_form_state.dart';

class AccountFormCubit extends Cubit<AccountFormState> {
  AccountFormCubit({
    required AccountsService accountsService,
    required UserContext userContext,
    Account? initial,
    required int defaultColorArgb,
  }) : _accountsService = accountsService,
       _userContext = userContext,
       _initial = initial,
       super(
         AccountFormReady(
           name: initial?.name ?? '',
           colorArgb: initial?.color ?? defaultColorArgb,
         ),
       );

  final AccountsService _accountsService;
  final UserContext _userContext;
  final Account? _initial;
  static const _uuid = Uuid();

  List<({String id, String name})> _existing = const [];

  Future<void> load() async {
    final list = await _accountsService.getAccounts();
    _existing = list.map((a) => (id: a.id, name: a.name)).toList();
    final current = state;
    if (current is AccountFormReady) {
      emit(
        current.copyWith(
          loaded: true,
          updateNameError: true,
          nameError: _nameError(current.name),
        ),
      );
    }
  }

  void nameChanged(String name) {
    final current = state;
    if (current is! AccountFormReady) return;
    emit(
      current.copyWith(
        name: name,
        updateNameError: true,
        nameError: _nameError(name),
      ),
    );
  }

  void colorChanged(int colorArgb) {
    final current = state;
    if (current is! AccountFormReady) return;
    emit(current.copyWith(colorArgb: colorArgb));
  }

  String? _nameError(String name) {
    if (name.trim().isEmpty) return null;
    final taken = UniqueName.isTaken(
      existing: _existing,
      candidateName: name,
      excludeId: _initial?.id,
    );
    return taken ? AppStrings.duplicateAccountName : null;
  }

  Future<void> submit() async {
    final current = state;
    if (current is! AccountFormReady || !current.canSave) return;

    emit(current.copyWith(submitting: true, clearSubmitError: true));

    try {
      final now = DateTime.now();
      final uid = await _userContext.resolveUserId();
      final account = Account(
        id: _initial?.id ?? _uuid.v4(),
        userId: uid,
        name: current.name.trim(),
        color: current.colorArgb,
        createdAt: _initial?.createdAt ?? now,
        updatedAt: now,
      );

      await _accountsService.saveAccount(account);
      emit(AccountFormSaved(account: account));
    } on AppException catch (e) {
      emit(current.copyWith(submitting: false, submitError: e.message));
    } catch (_) {
      emit(
        current.copyWith(
          submitting: false,
          submitError: AppStrings.couldNotSave,
        ),
      );
    }
  }
}

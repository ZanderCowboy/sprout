import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/application/accounts_service_impl.dart';
import 'package:sprout/features/accounts/domain/account.dart';
import 'package:sprout/features/accounts/presentation/account_form_cubit.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late FakeAccountsRepository repo;
  late AccountFormCubit cubit;

  Account account({required String id, required String name}) {
    return Account(
      id: id,
      userId: 'u',
      name: name,
      color: 0xFF000000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_account_form_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    repo = FakeAccountsRepository(
      initial: [account(id: '1', name: 'Cheque')],
    );
    cubit = AccountFormCubit(
      accountsService: AccountsServiceImpl(repo),
      userContext: UserContext(settingsBox),
      defaultColorArgb: 0xFF112233,
    );
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
    await settingsBox.close();
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  test('nameError uses UniqueName after load', () async {
    await cubit.load();
    cubit.nameChanged('cheque');
    final state = cubit.state;
    expect(state, isA<AccountFormReady>());
    expect((state as AccountFormReady).nameError, AppStrings.duplicateAccountName);
    expect(state.canSave, isFalse);
  });

  test('submit saves a unique name', () async {
    await cubit.load();
    cubit.nameChanged('Savings');
    await cubit.submit();
    expect(cubit.state, isA<AccountFormSaved>());
    expect(repo.lastUpserted?.name, 'Savings');
  });
}

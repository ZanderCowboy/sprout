import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/application/accounts_service_impl.dart';
import 'package:sprout/features/goals/application/goals_service_impl.dart';
import 'package:sprout/features/transactions/application/transactions_service_impl.dart';
import 'package:sprout/features/wizard/presentation/wizard_cubit.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late FakeGoalsRepository goalsRepo;
  late FakeAccountsRepository accountsRepo;
  late FakeTransactionsRepository txRepo;
  late UserContext userContext;
  late WizardCubit cubit;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_wizard_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    goalsRepo = FakeGoalsRepository();
    accountsRepo = FakeAccountsRepository();
    txRepo = FakeTransactionsRepository();
    userContext = UserContext(settingsBox);
    cubit = WizardCubit(
      accountsService: AccountsServiceImpl(accountsRepo),
      goalsService: GoalsServiceImpl(
        goalsRepo,
        TransactionsServiceImpl(txRepo),
      ),
      transactionsService: TransactionsServiceImpl(txRepo),
      userContext: userContext,
      defaultGoalColorArgb: 0xFF112233,
      defaultAccountColorArgb: 0xFF445566,
      defaultGoalIconCodePoint: 0xE52F,
    );
  });

  tearDown(() async {
    await cubit.close();
    await goalsRepo.dispose();
    await accountsRepo.dispose();
    await txRepo.dispose();
    await settingsBox.close();
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  WizardReady ready() => cubit.state as WizardReady;

  test('clearing an invalid target amount clears the error', () async {
    await cubit.load();
    cubit.setGoalTarget('abc');
    expect(ready().goalTargetError, AppStrings.invalidAmount);

    cubit.setGoalTarget('');
    expect(ready().goalTargetError, isNull);
  });

  test('rejects a junk account name', () async {
    await cubit.load();
    cubit.setAccountName(r'er34$34rre');
    expect(ready().accountNameError, AppStrings.invalidEntityName);
    expect(cubit.canGoToStep3, isFalse);
  });

  test('accepts a readable account name', () async {
    await cubit.load();
    cubit.setAccountName('EasyEquities TFSA');
    expect(ready().accountNameError, isNull);
    expect(cubit.canGoToStep3, isTrue);
  });

  test('deposit amount validates min and max against the goal target', () async {
    await cubit.load();
    cubit.setGoalName('Cape Town trip');
    cubit.setGoalTarget('100');
    cubit.setDepositAmount('5');
    expect(ready().depositAmountError, AppStrings.wizardDepositBelowMinimum);

    cubit.setDepositAmount('250');
    expect(ready().depositAmountError, AppStrings.wizardDepositAboveMaximum);

    cubit.setDepositAmount('50');
    expect(ready().depositAmountError, isNull);
    expect(cubit.canFinish, isTrue);

    cubit.setDepositAmount('');
    expect(ready().depositAmountError, isNull);
    expect(cubit.canFinish, isFalse);
  });

  test('skip does not queue a welcome toast', () async {
    await cubit.load();
    await cubit.skip();
    expect(cubit.state, isA<WizardSkipped>());
    final uid = await userContext.resolveUserId();
    expect(await userContext.takePendingWelcomeToast(uid), isNull);
  });

  test('allocate later saves goal and account without a deposit', () async {
    await cubit.load();
    cubit.setGoalName('Cape Town trip');
    cubit.setGoalTarget('12000');
    cubit.setAccountName('EasyEquities TFSA');
    cubit.setAllocateLater(true);
    expect(cubit.canFinish, isTrue);

    await cubit.finish();

    expect(cubit.state, isA<WizardCompleted>());
    expect((cubit.state as WizardCompleted).plantedSeed, isFalse);
    expect(goalsRepo.lastUpserted?.name, 'Cape Town trip');
    expect(accountsRepo.lastUpserted?.name, 'EasyEquities TFSA');
    expect(txRepo.addTransactionCalls, 0);

    final uid = await userContext.resolveUserId();
    expect(await userContext.getFirstRunCompleted(uid), isTrue);
    expect(
      await userContext.takePendingWelcomeToast(uid),
      AppStrings.wizardSetupReady,
    );
  });

  test('finish records a deposit and queues the seed toast', () async {
    await cubit.load();
    cubit.setGoalName('Cape Town trip');
    cubit.setGoalTarget('12000');
    cubit.setAccountName('EasyEquities TFSA');
    cubit.setDepositAmount('2500');

    await cubit.finish();

    expect(cubit.state, isA<WizardCompleted>());
    expect((cubit.state as WizardCompleted).plantedSeed, isTrue);
    expect(txRepo.addTransactionCalls, 1);
    expect(txRepo.lastAdded?.amountCents, 250000);

    final uid = await userContext.resolveUserId();
    expect(
      await userContext.takePendingWelcomeToast(uid),
      AppStrings.wizardFirstSeedPlanted,
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/goals/application/goals_service_impl.dart';
import 'package:sprout/features/goals/domain/goal.dart';
import 'package:sprout/features/goals/presentation/goal_form_cubit.dart';
import 'package:sprout/features/transactions/application/transactions_service_impl.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late FakeGoalsRepository goalsRepo;
  late FakeTransactionsRepository txRepo;
  late GoalFormCubit cubit;

  Goal goal({required String id, required String name}) {
    return Goal(
      id: id,
      userId: 'u',
      name: name,
      targetAmountCents: 10000,
      color: 0xFF000000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('sprout_goal_form_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    goalsRepo = FakeGoalsRepository(initial: [goal(id: '1', name: 'House')]);
    txRepo = FakeTransactionsRepository();
    cubit = GoalFormCubit(
      goalsService: GoalsServiceImpl(
        goalsRepo,
        TransactionsServiceImpl(txRepo),
      ),
      userContext: UserContext(settingsBox),
      defaultColorArgb: 0xFF112233,
    );
  });

  tearDown(() async {
    await cubit.close();
    await goalsRepo.dispose();
    await txRepo.dispose();
    await settingsBox.close();
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  test('nameError uses UniqueName after load', () async {
    await cubit.load();
    cubit.nameChanged('house');
    final state = cubit.state;
    expect(state, isA<GoalFormReady>());
    expect((state as GoalFormReady).nameError, AppStrings.duplicateGoalName);
    expect(state.canSave, isFalse);
  });

  test('submit saves a unique name and positive target', () async {
    await cubit.load();
    cubit.nameChanged('Car');
    cubit.targetChanged('250.00');
    await cubit.submit();
    expect(cubit.state, isA<GoalFormSaved>());
    expect(goalsRepo.lastUpserted?.name, 'Car');
    expect(goalsRepo.lastUpserted?.targetAmountCents, 25000);
    expect(goalsRepo.lastUpserted?.iconCodePoint, isNotNull);
  });

  test('iconChanged is persisted on submit', () async {
    await cubit.load();
    cubit.nameChanged('Car');
    cubit.targetChanged('250.00');
    cubit.iconChanged(0xE52F);
    await cubit.submit();
    expect(cubit.state, isA<GoalFormSaved>());
    expect(goalsRepo.lastUpserted?.iconCodePoint, 0xE52F);
  });

  test('submit recovers from a non-validation failure', () async {
    goalsRepo.upsertError = StateError('hive down');
    await cubit.load();
    cubit.nameChanged('Car');
    cubit.targetChanged('250.00');
    await cubit.submit();
    final state = cubit.state;
    expect(state, isA<GoalFormReady>());
    expect((state as GoalFormReady).submitting, isFalse);
    expect(state.submitError, AppStrings.couldNotSave);
    expect(state.canSave, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/budget/application/budget_service_impl.dart';
import 'package:sprout/features/budget/domain/budget_category.dart';
import 'package:sprout/features/budget/domain/budget_group.dart';

import '../mocks/mocks.dart';

void main() {
  late FakeBudgetRepository repo;
  late BudgetServiceImpl service;

  BudgetGroup group({required String id, required String name}) {
    return BudgetGroup(
      id: id,
      userId: 'u',
      name: name,
      description: null,
      colorHex: '#FF000000',
      iconCodePoint: null,
      iconFontFamily: null,
      category: BudgetCategory.essentials,
      items: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    repo = FakeBudgetRepository();
    service = BudgetServiceImpl(repo);
  });

  tearDown(() async {
    await repo.dispose();
  });

  test('saveBudgetGroup rejects a duplicate name', () async {
    await repo.upsertBudgetGroup(group(id: '1', name: 'Rent'));

    expect(
      () => service.saveBudgetGroup(group(id: '2', name: 'rent')),
      throwsA(
        isA<ValidationAppException>().having(
          (e) => e.message,
          'message',
          AppStrings.duplicateGroupName,
        ),
      ),
    );
  });

  test('saveBudgetGroup rejects an empty name', () async {
    expect(
      () => service.saveBudgetGroup(group(id: '1', name: '  ')),
      throwsA(
        isA<ValidationAppException>().having(
          (e) => e.message,
          'message',
          AppStrings.nameRequired,
        ),
      ),
    );
  });
}

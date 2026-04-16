import 'package:hive_flutter/hive_flutter.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

/// Rewrites [userId] on all local rows to match the Supabase auth user so RLS
/// (`auth.uid() = user_id`) and [UserContext.resolveUserId] stay aligned.
Future<void> migrateHiveUserIdsToAuthUser({
  required String authUserId,
  required Box<AccountHiveModel> accounts,
  required Box<GoalHiveModel> goals,
  required Box<BudgetGroupHiveModel> budgetGroups,
  required Box<TransactionHiveModel> transactions,
}) async {
  for (final key in accounts.keys.toList()) {
    final m = accounts.get(key);
    if (m == null || m.userId == authUserId) continue;
    await accounts.put(
      key,
      AccountHiveModel(
        id: m.id,
        userId: authUserId,
        name: m.name,
        color: m.color,
        createdAtMillis: m.createdAtMillis,
        updatedAtMillis: m.updatedAtMillis,
      ),
    );
  }
  for (final key in goals.keys.toList()) {
    final m = goals.get(key);
    if (m == null || m.userId == authUserId) continue;
    await goals.put(
      key,
      GoalHiveModel(
        id: m.id,
        userId: authUserId,
        name: m.name,
        targetAmountCents: m.targetAmountCents,
        color: m.color,
        createdAtMillis: m.createdAtMillis,
        updatedAtMillis: m.updatedAtMillis,
      ),
    );
  }
  for (final key in budgetGroups.keys.toList()) {
    final m = budgetGroups.get(key);
    if (m == null || m.userId == authUserId) continue;
    await budgetGroups.put(
      key,
      BudgetGroupHiveModel(
        id: m.id,
        userId: authUserId,
        name: m.name,
        description: m.description,
        colorHex: m.colorHex,
        iconCodePoint: m.iconCodePoint,
        iconFontFamily: m.iconFontFamily,
        categoryIndex: m.categoryIndex,
        itemsJson: m.itemsJson,
        createdAtMillis: m.createdAtMillis,
        updatedAtMillis: m.updatedAtMillis,
      ),
    );
  }
  for (final key in transactions.keys.toList()) {
    final m = transactions.get(key);
    if (m == null || m.userId == authUserId) continue;
    await transactions.put(
      key,
      TransactionHiveModel(
        id: m.id,
        userId: authUserId,
        accountId: m.accountId,
        goalId: m.goalId,
        kindIndex: m.kindIndex,
        amountCents: m.amountCents,
        occurredAtMillis: m.occurredAtMillis,
        note: m.note,
        pendingSync: m.pendingSync,
        isRecurring: m.isRecurring,
        recurringEnabled: m.recurringEnabled,
        frequencyIndex: m.frequencyIndex,
        nextScheduledAtMillis: m.nextScheduledAtMillis,
      ),
    );
  }
}

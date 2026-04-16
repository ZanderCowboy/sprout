import '../domain/transaction.dart';
import '../domain/transaction_frequency.dart';
import 'local/transaction_hive_model.dart';

Transaction transactionFromHive(TransactionHiveModel m) => Transaction(
      id: m.id,
      userId: m.userId,
      accountId: m.accountId,
      kind: TransactionKind.values[(m.kindIndex >= 0 &&
              m.kindIndex < TransactionKind.values.length)
          ? m.kindIndex
          : 0],
      goalId: m.goalId.isEmpty ? null : m.goalId,
      groupId: m.groupId,
      amountCents: m.amountCents,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(m.occurredAtMillis),
      note: m.note,
      pendingSync: m.pendingSync,
      isRecurring: m.isRecurring,
      recurringEnabled: m.recurringEnabled,
      frequency: TransactionFrequency.values[m.frequencyIndex],
      nextScheduledDate: m.nextScheduledAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m.nextScheduledAtMillis!),
    );

TransactionHiveModel transactionToHive(Transaction t) => TransactionHiveModel(
      id: t.id,
      userId: t.userId,
      accountId: t.accountId,
      goalId: t.goalId ?? '',
      groupId: t.groupId,
      kindIndex: t.kind.index,
      amountCents: t.amountCents,
      occurredAtMillis: t.occurredAt.millisecondsSinceEpoch,
      note: t.note,
      pendingSync: t.pendingSync,
      isRecurring: t.isRecurring,
      recurringEnabled: t.recurringEnabled,
      frequencyIndex: t.frequency.index,
      nextScheduledAtMillis: t.nextScheduledDate?.millisecondsSinceEpoch,
    );

Transaction transactionFromSupabaseRow(Map<String, dynamic> row) {
  final isRecurring = (row['is_recurring'] as bool?) ?? false;
  return Transaction(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    accountId: row['account_id'] as String,
    kind: TransactionKindCodec.fromWireName(row['kind'] as String?),
    goalId: row['goal_id'] as String?,
    groupId: row['group_id'] as String?,
    amountCents: (row['amount_cents'] as num).toInt(),
    occurredAt: DateTime.parse(row['occurred_at'] as String),
    note: row['note'] as String?,
    isRecurring: isRecurring,
    // Guard: older Supabase schema doesn't include 'recurring_enabled'.
    // When absent, default to "enabled if recurring".
    recurringEnabled: (row['recurring_enabled'] as bool?) ?? isRecurring,
    frequency: TransactionFrequencyCodec.fromWireName(row['frequency'] as String?),
    nextScheduledDate: row['next_scheduled_date'] == null
        ? null
        : DateTime.parse(row['next_scheduled_date'] as String),
    pendingSync: false,
  );
}

Map<String, dynamic> transactionToSupabaseRow(Transaction t) => {
      'id': t.id,
      'user_id': t.userId,
      'account_id': t.accountId,
      'kind': t.kind.wireName,
      'goal_id': t.goalId,
      'group_id': t.groupId,
      'amount_cents': t.amountCents,
      'occurred_at': t.occurredAt.toUtc().toIso8601String(),
      'is_recurring': t.isRecurring,
      'frequency': t.frequency.wireName,
      'next_scheduled_date': t.nextScheduledDate?.toUtc().toIso8601String(),
      if (t.note != null) 'note': t.note,
    };

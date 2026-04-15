import 'dart:convert';

import 'package:sprout/features/accounts/accounts.dart';
import 'package:sprout/features/goals/goals.dart';

import '../domain/transaction.dart';
import '../domain/transaction_frequency.dart';
import 'transaction_mapper.dart';

String encodeTransactionPayload(Transaction t) =>
    jsonEncode(transactionToSupabaseRow(t));

Transaction decodeTransactionPayload(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  return Transaction(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    accountId: map['account_id'] as String,
    kind: TransactionKindCodec.fromWireName(map['kind'] as String?),
    goalId: map['goal_id'] as String?,
    groupId: map['group_id'] as String?,
    amountCents: (map['amount_cents'] as num).toInt(),
    occurredAt: DateTime.parse(map['occurred_at'] as String),
    note: map['note'] as String?,
    isRecurring: (map['is_recurring'] as bool?) ?? false,
    frequency: TransactionFrequencyCodec.fromWireName(map['frequency'] as String?),
    nextScheduledDate: map['next_scheduled_date'] == null
        ? null
        : DateTime.parse(map['next_scheduled_date'] as String),
    pendingSync: true,
  );
}

String encodeAccountPayload(Account a) => jsonEncode(accountToSupabaseRow(a));

Account decodeAccountPayload(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  return accountFromSupabaseRow(map);
}

String encodeGoalPayload(Goal g) => jsonEncode(goalToSupabaseRow(g));

Goal decodeGoalPayload(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  return goalFromSupabaseRow(map);
}

String encodeIdPayload(String id) => jsonEncode({'id': id});

String decodeIdPayload(String json) =>
    (jsonDecode(json) as Map<String, dynamic>)['id'] as String;

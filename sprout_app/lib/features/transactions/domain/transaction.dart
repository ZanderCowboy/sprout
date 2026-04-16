import 'package:equatable/equatable.dart';

import 'transaction_frequency.dart';

enum TransactionKind {
  /// Money entering an account. Can be immediately assigned to a goal (goalId set)
  /// or left unallocated (goalId null).
  deposit,

  /// Money being allocated from an account's unallocated balance into a goal.
  allocation,
}

extension TransactionKindCodec on TransactionKind {
  String get wireName => switch (this) {
        TransactionKind.deposit => 'deposit',
        TransactionKind.allocation => 'allocation',
      };

  static TransactionKind fromWireName(String? wire) {
    if (wire == null || wire.isEmpty) return TransactionKind.deposit;
    return switch (wire) {
      'allocation' => TransactionKind.allocation,
      'deposit' => TransactionKind.deposit,
      _ => TransactionKind.deposit,
    };
  }
}

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.kind,
    this.goalId,
    this.groupId,
    required this.amountCents,
    required this.occurredAt,
    this.note,
    required this.pendingSync,
    this.isRecurring = false,
    this.recurringEnabled = false,
    this.frequency = TransactionFrequency.none,
    this.nextScheduledDate,
  });

  final String id;
  final String userId;
  final String accountId;
  final TransactionKind kind;
  final String? goalId;
  final String? groupId;
  final int amountCents;
  final DateTime occurredAt;
  final String? note;
  final bool pendingSync;
  final bool isRecurring;
  final bool recurringEnabled;
  final TransactionFrequency frequency;
  final DateTime? nextScheduledDate;

  @override
  List<Object?> get props => [
        id,
        userId,
        accountId,
        kind,
        goalId,
        groupId,
        amountCents,
        occurredAt,
        note,
        pendingSync,
        isRecurring,
        recurringEnabled,
        frequency,
        nextScheduledDate,
      ];
}

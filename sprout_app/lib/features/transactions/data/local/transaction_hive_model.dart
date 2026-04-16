class TransactionHiveModel {
  TransactionHiveModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.goalId,
    this.groupId,
    this.kindIndex = 0,
    required this.amountCents,
    required this.occurredAtMillis,
    this.note,
    required this.pendingSync,
    this.isRecurring = false,
    this.recurringEnabled = false,
    this.frequencyIndex = 0,
    this.nextScheduledAtMillis,
  });

  final String id;
  final String userId;
  final String accountId;

  /// Empty string represents null (unallocated deposit).
  final String goalId;

  /// Optional group/batch id to link an account deposit with its allocations.
  final String? groupId;

  /// [TransactionKind] index. Appended for backwards compatibility.
  final int kindIndex;
  final int amountCents;
  final int occurredAtMillis;
  final String? note;
  final bool pendingSync;
  final bool isRecurring;
  final bool recurringEnabled;
  final int frequencyIndex;
  final int? nextScheduledAtMillis;
}

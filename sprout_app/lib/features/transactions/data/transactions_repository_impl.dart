import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/features/sync/sync.dart';
import '../domain/portfolio_summary.dart';
import '../domain/transaction.dart';
import '../domain/transaction_frequency.dart';
import '../domain/transactions_repository.dart';
import 'local/transaction_hive_model.dart';
import 'pending_sync_payload.dart';
import 'supabase_tables.dart';
import 'transaction_mapper.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl({
    required Box<TransactionHiveModel> box,
    required UserContext userContext,
    required AppConfig appConfig,
    SupabaseClient? supabase,
    PendingSyncQueue? pendingSyncQueue,
  })  : _box = box,
        _userContext = userContext,
        _appConfig = appConfig,
        _supabase = supabase,
        _pendingSyncQueue = pendingSyncQueue;

  final Box<TransactionHiveModel> _box;
  final UserContext _userContext;
  final AppConfig _appConfig;
  final SupabaseClient? _supabase;
  final PendingSyncQueue? _pendingSyncQueue;
  final _updates = StreamController<void>.broadcast();
  static const _uuid = Uuid();

  void _notify() {
    if (!_updates.isClosed) _updates.add(null);
  }

  PortfolioSummary _summary() {
    if (_box.isEmpty) {
      return const PortfolioSummary(totalCents: 0, lastActivityAt: null);
    }
    var total = 0;
    DateTime? last;
    for (final t in _box.values) {
      final kind = TransactionKind.values[(t.kindIndex >= 0 &&
              t.kindIndex < TransactionKind.values.length)
          ? t.kindIndex
          : 0];
      if (kind == TransactionKind.deposit) {
        total += t.amountCents;
      }
      final dt = DateTime.fromMillisecondsSinceEpoch(t.occurredAtMillis);
      if (last == null || dt.isAfter(last)) last = dt;
    }
    return PortfolioSummary(totalCents: total, lastActivityAt: last);
  }

  @override
  Stream<List<Transaction>> watchTransactions() async* {
    yield await _list();
    await for (final _ in _updates.stream) {
      yield await _list();
    }
  }

  @override
  Stream<PortfolioSummary> watchPortfolioSummary() async* {
    yield _summary();
    await for (final _ in _updates.stream) {
      yield _summary();
    }
  }

  Future<List<Transaction>> _list() async {
    final uid = await _userContext.resolveUserId();
    return _box.values
        .map(transactionFromHive)
        .where((t) => t.userId == uid)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  @override
  Future<List<Transaction>> getForAccount(String accountId) async {
    final all = await _list();
    return all.where((t) => t.accountId == accountId).toList();
  }

  @override
  Future<List<Transaction>> getForGoal(String goalId) async {
    final all = await _list();
    return all.where((t) => t.goalId == goalId).toList();
  }

  @override
  Future<void> addTransaction({
    required String accountId,
    required TransactionKind kind,
    String? goalId,
    String? groupId,
    required int amountCents,
    DateTime? occurredAt,
    String? note,
    bool isRecurring = false,
    TransactionFrequency frequency = TransactionFrequency.none,
  }) async {
    final uid = await _userContext.resolveUserId();
    final id = _uuid.v4();
    final now = occurredAt ?? DateTime.now();
    final pending = _appConfig.isSupabaseConfigured;
    final normalizedIsRecurring =
        isRecurring && frequency != TransactionFrequency.none;
    final next = normalizedIsRecurring
        ? _computeNextScheduledDate(now, frequency)
        : null;
    if (kind == TransactionKind.allocation && (goalId == null || goalId.isEmpty)) {
      throw ArgumentError.value(goalId, 'goalId', 'Required for allocations');
    }
    final tx = Transaction(
      id: id,
      userId: uid,
      accountId: accountId,
      kind: kind,
      goalId: goalId,
      groupId: groupId,
      amountCents: amountCents,
      occurredAt: now,
      note: note,
      pendingSync: pending,
      isRecurring: normalizedIsRecurring,
      frequency: normalizedIsRecurring ? frequency : TransactionFrequency.none,
      nextScheduledDate: next,
    );
    await _box.put(id, transactionToHive(tx));
    _notify();
    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      await q.enqueue(
        PendingSyncOperationType.insertTransaction,
        encodeTransactionPayload(tx),
      );
    }
  }

  @override
  Future<void> updateTransactionNote({
    required String transactionId,
    required String? note,
  }) async {
    final existing = _box.get(transactionId);
    if (existing == null) return;

    final normalizedNote = (note ?? '').trim();
    final updatedHive = TransactionHiveModel(
      id: existing.id,
      userId: existing.userId,
      accountId: existing.accountId,
      kindIndex: existing.kindIndex,
      goalId: existing.goalId,
      groupId: existing.groupId,
      amountCents: existing.amountCents,
      occurredAtMillis: existing.occurredAtMillis,
      note: normalizedNote.isEmpty ? null : normalizedNote,
      pendingSync: _appConfig.isSupabaseConfigured ? true : existing.pendingSync,
      isRecurring: existing.isRecurring,
      frequencyIndex: existing.frequencyIndex,
      nextScheduledAtMillis: existing.nextScheduledAtMillis,
    );

    await _box.put(transactionId, updatedHive);
    _notify();

    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      final tx = transactionFromHive(updatedHive);
      await q.enqueue(
        PendingSyncOperationType.insertTransaction,
        encodeTransactionPayload(tx),
      );
    }
  }

  @override
  Future<void> updateTransactionRecurringConfig({
    required String transactionId,
    required bool isRecurring,
    required TransactionFrequency frequency,
  }) async {
    final existing = _box.get(transactionId);
    if (existing == null) return;

    final normalizedIsRecurring =
        isRecurring && frequency != TransactionFrequency.none;
    final now = DateTime.now();
    final next = normalizedIsRecurring
        ? _computeNextScheduledDate(now, frequency)
        : null;

    final updatedHive = TransactionHiveModel(
      id: existing.id,
      userId: existing.userId,
      accountId: existing.accountId,
      kindIndex: existing.kindIndex,
      goalId: existing.goalId,
      groupId: existing.groupId,
      amountCents: existing.amountCents,
      occurredAtMillis: existing.occurredAtMillis,
      note: existing.note,
      pendingSync: _appConfig.isSupabaseConfigured ? true : existing.pendingSync,
      isRecurring: normalizedIsRecurring,
      frequencyIndex: normalizedIsRecurring ? frequency.index : 0,
      nextScheduledAtMillis: next?.millisecondsSinceEpoch,
    );

    await _box.put(transactionId, updatedHive);
    _notify();

    final q = _pendingSyncQueue;
    if (_appConfig.isSupabaseConfigured && q != null) {
      final tx = transactionFromHive(updatedHive);
      await q.enqueue(
        PendingSyncOperationType.insertTransaction,
        encodeTransactionPayload(tx),
      );
    }
  }

  @override
  Future<void> markTransactionSynced(String transactionId) async {
    final hive = _box.get(transactionId);
    if (hive == null) return;
    await _box.put(
      transactionId,
      TransactionHiveModel(
        id: hive.id,
        userId: hive.userId,
        accountId: hive.accountId,
        goalId: hive.goalId,
        groupId: hive.groupId,
        kindIndex: hive.kindIndex,
        amountCents: hive.amountCents,
        occurredAtMillis: hive.occurredAtMillis,
        note: hive.note,
        pendingSync: false,
        isRecurring: hive.isRecurring,
        frequencyIndex: hive.frequencyIndex,
        nextScheduledAtMillis: hive.nextScheduledAtMillis,
      ),
    );
    _notify();
  }

  @override
  Future<void> pullRemote() async {
    if (!_appConfig.isSupabaseConfigured) return;
    final client = _supabase;
    if (client == null) return;
    if ((_pendingSyncQueue?.length ?? 0) > 0) return;

    final uid = await _userContext.resolveUserId();
    final response = await client
        .from(SupabaseTables.transactions)
        .select()
        .eq('user_id', uid);
    final rows = response as List<dynamic>;

    if (rows.isEmpty) {
      final hasLocal = _box.values.any((h) => h.userId == uid);
      if (hasLocal) return;
    }

    await _box.clear();
    for (final raw in rows) {
      final t =
          transactionFromSupabaseRow(Map<String, dynamic>.from(raw as Map));
      await _box.put(t.id, transactionToHive(t));
    }
    _notify();
  }

  DateTime _computeNextScheduledDate(
    DateTime from,
    TransactionFrequency frequency,
  ) {
    return switch (frequency) {
      TransactionFrequency.daily => from.add(const Duration(days: 1)),
      TransactionFrequency.weekly => from.add(const Duration(days: 7)),
      TransactionFrequency.monthly => _addMonthsClamped(from, 1),
      TransactionFrequency.yearly => _addYearsClamped(from, 1),
      TransactionFrequency.none => from,
    };
  }

  DateTime _addMonthsClamped(DateTime from, int monthsToAdd) {
    final targetMonthIndex = (from.year * 12 + (from.month - 1)) + monthsToAdd;
    final year = targetMonthIndex ~/ 12;
    final month = (targetMonthIndex % 12) + 1;
    final day = _clampDayOfMonth(year, month, from.day);
    return DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  DateTime _addYearsClamped(DateTime from, int yearsToAdd) {
    final year = from.year + yearsToAdd;
    final month = from.month;
    final day = _clampDayOfMonth(year, month, from.day);
    return DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }

  int _clampDayOfMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day > lastDay ? lastDay : day;
  }
}

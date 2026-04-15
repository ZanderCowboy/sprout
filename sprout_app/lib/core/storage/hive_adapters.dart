import 'package:hive/hive.dart';

import 'package:sprout/features/accounts/accounts.dart';
import 'package:sprout/features/goals/goals.dart';
import 'package:sprout/features/transactions/transactions.dart';

const int _typeAccount = 0;
const int _typeGoal = 1;
const int _typeTransaction = 2;
const int _typePendingSync = 3;

void registerHiveAdapters() {
  Hive
    ..registerAdapter(AccountHiveAdapter())
    ..registerAdapter(GoalHiveAdapter())
    ..registerAdapter(TransactionHiveAdapter())
    ..registerAdapter(PendingSyncHiveAdapter());
}

class AccountHiveAdapter extends TypeAdapter<AccountHiveModel> {
  @override
  int get typeId => _typeAccount;

  @override
  AccountHiveModel read(BinaryReader reader) {
    return AccountHiveModel(
      id: reader.readString(),
      userId: reader.readString(),
      name: reader.readString(),
      color: reader.readInt(),
      createdAtMillis: reader.readInt(),
      updatedAtMillis: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, AccountHiveModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.userId)
      ..writeString(obj.name)
      ..writeInt(obj.color)
      ..writeInt(obj.createdAtMillis)
      ..writeInt(obj.updatedAtMillis);
  }
}

class GoalHiveAdapter extends TypeAdapter<GoalHiveModel> {
  @override
  int get typeId => _typeGoal;

  @override
  GoalHiveModel read(BinaryReader reader) {
    return GoalHiveModel(
      id: reader.readString(),
      userId: reader.readString(),
      name: reader.readString(),
      targetAmountCents: reader.readInt(),
      color: reader.readInt(),
      createdAtMillis: reader.readInt(),
      updatedAtMillis: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, GoalHiveModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.userId)
      ..writeString(obj.name)
      ..writeInt(obj.targetAmountCents)
      ..writeInt(obj.color)
      ..writeInt(obj.createdAtMillis)
      ..writeInt(obj.updatedAtMillis);
  }
}

class TransactionHiveAdapter extends TypeAdapter<TransactionHiveModel> {
  @override
  int get typeId => _typeTransaction;

  @override
  TransactionHiveModel read(BinaryReader reader) {
    // Backward-compatible read:
    // Older versions wrote only: id, userId, accountId, goalId, amountCents,
    // occurredAtMillis, note?, pendingSync. Newer versions append recurring fields.
    // We attempt to read the new fields; if they aren't present, we default safely.
    bool isRecurring = false;
    int frequencyIndex = 0;
    int? nextScheduledAtMillis;
    int kindIndex = 0;

    return TransactionHiveModel(
      id: reader.readString(),
      userId: reader.readString(),
      accountId: reader.readString(),
      goalId: reader.readString(),
      amountCents: reader.readInt(),
      occurredAtMillis: reader.readInt(),
      note: reader.readBool() ? reader.readString() : null,
      pendingSync: reader.readBool(),
      isRecurring: (() {
        try {
          isRecurring = reader.readBool();
        } on Object {
          // ignore: no-op
        }
        return isRecurring;
      })(),
      frequencyIndex: (() {
        try {
          frequencyIndex = reader.readInt();
        } on Object {
          // ignore: no-op
        }
        return frequencyIndex;
      })(),
      nextScheduledAtMillis: (() {
        try {
          final hasNext = reader.readBool();
          if (hasNext) {
            nextScheduledAtMillis = reader.readInt();
          }
        } on Object {
          // ignore: no-op
        }
        return nextScheduledAtMillis;
      })(),
      kindIndex: (() {
        try {
          kindIndex = reader.readInt();
        } on Object {
          // ignore: no-op
        }
        return kindIndex;
      })(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionHiveModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.userId)
      ..writeString(obj.accountId)
      ..writeString(obj.goalId)
      ..writeInt(obj.amountCents)
      ..writeInt(obj.occurredAtMillis);
    final n = obj.note;
    if (n != null) {
      writer
        ..writeBool(true)
        ..writeString(n);
    } else {
      writer.writeBool(false);
    }
    writer
      ..writeBool(obj.pendingSync)
      ..writeBool(obj.isRecurring)
      ..writeInt(obj.frequencyIndex);
    final nextMillis = obj.nextScheduledAtMillis;
    if (nextMillis != null) {
      writer
        ..writeBool(true)
        ..writeInt(nextMillis);
    } else {
      writer.writeBool(false);
    }
    writer.writeInt(obj.kindIndex);
  }
}

class PendingSyncHiveAdapter extends TypeAdapter<PendingSyncHiveModel> {
  @override
  int get typeId => _typePendingSync;

  @override
  PendingSyncHiveModel read(BinaryReader reader) {
    return PendingSyncHiveModel(
      queueId: reader.readString(),
      operationTypeIndex: reader.readInt(),
      payloadJson: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, PendingSyncHiveModel obj) {
    writer
      ..writeString(obj.queueId)
      ..writeInt(obj.operationTypeIndex)
      ..writeString(obj.payloadJson);
  }
}

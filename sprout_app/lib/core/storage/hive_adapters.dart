import 'package:hive/hive.dart';

import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/budget/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';

const int _typeAccount = 0;
const int _typeGoal = 1;
const int _typeTransaction = 2;
const int _typePendingSync = 3;
const int _typeBudgetGroup = 4;

void registerHiveAdapters() {
  Hive
    ..registerAdapter(AccountHiveAdapter())
    ..registerAdapter(BudgetGroupHiveAdapter())
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
    bool recurringEnabled = false;

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
      recurringEnabled: (() {
        // Appended field; older rows won't have it.
        recurringEnabled = isRecurring;
        try {
          recurringEnabled = reader.readBool();
        } on Object {
          // ignore: no-op
        }
        return recurringEnabled;
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
    writer
      ..writeInt(obj.kindIndex)
      ..writeBool(obj.recurringEnabled);
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

class BudgetGroupHiveAdapter extends TypeAdapter<BudgetGroupHiveModel> {
  @override
  int get typeId => _typeBudgetGroup;

  @override
  BudgetGroupHiveModel read(BinaryReader reader) {
    // IMPORTANT: Read order must exactly match write order.
    final id = reader.readString();
    final userId = reader.readString();
    final name = reader.readString();
    final description = reader.readBool() ? reader.readString() : null;
    final colorHex = reader.readString();
    final iconCodePoint = reader.readBool() ? reader.readInt() : null;
    final iconFontFamily = reader.readBool() ? reader.readString() : null;
    return BudgetGroupHiveModel(
      id: id,
      userId: userId,
      name: name,
      description: description,
      colorHex: colorHex,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      categoryIndex: reader.readInt(),
      itemsJson: reader.readString(),
      createdAtMillis: reader.readInt(),
      updatedAtMillis: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, BudgetGroupHiveModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.userId)
      ..writeString(obj.name);
    final d = obj.description;
    if (d != null) {
      writer
        ..writeBool(true)
        ..writeString(d);
    } else {
      writer.writeBool(false);
    }
    writer.writeString(obj.colorHex);
    final cp = obj.iconCodePoint;
    if (cp != null) {
      writer
        ..writeBool(true)
        ..writeInt(cp);
    } else {
      writer.writeBool(false);
    }
    final ff = obj.iconFontFamily;
    if (ff != null) {
      writer
        ..writeBool(true)
        ..writeString(ff);
    } else {
      writer.writeBool(false);
    }
    writer
      ..writeInt(obj.categoryIndex)
      ..writeString(obj.itemsJson)
      ..writeInt(obj.createdAtMillis)
      ..writeInt(obj.updatedAtMillis);
  }
}

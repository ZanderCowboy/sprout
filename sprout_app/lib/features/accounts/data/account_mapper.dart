import '../domain/account.dart';
import 'local/account_hive_model.dart';

Account accountFromHive(AccountHiveModel m) => Account(
      id: m.id,
      userId: m.userId,
      name: m.name,
      color: m.color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m.updatedAtMillis),
    );

AccountHiveModel accountToHive(Account a) => AccountHiveModel(
      id: a.id,
      userId: a.userId,
      name: a.name,
      color: a.color,
      createdAtMillis: a.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: a.updatedAt.millisecondsSinceEpoch,
    );

Account accountFromSupabaseRow(Map<String, dynamic> row) {
  return Account(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    name: row['name'] as String,
    color: (row['color'] as num).toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );
}

Map<String, dynamic> accountToSupabaseRow(Account a) => {
      'id': a.id,
      'user_id': a.userId,
      'name': a.name,
      'color': a.color,
      'created_at': a.createdAt.toUtc().toIso8601String(),
      'updated_at': a.updatedAt.toUtc().toIso8601String(),
    };

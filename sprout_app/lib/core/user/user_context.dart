import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const String _kUserIdKey = 'active_user_id';

class UserContext {
  UserContext(
    this._settingsBox, {
    SupabaseClient? supabaseClient,
  }) : _supabase = supabaseClient;

  final Box<dynamic> _settingsBox;
  final SupabaseClient? _supabase;
  static const _uuid = Uuid();

  Future<String> resolveUserId() async {
    final authId = _supabase?.auth.currentUser?.id;
    if (authId != null && authId.isNotEmpty) {
      await _settingsBox.put(_kUserIdKey, authId);
      return authId;
    }
    final existing = _settingsBox.get(_kUserIdKey) as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final local = _uuid.v4();
    await _settingsBox.put(_kUserIdKey, local);
    return local;
  }

  String? get cachedUserId => _settingsBox.get(_kUserIdKey) as String?;
}

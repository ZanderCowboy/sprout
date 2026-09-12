import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const String _kUserIdKey = 'active_user_id';
const String _kLastVerifiedUserIdKey = 'last_verified_user_id';
const String _kIntroCompletedKey = 'intro_completed';
const String _kFirstRunCompletedKey = 'first_run_completed';
const String _kWelcomeToastKey = 'wizard_welcome_toast';

class UserContext {
  UserContext(this._settingsBox, {SupabaseClient? supabaseClient})
    : _supabase = supabaseClient;

  final Box<dynamic> _settingsBox;
  final SupabaseClient? _supabase;
  static const _uuid = Uuid();

  /// Prefers a verified (non-anonymous) Supabase uid; otherwise local Hive id.
  Future<String> resolveUserId() async {
    final authUser = _supabase?.auth.currentUser;
    final authId = authUser?.id;
    if (authUser != null &&
        !authUser.isAnonymous &&
        authId != null &&
        authId.isNotEmpty) {
      await _settingsBox.put(_kUserIdKey, authId);
      await _settingsBox.put(_kLastVerifiedUserIdKey, authId);
      return authId;
    }
    final existing = _settingsBox.get(_kUserIdKey) as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final local = _uuid.v4();
    await _settingsBox.put(_kUserIdKey, local);
    return local;
  }

  String? get cachedUserId => _settingsBox.get(_kUserIdKey) as String?;

  String? get lastVerifiedUserId =>
      _settingsBox.get(_kLastVerifiedUserIdKey) as String?;

  Future<void> setActiveUserId(String userId) async {
    await _settingsBox.put(_kUserIdKey, userId);
  }

  Future<void> markVerifiedUserId(String userId) async {
    await _settingsBox.put(_kLastVerifiedUserIdKey, userId);
  }

  bool _introCompleted = false;

  bool get introCompleted =>
      _introCompleted || _settingsBox.get(_kIntroCompletedKey) == true;

  Future<void> markIntroCompleted() async {
    _introCompleted = true;
    await _settingsBox.put(_kIntroCompletedKey, true);
  }

  Future<bool> getFirstRunCompleted(String userId) async {
    final key = '${_kFirstRunCompletedKey}_$userId';
    return _settingsBox.get(key) == true;
  }

  Future<void> markFirstRunCompleted(String userId) async {
    final key = '${_kFirstRunCompletedKey}_$userId';
    await _settingsBox.put(key, true);
  }

  Future<void> setPendingWelcomeToast(String userId, String message) async {
    await _settingsBox.put('${_kWelcomeToastKey}_$userId', message);
  }

  Future<String?> takePendingWelcomeToast(String userId) async {
    final key = '${_kWelcomeToastKey}_$userId';
    final value = _settingsBox.get(key) as String?;
    if (value != null) {
      await _settingsBox.delete(key);
    }
    return value;
  }
}

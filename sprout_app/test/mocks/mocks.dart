import 'dart:async';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/features/auth/domain/auth_repository.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  AuthUser? _currentUser;
  final _controller = StreamController<AuthUser?>.broadcast();

  int sendOtpCalls = 0;
  int verifyOtpCalls = 0;
  int googleCalls = 0;
  int updateDisplayNameCalls = 0;
  int deleteOwnAccountCalls = 0;
  int signOutCalls = 0;

  String? lastEmail;
  String? lastToken;
  String? lastDisplayName;
  Object? sendOtpError;
  Object? verifyOtpError;
  Object? googleError;
  Object? updateDisplayNameError;
  Object? deleteOwnAccountError;
  Object? signOutError;

  void setUser(AuthUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<void> sendEmailOtp(String email) async {
    sendOtpCalls++;
    lastEmail = email;
    final error = sendOtpError;
    if (error != null) throw error;
  }

  @override
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    verifyOtpCalls++;
    lastEmail = email;
    lastToken = token;
    final error = verifyOtpError;
    if (error != null) throw error;
    final user = AuthUser(id: 'verified-uid', email: email, isAnonymous: false);
    setUser(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    googleCalls++;
    final error = googleError;
    if (error != null) throw error;
    const user = AuthUser(
      id: 'google-uid',
      email: 'user@gmail.com',
      displayName: 'Google User',
      isAnonymous: false,
      signedInWithGoogle: true,
    );
    setUser(user);
    return user;
  }

  @override
  Future<AuthUser> updateDisplayName(String displayName) async {
    updateDisplayNameCalls++;
    lastDisplayName = displayName;
    final error = updateDisplayNameError;
    if (error != null) throw error;
    final current = _currentUser;
    if (current == null) {
      throw StateError('No signed-in user to update.');
    }
    final user = AuthUser(
      id: current.id,
      email: current.email,
      displayName: displayName,
      isAnonymous: current.isAnonymous,
      signedInWithGoogle: current.signedInWithGoogle,
    );
    setUser(user);
    return user;
  }

  @override
  Future<void> deleteOwnAccount() async {
    deleteOwnAccountCalls++;
    final error = deleteOwnAccountError;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final error = signOutError;
    if (error != null) throw error;
    setUser(null);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeRemoteConfigService implements RemoteConfigService {
  FakeRemoteConfigService({Map<String, String> strings = const {}})
    : _strings = Map.of(strings);

  final Map<String, String> _strings;

  @override
  bool get isReady => true;

  @override
  Future<void> setup(AppConfig config) async {}

  @override
  Future<bool> fetchFlags() async => true;

  @override
  bool isEnabled(RemoteFeatureFlag flag) => flag.defaultValue;

  @override
  String? getString(String key) {
    final value = _strings[key];
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

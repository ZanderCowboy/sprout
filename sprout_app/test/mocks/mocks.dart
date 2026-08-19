import 'dart:async';

import 'package:sprout/features/auth/domain/auth_repository.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  AuthUser? _currentUser;
  final _controller = StreamController<AuthUser?>.broadcast();

  int sendOtpCalls = 0;
  int verifyOtpCalls = 0;
  int googleCalls = 0;
  int signOutCalls = 0;

  String? lastEmail;
  String? lastToken;
  Object? sendOtpError;
  Object? verifyOtpError;
  Object? googleError;
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
      isAnonymous: false,
    );
    setUser(user);
    return user;
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

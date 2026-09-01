import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import '../../application/auth_service.dart';
import '../../domain/auth_user.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthViewState> {
  AuthCubit({required AuthService authService, required AppConfig appConfig})
    : _authService = authService,
      _appConfig = appConfig,
      super(const AuthViewLoading()) {
    _subscription = _authService.authStateChanges().listen(_onAuthChanged);
    _emitFromCurrent();
  }

  final AuthService _authService;
  final AppConfig _appConfig;
  StreamSubscription<AuthUser?>? _subscription;

  bool get _googleAvailable => _appConfig.isGoogleSignInConfigured;

  /// Development flavor only. Production never shows the debug sign-in button.
  bool get debugSignInAvailable => _authService.debugSignInAvailable;

  /// Development-only: skip OTP/Google and bind a stable local test user.
  Future<void> debugSignIn() async {
    final current = state;
    if (current is AuthViewGuest && current.busy) return;
    if (current is AuthViewGuest) {
      emit(current.copyWith(busy: true, clearError: true, clearInfo: true));
    }
    try {
      await _authService.debugSignIn();
      if (isClosed) return;
      emit(const AuthViewSignedIn(user: AuthService.maestroTestUser));
    } on AppException catch (e) {
      if (isClosed) return;
      if (current is AuthViewGuest) {
        emit(
          current.copyWith(
            busy: false,
            errorMessage: e.toFailure().message,
            clearInfo: true,
          ),
        );
      }
    }
  }

  void emailChanged(String email) {
    final current = state;
    if (current is! AuthViewGuest || current.busy) return;
    emit(current.copyWith(email: email, clearError: true, clearInfo: true));
  }

  void displayNameChanged(String displayName) {
    final current = state;
    if (current is! AuthViewGuest || current.busy) return;
    emit(
      current.copyWith(
        displayName: displayName,
        clearError: true,
        clearInfo: true,
      ),
    );
  }

  Future<void> sendOtp() async {
    final current = state;
    if (current is! AuthViewGuest || current.busy) return;
    if (!current.supabaseConfigured) return;

    emit(current.copyWith(busy: true, clearError: true, clearInfo: true));
    try {
      await _authService.sendEmailOtp(current.email);
      if (isClosed) return;
      emit(
        current.copyWith(
          busy: false,
          otpSent: true,
          infoMessage: AppStrings.checkEmailForCode,
          clearError: true,
        ),
      );
    } on AppException catch (e) {
      if (isClosed) return;
      emit(
        current.copyWith(
          busy: false,
          errorMessage: e.toFailure().message,
          clearInfo: true,
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        current.copyWith(
          busy: false,
          errorMessage: e.toString(),
          clearInfo: true,
        ),
      );
    }
  }

  Future<void> verifyOtp(String token) async {
    final current = state;
    if (current is! AuthViewGuest || current.busy) return;
    if (!current.supabaseConfigured) return;

    emit(current.copyWith(busy: true, clearError: true, clearInfo: true));
    try {
      await _authService.verifyEmailOtp(
        email: current.email,
        token: token,
        displayName: current.displayName,
      );
      if (isClosed) return;
      _emitFromCurrent();
    } on AppException catch (e) {
      if (isClosed) return;
      emit(
        current.copyWith(
          busy: false,
          errorMessage: e.toFailure().message,
          clearInfo: true,
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        current.copyWith(
          busy: false,
          errorMessage: e.toString(),
          clearInfo: true,
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    final current = state;
    if (current is! AuthViewGuest || current.busy) return;
    if (!current.supabaseConfigured || !current.googleAvailable) return;

    emit(current.copyWith(busy: true, clearError: true, clearInfo: true));
    try {
      await _authService.signInWithGoogle();
      if (isClosed) return;
      _emitFromCurrent();
    } on AppException catch (e) {
      if (isClosed) return;
      emit(
        current.copyWith(
          busy: false,
          errorMessage: e.toFailure().message,
          clearInfo: true,
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        current.copyWith(
          busy: false,
          errorMessage: e.toString(),
          clearInfo: true,
        ),
      );
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final current = state;
    if (current is! AuthViewSignedIn || current.busy) return;

    emit(current.copyWith(busy: true, clearError: true));
    try {
      final user = await _authService.updateDisplayName(displayName);
      if (isClosed) return;
      emit(AuthViewSignedIn(user: user));
    } on AppException catch (e) {
      if (isClosed) return;
      emit(current.copyWith(busy: false, errorMessage: e.toFailure().message));
    } on Object catch (e) {
      if (isClosed) return;
      emit(current.copyWith(busy: false, errorMessage: e.toString()));
    }
  }

  Future<void> signOut() async {
    final current = state;
    if (current is! AuthViewSignedIn || current.busy) return;

    emit(current.copyWith(busy: true, clearError: true));
    try {
      await _authService.signOut();
      if (isClosed) return;
      _emitFromCurrent();
    } on AppException catch (e) {
      if (isClosed) return;
      emit(current.copyWith(busy: false, errorMessage: e.toFailure().message));
    } on Object catch (e) {
      if (isClosed) return;
      emit(current.copyWith(busy: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteAccount() async {
    final current = state;
    if (current is! AuthViewSignedIn || current.busy) return;

    emit(current.copyWith(busy: true, clearError: true));
    try {
      await _authService.deleteAccount();
      if (isClosed) return;
      _emitFromCurrent();
    } on AppException catch (e) {
      if (isClosed) return;
      emit(current.copyWith(busy: false, errorMessage: e.toFailure().message));
    } on Object catch (e) {
      if (isClosed) return;
      emit(current.copyWith(busy: false, errorMessage: e.toString()));
    }
  }

  void _onAuthChanged(AuthUser? user) {
    _emitFromUser(user);
  }

  void _emitFromCurrent() {
    _emitFromUser(_authService.currentUser);
  }

  void _emitFromUser(AuthUser? user) {
    if (isClosed) return;
    if (user != null && user.isVerified) {
      emit(AuthViewSignedIn(user: user));
      return;
    }
    if (_authService.isDebugSignedIn) {
      emit(const AuthViewSignedIn(user: AuthService.maestroTestUser));
      return;
    }
    final previous = state;
    final email = previous is AuthViewGuest ? previous.email : '';
    final displayName = previous is AuthViewGuest ? previous.displayName : '';
    final otpSent = previous is AuthViewGuest ? previous.otpSent : false;
    emit(
      AuthViewGuest(
        supabaseConfigured: _appConfig.isSupabaseConfigured,
        googleAvailable: _googleAvailable,
        email: email,
        displayName: displayName,
        otpSent: otpSent,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

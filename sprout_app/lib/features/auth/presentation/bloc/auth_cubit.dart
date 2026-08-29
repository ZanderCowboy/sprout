import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/error/error.dart';
import '../../application/auth_service.dart';
import '../../domain/auth_user.dart';

sealed class AuthViewState extends Equatable {
  const AuthViewState();

  @override
  List<Object?> get props => [];
}

final class AuthViewLoading extends AuthViewState {
  const AuthViewLoading();
}

final class AuthViewGuest extends AuthViewState {
  const AuthViewGuest({
    required this.supabaseConfigured,
    required this.googleAvailable,
    this.email = '',
    this.displayName = '',
    this.otpSent = false,
    this.busy = false,
    this.errorMessage,
    this.infoMessage,
  });

  final bool supabaseConfigured;
  final bool googleAvailable;
  final String email;
  final String displayName;
  final bool otpSent;
  final bool busy;
  final String? errorMessage;
  final String? infoMessage;

  AuthViewGuest copyWith({
    bool? supabaseConfigured,
    bool? googleAvailable,
    String? email,
    String? displayName,
    bool? otpSent,
    bool? busy,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthViewGuest(
      supabaseConfigured: supabaseConfigured ?? this.supabaseConfigured,
      googleAvailable: googleAvailable ?? this.googleAvailable,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      otpSent: otpSent ?? this.otpSent,
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }

  @override
  List<Object?> get props => [
    supabaseConfigured,
    googleAvailable,
    email,
    displayName,
    otpSent,
    busy,
    errorMessage,
    infoMessage,
  ];
}

final class AuthViewSignedIn extends AuthViewState {
  const AuthViewSignedIn({
    required this.user,
    this.busy = false,
    this.errorMessage,
  });

  final AuthUser user;
  final bool busy;
  final String? errorMessage;

  AuthViewSignedIn copyWith({
    AuthUser? user,
    bool? busy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthViewSignedIn(
      user: user ?? this.user,
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [user, busy, errorMessage];
}

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

  /// Development-only: true when MAESTRO_BYPASS_AUTH compile flag is set.
  bool get maestroBypassAuthEnabled => _authService.maestroBypassAuthEnabled;

  /// Development-only: bypass OTP/Google and bind a stable test user.
  Future<void> bypassAuthForMaestro() async {
    await _authService.bypassAuthForMaestro();
    // After bypass, emit SignedIn with a synthetic local user.
    const testUser = AuthUser(
      id: 'maestro-test-user',
      email: 'maestro@test.local',
      displayName: 'Maestro Test',
      isAnonymous: false,
      signedInWithGoogle: false,
    );
    emit(const AuthViewSignedIn(user: testUser));
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
          infoMessage: 'Check your email for a 6-digit code.',
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

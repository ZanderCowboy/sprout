part of 'auth_cubit.dart';

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

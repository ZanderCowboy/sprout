import 'package:equatable/equatable.dart';

/// Reads a display name from Supabase `user_metadata`.
///
/// Preference order: `display_name`, `full_name`, `name`.
String? displayNameFromMetadata(Map<String, dynamic>? metadata) {
  if (metadata == null) return null;
  const keys = ['display_name', 'full_name', 'name'];
  for (final key in keys) {
    final value = metadata[key];
    if (value is! String) continue;
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// True when Google is listed on identities or in `app_metadata`.
bool signedInWithGoogleFromAuth({
  Iterable<String> identityProviders = const [],
  Map<String, dynamic>? appMetadata,
}) {
  for (final provider in identityProviders) {
    if (provider == 'google') return true;
  }
  final metadata = appMetadata;
  if (metadata == null) return false;
  if (metadata['provider'] == 'google') return true;
  final providers = metadata['providers'];
  if (providers is List) {
    return providers.any((entry) => entry == 'google');
  }
  return false;
}

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.isAnonymous,
    this.email,
    this.displayName,
    this.signedInWithGoogle = false,
  });

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  final bool signedInWithGoogle;

  bool get isVerified => !isAnonymous;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    isAnonymous,
    signedInWithGoogle,
  ];
}

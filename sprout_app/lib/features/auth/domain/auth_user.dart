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

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.isAnonymous,
    this.email,
    this.displayName,
  });

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  bool get isVerified => !isAnonymous;

  @override
  List<Object?> get props => [id, email, displayName, isAnonymous];
}

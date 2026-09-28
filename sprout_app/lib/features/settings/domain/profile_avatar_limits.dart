/// Locked storage / crop limits for profile avatars (#117).
abstract final class ProfileAvatarLimits {
  /// Max long side of the stored JPEG (px).
  static const int maxLongSidePx = 512;

  /// Soft / hard file-size cap (~2 MB).
  static const int maxBytes = 2 * 1024 * 1024;

  /// JPEG encode quality after crop + resize.
  static const int jpegQuality = 85;

  /// Supabase Storage bucket id.
  static const String bucketId = 'avatars';

  /// Object name under `{uid}/`.
  static const String objectName = 'avatar.jpg';

  /// Storage object path for [userId].
  static String objectPath(String userId) => '$userId/$objectName';
}

import 'dart:typed_data';

import 'package:sprout/features/auth/domain/auth_user.dart';

/// Uploads, resolves, and removes the signed-in user's profile avatar.
abstract class ProfileAvatarService {
  /// Creates a short-lived signed URL for [avatarPath], or null when unset.
  Future<String?> resolveDisplayUrl(String? avatarPath);

  /// Crops/resizes are done by the caller; this uploads JPEG [bytes] and
  /// updates `user_metadata.avatar_path`. Keeps the prior avatar on failure.
  Future<AuthUser> uploadAvatar(Uint8List bytes);

  /// Deletes the Storage object and clears `avatar_path`.
  Future<AuthUser> removeAvatar();

  /// True while an upload or remove is in flight (blocks concurrent work).
  bool get isBusy;
}

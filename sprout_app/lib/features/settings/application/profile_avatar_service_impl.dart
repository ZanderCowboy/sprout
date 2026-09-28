import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/auth/domain/auth_repository.dart';
import 'package:sprout/features/auth/domain/auth_user.dart';
import 'package:sprout/features/settings/domain/profile_avatar_limits.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'profile_avatar_service.dart';

class ProfileAvatarServiceImpl implements ProfileAvatarService {
  ProfileAvatarServiceImpl({
    required AuthRepository authRepository,
    required SupabaseClient? supabase,
  }) : _authRepository = authRepository,
       _supabase = supabase;

  final AuthRepository _authRepository;
  final SupabaseClient? _supabase;
  bool _busy = false;

  @override
  bool get isBusy => _busy;

  SupabaseClient get _client {
    final client = _supabase;
    if (client == null) {
      throw const AuthAppException(AppStrings.supabaseNotConfigured);
    }
    return client;
  }

  @override
  Future<String?> resolveDisplayUrl(String? avatarPath) async {
    final path = avatarPath?.trim();
    if (path == null || path.isEmpty) return null;
    try {
      return await _client.storage
          .from(ProfileAvatarLimits.bucketId)
          .createSignedUrl(path, 60 * 60);
    } on Object {
      return null;
    }
  }

  @override
  Future<AuthUser> uploadAvatar(Uint8List bytes) async {
    if (_busy) {
      throw const ValidationAppException(AppStrings.avatarUploadFailed);
    }
    final user = _authRepository.currentUser;
    if (user == null || !user.isVerified) {
      throw const AuthAppException(AppStrings.verifiedSessionRequired);
    }

    _busy = true;
    try {
      final encoded = _encodeAvatarJpeg(bytes);
      final path = ProfileAvatarLimits.objectPath(user.id);
      await _client.storage
          .from(ProfileAvatarLimits.bucketId)
          .uploadBinary(
            path,
            encoded,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      return await _authRepository.updateAvatarPath(path);
    } on StorageException catch (e) {
      throw AuthAppException(e.message);
    } on AppException {
      rethrow;
    } on Object {
      throw const AuthAppException(AppStrings.avatarUploadFailed);
    } finally {
      _busy = false;
    }
  }

  @override
  Future<AuthUser> removeAvatar() async {
    if (_busy) {
      throw const ValidationAppException(AppStrings.avatarUploadFailed);
    }
    final user = _authRepository.currentUser;
    if (user == null || !user.isVerified) {
      throw const AuthAppException(AppStrings.verifiedSessionRequired);
    }

    _busy = true;
    try {
      final path = user.avatarPath ?? ProfileAvatarLimits.objectPath(user.id);
      try {
        await _client.storage.from(ProfileAvatarLimits.bucketId).remove([path]);
      } on StorageException {
        // Object may already be gone; still clear metadata.
      }
      return await _authRepository.updateAvatarPath(null);
    } on AppException {
      rethrow;
    } on Object {
      throw const AuthAppException(AppStrings.avatarUploadFailed);
    } finally {
      _busy = false;
    }
  }

  /// Decodes, downscales to [ProfileAvatarLimits.maxLongSidePx], encodes JPEG.
  static Uint8List encodeAvatarJpegForTest(Uint8List bytes) =>
      _encodeAvatarJpeg(bytes);

  static Uint8List _encodeAvatarJpeg(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ValidationAppException(AppStrings.avatarInvalid);
    }
    if (bytes.lengthInBytes > ProfileAvatarLimits.maxBytes * 4) {
      // Reject absurd raw picks early (before decode).
      throw const ValidationAppException(AppStrings.avatarTooLarge);
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const ValidationAppException(AppStrings.avatarInvalid);
    }

    final longSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    final img.Image prepared;
    if (longSide > ProfileAvatarLimits.maxLongSidePx) {
      final scale = ProfileAvatarLimits.maxLongSidePx / longSide;
      prepared = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    } else {
      prepared = decoded;
    }

    final encoded = Uint8List.fromList(
      img.encodeJpg(prepared, quality: ProfileAvatarLimits.jpegQuality),
    );
    if (encoded.lengthInBytes > ProfileAvatarLimits.maxBytes) {
      throw const ValidationAppException(AppStrings.avatarTooLarge);
    }
    return encoded;
  }
}

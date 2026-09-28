import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sprout/core/error/error.dart';
import 'package:sprout/features/settings/application/profile_avatar_service_impl.dart';
import 'package:sprout/features/settings/domain/profile_avatar_limits.dart';

Uint8List _png({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(20, 180, 90));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('encode downscales long side to 512 and stays under max bytes', () {
    final raw = _png(width: 1200, height: 800);
    final encoded = ProfileAvatarServiceImpl.encodeAvatarJpegForTest(raw);
    final decoded = img.decodeJpg(encoded)!;
    expect(decoded.width, lessThanOrEqualTo(ProfileAvatarLimits.maxLongSidePx));
    expect(
      decoded.height,
      lessThanOrEqualTo(ProfileAvatarLimits.maxLongSidePx),
    );
    expect(encoded.lengthInBytes, lessThanOrEqualTo(ProfileAvatarLimits.maxBytes));
  });

  test('encode rejects empty bytes', () {
    expect(
      () => ProfileAvatarServiceImpl.encodeAvatarJpegForTest(Uint8List(0)),
      throwsA(isA<ValidationAppException>()),
    );
  });
}

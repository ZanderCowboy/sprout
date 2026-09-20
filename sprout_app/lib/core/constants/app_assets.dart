import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Typed asset paths. Prefer these over hardcoded `assets/...` strings.
///
/// This repo does not run flutter_gen / build_runner; add a field here when
/// a new file is registered under `assets/` in `pubspec.yaml`.
abstract final class AppAssets {
  static const sproutIcon = AppAssetImage.image(
    'assets/images/sprout-icon.png',
  );
  static const googleGLogo = AppAssetImage.svg(
    'assets/images/google_g_logo.svg',
  );
}

/// Raster or SVG asset so call sites never pass a raw path string.
final class AppAssetImage {
  const AppAssetImage.image(this.path) : _isSvg = false;

  const AppAssetImage.svg(this.path) : _isSvg = true;

  final String path;
  final bool _isSvg;

  Widget image({
    Key? key,
    double? width,
    double? height,
    Color? color,
    BoxFit? fit,
  }) {
    if (_isSvg) {
      return SvgPicture.asset(
        path,
        key: key,
        width: width,
        height: height,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
        fit: fit ?? BoxFit.contain,
      );
    }
    return Image.asset(
      path,
      key: key,
      width: width,
      height: height,
      color: color,
      fit: fit,
    );
  }
}

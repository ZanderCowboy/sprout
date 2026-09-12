import 'package:flutter/widgets.dart';

/// Typed asset paths. Prefer these over hardcoded `assets/...` strings.
///
/// This repo does not run flutter_gen / build_runner; add a field here when
/// a new file is registered under `assets/` in `pubspec.yaml`.
abstract final class AppAssets {
  static const sproutIcon = AppAssetImage('assets/images/sprout-icon.png');
}

/// [Image.asset] wrapper so call sites never pass a raw path string.
final class AppAssetImage {
  const AppAssetImage(this.path);

  final String path;

  Image image({
    Key? key,
    double? width,
    double? height,
    Color? color,
    BoxFit? fit,
  }) {
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

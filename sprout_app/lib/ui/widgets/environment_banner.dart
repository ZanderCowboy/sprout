import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/constants/app_strings.dart';

/// Diagonal corner ribbon indicating the active [AppEnvironment].
///
/// Hidden only for production release builds.
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({
    super.key,
    required this.environment,
    required this.child,
  });

  final AppEnvironment environment;
  final Widget child;

  bool get _shouldHide =>
      environment == AppEnvironment.production && kReleaseMode;

  String get _label => switch (environment) {
    AppEnvironment.development => AppStrings.environmentDev,
    AppEnvironment.production => AppStrings.environmentProd,
  };

  Color get _color => switch (environment) {
    AppEnvironment.development => AppColors.environmentDev,
    AppEnvironment.production => AppColors.environmentProd,
  };

  @override
  Widget build(BuildContext context) {
    if (_shouldHide) return child;

    return Banner(
      message: _label,
      location: BannerLocation.topEnd,
      color: _color,
      textStyle: const TextStyle(
        color: AppColors.surfaceDeep,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        height: 1,
      ),
      child: child,
    );
  }
}

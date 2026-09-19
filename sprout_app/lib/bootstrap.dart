import 'package:flutter/widgets.dart';

import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/features/startup/startup_flow.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:debug_lens/debug_lens.dart';

Future<void> bootstrap({
  required String configAssetPath,
  required AppEnvironment environment,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  DebugLens.debugLensEnabled = false;

  runApp(
    SproutBootstrapApp(
      configAssetPath: configAssetPath,
      environment: environment,
    ),
  );
}

/// Returns true when DebugLens should be enabled.
///
/// Enabled when development OR production with `debug_lens_enabled` flag.
bool shouldEnableDebugLens() {
  final config = sl<AppConfig>();
  if (config.environment == AppEnvironment.development) {
    return true;
  }
  final remoteConfig = sl<RemoteConfigService>();
  return remoteConfig.isEnabled(RemoteFeatureFlag.debugLensEnabled);
}

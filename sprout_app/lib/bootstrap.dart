import 'package:flutter/widgets.dart';

import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/features/startup/startup_flow.dart';

Future<void> bootstrap({
  required String configAssetPath,
  required AppEnvironment environment,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    SproutBootstrapApp(
      configAssetPath: configAssetPath,
      environment: environment,
    ),
  );
}

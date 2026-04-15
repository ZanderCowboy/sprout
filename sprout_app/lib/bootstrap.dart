import 'package:flutter/widgets.dart';

import 'package:sprout/features/startup/startup_flow.dart';

Future<void> bootstrap({required String configAssetPath}) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(SproutBootstrapApp(configAssetPath: configAssetPath));
}

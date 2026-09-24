import 'package:sprout/core/config/app_environment.dart';

import 'bootstrap.dart';

/// Same as [main_development] — default for `flutter run` without `-t`.
Future<void> main() async {
  await bootstrap(
    configAssetPath: 'assets/config/development.json',
    environment: AppEnvironment.development,
  );
}

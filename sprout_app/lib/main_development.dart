import 'bootstrap.dart';
import 'package:sprout/core/config/app_environment.dart';

/// Entry point that loads [assets/config/development.json].
Future<void> main() async {
  await bootstrap(
    configAssetPath: 'assets/config/development.json',
    environment: AppEnvironment.development,
  );
}

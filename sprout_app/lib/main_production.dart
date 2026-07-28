import 'bootstrap.dart';
import 'package:sprout/core/config/app_environment.dart';

/// Entry point that loads [assets/config/production.json].
Future<void> main() async {
  await bootstrap(
    configAssetPath: 'assets/config/production.json',
    environment: AppEnvironment.production,
  );
}

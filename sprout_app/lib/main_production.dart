import 'bootstrap.dart';

/// Entry point that loads [assets/config/production.json].
Future<void> main() async {
  await bootstrap(configAssetPath: 'assets/config/production.json');
}

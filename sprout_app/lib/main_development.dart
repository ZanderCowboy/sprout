import 'bootstrap.dart';

/// Entry point that loads [assets/config/development.json].
Future<void> main() async {
  await bootstrap(configAssetPath: 'assets/config/development.json');
}

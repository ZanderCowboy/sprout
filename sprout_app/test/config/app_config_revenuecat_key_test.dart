import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';

AppConfig configWithKey(String key) {
  return AppConfig(
    environment: AppEnvironment.development,
    supabaseUrl: '',
    supabaseAnonKey: '',
    googleWebClientId: '',
    androidApplicationId: 'app.stackmint.sprout.dev',
    revenueCatAndroidApiKey: key,
    firebaseApiKey: '',
    firebaseAppId: '',
    firebaseMessagingSenderId: '',
    firebaseProjectId: '',
    firebaseStorageBucket: '',
  );
}

void main() {
  test('empty key is not configured', () {
    final config = configWithKey('');
    expect(config.isRevenueCatConfigured, isFalse);
    expect(config.isRevenueCatTestStoreKey, isFalse);
  });

  test('test_ prefix is Test Store', () {
    final config = configWithKey('test_placeholder_not_a_secret');
    expect(config.isRevenueCatConfigured, isTrue);
    expect(config.isRevenueCatTestStoreKey, isTrue);
  });

  test('goog_ prefix is not Test Store', () {
    final config = configWithKey('goog_placeholder_not_a_secret');
    expect(config.isRevenueCatConfigured, isTrue);
    expect(config.isRevenueCatTestStoreKey, isFalse);
  });
}

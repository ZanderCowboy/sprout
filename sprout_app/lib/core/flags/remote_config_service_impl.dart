import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';

class RemoteConfigServiceImpl implements RemoteConfigService {
  bool _firebaseReady = false;
  bool _remoteConfigReady = false;

  @override
  bool get isReady => _remoteConfigReady;

  @override
  Future<void> setup(AppConfig config) async {
    if (config.environment != AppEnvironment.development) {
      return;
    }
    if (!config.isFirebaseConfigured) {
      if (kDebugMode) {
        debugPrint(
          'RemoteConfigService.setup: Firebase options missing in config; '
          'skipping.',
        );
      }
      return;
    }

    try {
      if (!_firebaseReady) {
        await Firebase.initializeApp(options: config.toFirebaseOptions());
        _firebaseReady = true;
      }

      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults({
        for (final flag in RemoteFeatureFlag.values)
          flag.key: flag.defaultValue,
        RemoteConfigKeys.termsOfService: '',
        RemoteConfigKeys.privacyPolicy: '',
      });
      _remoteConfigReady = true;
    } on Object catch (e) {
      _remoteConfigReady = false;
      if (kDebugMode) {
        debugPrint('RemoteConfigService.setup failed: $e');
      }
    }
  }

  @override
  Future<bool> fetchFlags() async {
    if (!_remoteConfigReady) return false;
    try {
      return await FirebaseRemoteConfig.instance.fetchAndActivate();
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('RemoteConfigService.fetchFlags failed: $e');
      }
      return false;
    }
  }

  @override
  bool isEnabled(RemoteFeatureFlag flag) {
    if (!_remoteConfigReady) return flag.defaultValue;
    try {
      return FirebaseRemoteConfig.instance.getBool(flag.key);
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('RemoteConfigService.isEnabled(${flag.key}) failed: $e');
      }
      return flag.defaultValue;
    }
  }

  @override
  String? getString(String key) {
    if (!_remoteConfigReady) return null;
    try {
      final value = FirebaseRemoteConfig.instance.getString(key);
      if (value.isEmpty) return null;
      return value;
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('RemoteConfigService.getString($key) failed: $e');
      }
      return null;
    }
  }
}

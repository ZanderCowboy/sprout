import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';

/// Firebase Remote Config string parameter names.
abstract final class RemoteConfigKeys {
  /// Markdown Terms of Service. Empty default falls back to the bundled asset.
  static const termsOfService = 'terms_of_service';
}

/// Owns Firebase + Remote Config setup, separate from reading flag values.
class RemoteConfigService {
  bool _firebaseReady = false;
  bool _remoteConfigReady = false;

  bool get isReady => _remoteConfigReady;

  /// Initializes Firebase (once) and applies Remote Config settings + defaults.
  ///
  /// No-op (and leaves [isReady] false) when not development or Firebase
  /// options are missing from [AppConfig]. Does not fetch from the network.
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
      });
      _remoteConfigReady = true;
    } on Object catch (e) {
      _remoteConfigReady = false;
      if (kDebugMode) {
        debugPrint('RemoteConfigService.setup failed: $e');
      }
    }
  }

  /// Fetches and activates Remote Config from the network.
  ///
  /// Returns `false` if setup was skipped or fetch fails (fail-closed).
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

  /// Reads an activated flag. Uses [RemoteFeatureFlag.defaultValue] when not
  /// ready (fail-closed for kill switches that default to `false`).
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

  /// Reads an activated string parameter.
  ///
  /// Returns `null` when setup was skipped, fetch never ran, or the value is
  /// empty so callers can fall back to a bundled asset.
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

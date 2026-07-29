import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'package:sprout/core/config/app_environment.dart';

class AppConfigLoadResult {
  const AppConfigLoadResult({
    required this.config,
    required this.error,
    required this.stackTrace,
  });

  final AppConfig config;
  final Object? error;
  final StackTrace? stackTrace;
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.androidApplicationId,
    required this.revenueCatAndroidApiKey,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseMessagingSenderId,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
  });

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Play / Android applicationId this config is meant for (flavor reference).
  /// Not used by RevenueCat configure — the SDK key is [revenueCatAndroidApiKey].
  final String androidApplicationId;
  final String revenueCatAndroidApiKey;

  /// From gitignored config / `google-services.json` (not committed in Dart).
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String firebaseStorageBucket;

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  bool get isRevenueCatConfigured => revenueCatAndroidApiKey.isNotEmpty;

  bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  FirebaseOptions toFirebaseOptions() {
    if (!isFirebaseConfigured) {
      throw StateError(
        'Firebase options are not configured. Add a "firebase" object to '
        'the env JSON (see docs/REVENUECAT.md).',
      );
    }
    return FirebaseOptions(
      apiKey: firebaseApiKey,
      appId: firebaseAppId,
      messagingSenderId: firebaseMessagingSenderId,
      projectId: firebaseProjectId,
      storageBucket:
          firebaseStorageBucket.isEmpty ? null : firebaseStorageBucket,
    );
  }

  /// Throws if [isSupabaseConfigured] but URL/key look wrong (call after [load]).
  void assertValidSupabaseIfConfigured() {
    if (!isSupabaseConfigured) return;
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      throw StateError(
        'Invalid supabaseUrl: "$supabaseUrl". '
        'Expected https://<project-ref>.supabase.co (no trailing path required). '
        'See supabase/README.md.',
      );
    }
    final key = supabaseAnonKey.trim();
    if (key.length < 20) {
      throw StateError(
        'supabaseAnonKey looks too short. Use the anon / publishable key from '
        'Supabase Dashboard → Project Settings → API (see supabase/README.md).',
      );
    }
  }

  /// Loads JSON from a Flutter asset bundle path, e.g.
  /// `assets/config/development.json`.
  ///
  /// The asset must exist in the bundle; there is no fallback.
  ///
  /// Non-empty compile-time `SUPABASE_URL` / `SUPABASE_ANON_KEY` /
  /// `REVENUECAT_ANDROID_API_KEY` override JSON values (e.g. CI).
  static Future<AppConfig> load({
    required String configAssetPath,
    required AppEnvironment environment,
  }) async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const envRcKey = String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');

    final fromFile = await _loadConfigJson(
      configAssetPath,
      environment: environment,
    );

    return fromFile._withOverrides(
      envUrl: envUrl,
      envKey: envKey,
      envRcKey: envRcKey,
    );
  }

  /// Best-effort config load for startup fallback UI.
  ///
  /// - Never throws: on any error returns an empty config + the error/stack.
  /// - Still honors compile-time overrides (`SUPABASE_URL` / `SUPABASE_ANON_KEY` /
  ///   `REVENUECAT_ANDROID_API_KEY`).
  static Future<AppConfigLoadResult> tryLoad({
    required String configAssetPath,
    required AppEnvironment environment,
  }) async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const envRcKey = String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');

    try {
      final fromFile = await _loadConfigJson(
        configAssetPath,
        environment: environment,
      );
      final cfg = fromFile._withOverrides(
        envUrl: envUrl,
        envKey: envKey,
        envRcKey: envRcKey,
      );
      return AppConfigLoadResult(config: cfg, error: null, stackTrace: null);
    } on Object catch (e, st) {
      final cfg = AppConfig(
        environment: environment,
        supabaseUrl: envUrl,
        supabaseAnonKey: envKey,
        androidApplicationId: '',
        revenueCatAndroidApiKey: envRcKey,
        firebaseApiKey: '',
        firebaseAppId: '',
        firebaseMessagingSenderId: '',
        firebaseProjectId: '',
        firebaseStorageBucket: '',
      );
      return AppConfigLoadResult(config: cfg, error: e, stackTrace: st);
    }
  }

  AppConfig _withOverrides({
    required String envUrl,
    required String envKey,
    required String envRcKey,
  }) {
    return AppConfig(
      environment: environment,
      supabaseUrl: envUrl.isNotEmpty ? envUrl : supabaseUrl,
      supabaseAnonKey: envKey.isNotEmpty ? envKey : supabaseAnonKey,
      androidApplicationId: androidApplicationId,
      revenueCatAndroidApiKey: envRcKey.isNotEmpty
          ? envRcKey
          : revenueCatAndroidApiKey,
      firebaseApiKey: firebaseApiKey,
      firebaseAppId: firebaseAppId,
      firebaseMessagingSenderId: firebaseMessagingSenderId,
      firebaseProjectId: firebaseProjectId,
      firebaseStorageBucket: firebaseStorageBucket,
    );
  }

  static Future<AppConfig> _loadConfigJson(
    String assetPath, {
    required AppEnvironment environment,
  }) async {
    late final String raw;
    try {
      raw = await rootBundle.loadString(assetPath);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StateError(
          'Sprout config asset is missing or unreadable: "$assetPath". '
          'Create sprout_app/$assetPath with JSON keys supabaseUrl, '
          'supabaseAnonKey, androidApplicationId, revenueCatAndroidApiKey, '
          'and optional firebase { apiKey, appId, messagingSenderId, '
          'projectId, storageBucket } '
          '(see supabase/README.md and docs/REVENUECAT.md).',
        ),
        st,
      );
    }

    late final Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('root must be a JSON object');
      }
      map = decoded;
    } catch (e, st) {
      Error.throwWithStackTrace(
        StateError(
          'Sprout config at "$assetPath" is not valid JSON object: $e',
        ),
        st,
      );
    }

    final firebase = map['firebase'];
    final firebaseMap =
        firebase is Map<String, dynamic> ? firebase : const <String, dynamic>{};

    return AppConfig(
      environment: environment,
      supabaseUrl: (map['supabaseUrl'] as String?)?.trim() ?? '',
      supabaseAnonKey: (map['supabaseAnonKey'] as String?)?.trim() ?? '',
      androidApplicationId:
          (map['androidApplicationId'] as String?)?.trim() ?? '',
      revenueCatAndroidApiKey:
          (map['revenueCatAndroidApiKey'] as String?)?.trim() ?? '',
      firebaseApiKey: (firebaseMap['apiKey'] as String?)?.trim() ?? '',
      firebaseAppId: (firebaseMap['appId'] as String?)?.trim() ?? '',
      firebaseMessagingSenderId:
          (firebaseMap['messagingSenderId'] as String?)?.trim() ?? '',
      firebaseProjectId: (firebaseMap['projectId'] as String?)?.trim() ?? '',
      firebaseStorageBucket:
          (firebaseMap['storageBucket'] as String?)?.trim() ?? '',
    );
  }
}

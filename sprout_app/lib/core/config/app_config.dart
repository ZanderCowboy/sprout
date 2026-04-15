import 'dart:convert';

import 'package:flutter/services.dart';

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
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

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
  /// Non-empty compile-time `SUPABASE_URL` / `SUPABASE_ANON_KEY` override JSON
  /// values (e.g. CI).
  static Future<AppConfig> load({required String configAssetPath}) async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final fromFile = await _loadConfigJson(configAssetPath);

    return AppConfig(
      supabaseUrl: envUrl.isNotEmpty ? envUrl : fromFile.supabaseUrl,
      supabaseAnonKey: envKey.isNotEmpty ? envKey : fromFile.supabaseAnonKey,
    );
  }

  /// Best-effort config load for startup fallback UI.
  ///
  /// - Never throws: on any error returns an empty config + the error/stack.
  /// - Still honors compile-time overrides (`SUPABASE_URL` / `SUPABASE_ANON_KEY`).
  static Future<AppConfigLoadResult> tryLoad({
    required String configAssetPath,
  }) async {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    try {
      final fromFile = await _loadConfigJson(configAssetPath);
      final cfg = AppConfig(
        supabaseUrl: envUrl.isNotEmpty ? envUrl : fromFile.supabaseUrl,
        supabaseAnonKey: envKey.isNotEmpty ? envKey : fromFile.supabaseAnonKey,
      );
      return AppConfigLoadResult(config: cfg, error: null, stackTrace: null);
    } on Object catch (e, st) {
      final cfg = AppConfig(
        supabaseUrl: envUrl,
        supabaseAnonKey: envKey,
      );
      return AppConfigLoadResult(config: cfg, error: e, stackTrace: st);
    }
  }

  static Future<AppConfig> _loadConfigJson(String assetPath) async {
    late final String raw;
    try {
      raw = await rootBundle.loadString(assetPath);
    } catch (e, st) {
      Error.throwWithStackTrace(
        StateError(
          'Sprout config asset is missing or unreadable: "$assetPath". '
          'Create sprout_app/$assetPath with JSON keys supabaseUrl and '
          'supabaseAnonKey (see supabase/README.md).',
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

    return AppConfig(
      supabaseUrl: (map['supabaseUrl'] as String?)?.trim() ?? '',
      supabaseAnonKey: (map['supabaseAnonKey'] as String?)?.trim() ?? '',
    );
  }
}

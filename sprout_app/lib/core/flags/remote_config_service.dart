import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';

/// Firebase Remote Config string parameter names.
abstract final class RemoteConfigKeys {
  /// Markdown Terms of Service. Empty default falls back to the bundled asset.
  static const termsOfService = 'terms_of_service';

  /// Markdown Privacy Policy. Empty default falls back to the bundled asset.
  static const privacyPolicy = 'privacy_policy';
}

/// Owns Firebase + Remote Config setup and flag reads.
abstract class RemoteConfigService {
  /// True after Remote Config has been set up successfully.
  bool get isReady;

  /// Initializes Firebase (once) and applies Remote Config settings + defaults.
  ///
  /// No-op (and leaves [isReady] false) when not development or Firebase
  /// options are missing from [AppConfig]. Does not fetch from the network.
  Future<void> setup(AppConfig config);

  /// Fetches and activates Remote Config from the network.
  ///
  /// Returns `false` if setup was skipped or fetch fails (fail-closed).
  Future<bool> fetchFlags();

  /// Reads an activated flag. Uses [RemoteFeatureFlag.defaultValue] when not
  /// ready (fail-closed for kill switches that default to `false`).
  bool isEnabled(RemoteFeatureFlag flag);

  /// Reads an activated string parameter.
  ///
  /// Returns `null` when setup was skipped, fetch never ran, or the value is
  /// empty so callers can fall back to a bundled asset.
  String? getString(String key);
}

/// Loads Privacy Policy markdown from Remote Config, with a bundled fallback.
abstract class PrivacyPolicyService {
  /// Bundled asset path used when Remote Config has no policy text.
  static const bundledAssetPath = 'assets/legal/privacy.md';

  /// Remote markdown when Firebase RC has a non-empty `privacy_policy`;
  /// otherwise the bundled asset (first launch / offline / prod until RC is on).
  Future<String> loadMarkdown();
}

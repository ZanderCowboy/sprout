/// Loads Terms of Service markdown from Remote Config, with a bundled fallback.
abstract class TermsOfServiceService {
  /// Bundled asset path used when Remote Config has no terms text.
  static const bundledAssetPath = 'assets/legal/terms.md';

  /// Remote markdown when Firebase RC has a non-empty `terms_of_service`;
  /// otherwise the bundled asset (first launch / offline / prod until RC is on).
  Future<String> loadMarkdown();
}

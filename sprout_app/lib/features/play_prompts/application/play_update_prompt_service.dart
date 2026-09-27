/// Decides when to show the Play Store update soft prompt (#104).
abstract class PlayUpdatePromptService {
  /// True when an update is available and the once-per-calendar-day cooldown
  /// allows showing the sheet (Android only).
  Future<bool> shouldShowPrompt();

  /// Records that the update sheet was shown today (cooldown).
  Future<void> markPromptShown();

  /// Opens the Play Store listing for this app's application id.
  Future<void> openStoreListing();
}

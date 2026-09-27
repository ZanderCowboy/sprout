import 'dart:async';

/// Soft Play In-App Review prompt after a success moment (#105).
abstract class PlayReviewPromptService {
  /// Fires when the host should present the review soft-prompt sheet.
  Stream<void> get reviewPromptRequests;

  /// Called after a successful deposit sheet submit. May enqueue a prompt when
  /// the user has logged their first deposit and has not declined / completed /
  /// already been offered the review soft prompt.
  Future<void> onDepositLoggedSuccess();

  /// Whether a review soft prompt may be shown now.
  Future<bool> shouldShowPrompt();

  /// Marks the soft prompt as offered (shown).
  Future<void> markPromptOffered();

  /// User chose Not now / dismissed — do not ask again.
  Future<void> markDeclined();

  /// User chose Rate on Play — request native review and mark completed.
  Future<void> requestReviewAndMarkCompleted();
}

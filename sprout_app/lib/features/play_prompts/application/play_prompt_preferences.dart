import 'package:shared_preferences/shared_preferences.dart';

/// Local prefs for Play update / review soft-prompt cadence.
class PlayPromptPreferences {
  PlayPromptPreferences(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const String updateLastShownDayKey = 'play_update_prompt_last_day';
  static const String reviewDeclinedKey = 'play_review_prompt_declined';
  static const String reviewCompletedKey = 'play_review_prompt_completed';
  static const String reviewOfferedKey = 'play_review_prompt_offered';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  /// Calendar day key in local time (`yyyy-MM-dd`).
  String calendarDayKey([DateTime? now]) {
    final n = now ?? _clock();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool get wasUpdateShownToday {
    final last = _prefs.getString(updateLastShownDayKey);
    return last != null && last == calendarDayKey();
  }

  Future<void> markUpdateShownToday() async {
    await _prefs.setString(updateLastShownDayKey, calendarDayKey());
  }

  bool get hasDeclinedReview => _prefs.getBool(reviewDeclinedKey) ?? false;

  bool get hasCompletedReview => _prefs.getBool(reviewCompletedKey) ?? false;

  bool get hasOfferedReview => _prefs.getBool(reviewOfferedKey) ?? false;

  Future<void> markReviewDeclined() async {
    await _prefs.setBool(reviewDeclinedKey, true);
    await _prefs.setBool(reviewOfferedKey, true);
  }

  Future<void> markReviewCompleted() async {
    await _prefs.setBool(reviewCompletedKey, true);
    await _prefs.setBool(reviewOfferedKey, true);
  }

  Future<void> markReviewOffered() async {
    await _prefs.setBool(reviewOfferedKey, true);
  }
}

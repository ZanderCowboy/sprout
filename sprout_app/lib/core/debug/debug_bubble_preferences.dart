import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the debug bubble visibility preference.
///
/// When the debug bubble is hidden, the floating bubble will not be shown,
/// but Debug Lens itself remains functional and can be accessed from Settings.
class DebugBubblePreferences extends ChangeNotifier {

  DebugBubblePreferences(this._prefs);
  static const String _keyBubbleVisible = 'debug_bubble_visible';

  final SharedPreferences _prefs;

  /// Returns whether the debug bubble should be visible.
  ///
  /// Defaults to `true` when no preference has been saved.
  bool get isBubbleVisible => _prefs.getBool(_keyBubbleVisible) ?? true;

  /// Sets whether the debug bubble should be visible.
  Future<void> setBubbleVisible(bool visible) async {
    if (visible == isBubbleVisible) return;
    await _prefs.setBool(_keyBubbleVisible, visible);
    notifyListeners();
  }
}

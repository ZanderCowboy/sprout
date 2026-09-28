/// Tracks the locked PROD debug-entry gesture: double-tap, then long-press.
///
/// Incomplete sequences and wrong order are no-ops. After a successful
/// double-tap the sequence stays armed for [armWindow]; a long-press outside
/// that window does nothing.
class DebugEntryGestureSequence {
  DebugEntryGestureSequence({
    this.armWindow = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// How long a double-tap keeps the sequence armed for a following long-press.
  final Duration armWindow;

  final DateTime Function() _clock;

  bool _armed = false;
  DateTime? _armedAt;

  /// True when a recent double-tap is waiting for a long-press.
  bool get isArmed {
    if (!_armed) return false;
    final armedAt = _armedAt;
    if (armedAt == null) return false;
    if (_clock().difference(armedAt) > armWindow) {
      reset();
      return false;
    }
    return true;
  }

  /// Arms the sequence after a double-tap on the version label.
  void onDoubleTap() {
    _armed = true;
    _armedAt = _clock();
  }

  /// Completes the sequence when long-pressed while armed.
  ///
  /// Returns `true` only for double-tap → long-press within [armWindow].
  bool onLongPress() {
    if (!isArmed) return false;
    reset();
    return true;
  }

  /// Clears any armed state.
  void reset() {
    _armed = false;
    _armedAt = null;
  }
}

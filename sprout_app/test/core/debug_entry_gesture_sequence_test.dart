import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/debug/debug_entry_gesture_sequence.dart';

void main() {
  test('double-tap then long-press within window succeeds', () {
    var now = DateTime(2026, 9, 28, 12);
    final sequence = DebugEntryGestureSequence(
      armWindow: const Duration(seconds: 2),
      clock: () => now,
    );

    sequence.onDoubleTap();
    expect(sequence.isArmed, isTrue);

    now = now.add(const Duration(milliseconds: 500));
    expect(sequence.onLongPress(), isTrue);
    expect(sequence.isArmed, isFalse);
  });

  test('long-press alone is a no-op', () {
    final sequence = DebugEntryGestureSequence();
    expect(sequence.onLongPress(), isFalse);
  });

  test('long-press after arm window expires is a no-op', () {
    var now = DateTime(2026, 9, 28, 12);
    final sequence = DebugEntryGestureSequence(
      armWindow: const Duration(seconds: 2),
      clock: () => now,
    );

    sequence.onDoubleTap();
    now = now.add(const Duration(seconds: 3));
    expect(sequence.onLongPress(), isFalse);
    expect(sequence.isArmed, isFalse);
  });

  test('second double-tap re-arms the window', () {
    var now = DateTime(2026, 9, 28, 12);
    final sequence = DebugEntryGestureSequence(
      armWindow: const Duration(seconds: 2),
      clock: () => now,
    );

    sequence.onDoubleTap();
    now = now.add(const Duration(seconds: 1));
    sequence.onDoubleTap();
    now = now.add(const Duration(seconds: 1, milliseconds: 500));
    expect(sequence.onLongPress(), isTrue);
  });
}

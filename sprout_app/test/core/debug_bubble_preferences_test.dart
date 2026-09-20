import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/core/debug/debug_bubble_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to visible when no preference is stored', () async {
    final prefs = DebugBubblePreferences(await SharedPreferences.getInstance());

    expect(prefs.isBubbleVisible, isTrue);
  });

  test('notifies listeners when visibility changes', () async {
    final prefs = DebugBubblePreferences(await SharedPreferences.getInstance());
    var notifications = 0;
    prefs.addListener(() => notifications++);

    await prefs.setBubbleVisible(false);

    expect(prefs.isBubbleVisible, isFalse);
    expect(notifications, 1);
  });

  test('does not notify when visibility is unchanged', () async {
    SharedPreferences.setMockInitialValues({'debug_bubble_visible': false});
    final prefs = DebugBubblePreferences(await SharedPreferences.getInstance());
    var notifications = 0;
    prefs.addListener(() => notifications++);

    await prefs.setBubbleVisible(false);

    expect(notifications, 0);
  });
}

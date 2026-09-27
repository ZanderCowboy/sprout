import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/features/play_prompts/application/play_prompt_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 28, 10);
  });

  Future<PlayPromptPreferences> prefs() async {
    return PlayPromptPreferences(
      await SharedPreferences.getInstance(),
      clock: () => now,
    );
  }

  test('update cooldown is once per calendar day', () async {
    final p = await prefs();
    expect(p.wasUpdateShownToday, isFalse);

    await p.markUpdateShownToday();
    expect(p.wasUpdateShownToday, isTrue);

    now = DateTime(2026, 9, 29, 1);
    expect(p.wasUpdateShownToday, isFalse);
  });

  test('review decline and completed flags stick', () async {
    final p = await prefs();
    expect(p.hasDeclinedReview, isFalse);
    expect(p.hasCompletedReview, isFalse);
    expect(p.hasOfferedReview, isFalse);

    await p.markReviewDeclined();
    expect(p.hasDeclinedReview, isTrue);
    expect(p.hasOfferedReview, isTrue);

    final p2 = await prefs();
    await p2.markReviewCompleted();
    expect(p2.hasCompletedReview, isTrue);
  });
}

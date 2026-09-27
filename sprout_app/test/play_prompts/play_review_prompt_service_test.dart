import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/features/play_prompts/application/play_in_app_review_gateway.dart';
import 'package:sprout/features/play_prompts/application/play_prompt_preferences.dart';
import 'package:sprout/features/play_prompts/application/play_review_prompt_service_impl.dart';

import '../mocks/mocks.dart';

class _FakeReviewGateway implements PlayInAppReviewGateway {
  bool available = true;
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayPromptPreferences preferences;
  late _FakeReviewGateway gateway;
  late FakeUserContext userContext;
  late PlayReviewPromptServiceImpl service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PlayPromptPreferences(await SharedPreferences.getInstance());
    gateway = _FakeReviewGateway();
    userContext = FakeUserContext()..firstDepositLoggedValue = true;
    service = PlayReviewPromptServiceImpl(
      preferences: preferences,
      reviewGateway: gateway,
      userContext: userContext,
    );
  });

  tearDown(() async {
    await service.dispose();
  });

  test(
    'shouldShowPrompt when first deposit logged and never offered',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(await service.shouldShowPrompt(), isTrue);
    },
  );

  test('shouldShowPrompt false without first deposit', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    userContext.firstDepositLoggedValue = false;
    expect(await service.shouldShowPrompt(), isFalse);
  });

  test('shouldShowPrompt false after decline', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await service.markDeclined();
    expect(await service.shouldShowPrompt(), isFalse);
  });

  test('onDepositLoggedSuccess enqueues review request', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final events = <void>[];
    final sub = service.reviewPromptRequests.listen(events.add);
    await service.onDepositLoggedSuccess();
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    await sub.cancel();
  });

  test('requestReviewAndMarkCompleted calls gateway and sticks', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await service.requestReviewAndMarkCompleted();
    expect(gateway.requestCount, 1);
    expect(await service.shouldShowPrompt(), isFalse);
    expect(preferences.hasCompletedReview, isTrue);
  });

  test('requestReview still completes when gateway unavailable', () async {
    gateway.available = false;
    await service.requestReviewAndMarkCompleted();
    expect(gateway.requestCount, 0);
    expect(preferences.hasCompletedReview, isTrue);
  });
}

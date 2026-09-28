import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/features/play_prompts/application/play_in_app_review_gateway.dart';
import 'package:sprout/features/play_prompts/application/play_prompt_preferences.dart';
import 'package:sprout/features/play_prompts/application/play_review_prompt_service_impl.dart';
import 'package:sprout/features/play_prompts/application/play_store_listing_launcher.dart';

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

class _FakeLauncher implements PlayStoreListingLauncher {
  String? openedId;

  @override
  Future<void> openListing(String androidApplicationId) async {
    openedId = androidApplicationId;
  }
}

AppConfig _config() => const AppConfig(
  environment: AppEnvironment.development,
  supabaseUrl: '',
  supabaseAnonKey: '',
  googleWebClientId: '',
  androidApplicationId: 'app.stackmint.sprout.dev',
  revenueCatAndroidApiKey: '',
  firebaseApiKey: '',
  firebaseAppId: '',
  firebaseMessagingSenderId: '',
  firebaseProjectId: '',
  firebaseStorageBucket: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayPromptPreferences preferences;
  late _FakeReviewGateway gateway;
  late _FakeLauncher launcher;
  late FakeUserContext userContext;
  late PlayReviewPromptServiceImpl service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PlayPromptPreferences(await SharedPreferences.getInstance());
    gateway = _FakeReviewGateway();
    launcher = _FakeLauncher();
    userContext = FakeUserContext()..firstDepositLoggedValue = true;
    service = PlayReviewPromptServiceImpl(
      preferences: preferences,
      reviewGateway: gateway,
      listingLauncher: launcher,
      userContext: userContext,
      appConfig: _config(),
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
    expect(launcher.openedId, isNull);
    expect(await service.shouldShowPrompt(), isFalse);
    expect(preferences.hasCompletedReview, isTrue);
  });

  test('requestReview opens listing when gateway unavailable', () async {
    gateway.available = false;
    await service.requestReview();
    expect(gateway.requestCount, 0);
    expect(launcher.openedId, 'app.stackmint.sprout.dev');
    expect(preferences.hasCompletedReview, isFalse);
  });

  test('forceStoreListing skips in-app review', () async {
    await service.requestReview(forceStoreListing: true);
    expect(gateway.requestCount, 0);
    expect(launcher.openedId, 'app.stackmint.sprout.dev');
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/features/play_prompts/application/play_prompt_preferences.dart';
import 'package:sprout/features/play_prompts/application/play_store_listing_launcher.dart';
import 'package:sprout/features/play_prompts/application/play_update_availability_checker.dart';
import 'package:sprout/features/play_prompts/application/play_update_prompt_service_impl.dart';

class _FakeAvailability implements PlayUpdateAvailabilityChecker {
  _FakeAvailability(this.available);
  bool available;
  int calls = 0;

  @override
  Future<bool> isUpdateAvailable() async {
    calls++;
    return available;
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

  late _FakeAvailability availability;
  late _FakeLauncher launcher;
  late PlayPromptPreferences preferences;
  late PlayUpdatePromptServiceImpl service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    availability = _FakeAvailability(true);
    launcher = _FakeLauncher();
    preferences = PlayPromptPreferences(
      await SharedPreferences.getInstance(),
      clock: () => DateTime(2026, 9, 28),
    );
    service = PlayUpdatePromptServiceImpl(
      availabilityChecker: availability,
      listingLauncher: launcher,
      preferences: preferences,
      appConfig: _config(),
    );
  });

  test(
    'shouldShowPrompt is true when update available and not shown today',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(await service.shouldShowPrompt(), isTrue);
      expect(availability.calls, 1);
    },
  );

  test('shouldShowPrompt is false after shown today', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await service.markPromptShown();
    expect(await service.shouldShowPrompt(), isFalse);
    expect(availability.calls, 0);
  });

  test('shouldShowPrompt is false when no update', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    availability.available = false;
    expect(await service.shouldShowPrompt(), isFalse);
  });

  test('openStoreListing uses application id', () async {
    await service.openStoreListing();
    expect(launcher.openedId, 'app.stackmint.sprout.dev');
  });
}

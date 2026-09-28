import 'package:flutter/foundation.dart';

import 'package:sprout/core/config/app_config.dart';

import 'play_prompt_preferences.dart';
import 'play_store_listing_launcher.dart';
import 'play_update_availability_checker.dart';
import 'play_update_prompt_service.dart';

class PlayUpdatePromptServiceImpl implements PlayUpdatePromptService {
  PlayUpdatePromptServiceImpl({
    required PlayUpdateAvailabilityChecker availabilityChecker,
    required PlayStoreListingLauncher listingLauncher,
    required PlayPromptPreferences preferences,
    required AppConfig appConfig,
  }) : _availabilityChecker = availabilityChecker,
       _listingLauncher = listingLauncher,
       _preferences = preferences,
       _appConfig = appConfig;

  final PlayUpdateAvailabilityChecker _availabilityChecker;
  final PlayStoreListingLauncher _listingLauncher;
  final PlayPromptPreferences _preferences;
  final AppConfig _appConfig;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> shouldShowPrompt() async {
    if (!_isAndroid) return false;
    if (_preferences.wasUpdateShownToday) return false;
    return _availabilityChecker.isUpdateAvailable();
  }

  @override
  Future<void> markPromptShown() => _preferences.markUpdateShownToday();

  @override
  Future<void> openStoreListing() {
    return _listingLauncher.openListing(_appConfig.androidApplicationId);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sprout/core/config/app_config.dart';
import 'package:sprout/core/user/user_context.dart';

import 'play_in_app_review_gateway.dart';
import 'play_prompt_preferences.dart';
import 'play_review_prompt_service.dart';
import 'play_store_listing_launcher.dart';

class PlayReviewPromptServiceImpl implements PlayReviewPromptService {
  PlayReviewPromptServiceImpl({
    required PlayPromptPreferences preferences,
    required PlayInAppReviewGateway reviewGateway,
    required PlayStoreListingLauncher listingLauncher,
    required UserContext userContext,
    required AppConfig appConfig,
  }) : _preferences = preferences,
       _reviewGateway = reviewGateway,
       _listingLauncher = listingLauncher,
       _userContext = userContext,
       _appConfig = appConfig;

  final PlayPromptPreferences _preferences;
  final PlayInAppReviewGateway _reviewGateway;
  final PlayStoreListingLauncher _listingLauncher;
  final UserContext _userContext;
  final AppConfig _appConfig;
  final StreamController<void> _requests = StreamController<void>.broadcast();

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<void> get reviewPromptRequests => _requests.stream;

  @override
  Future<void> onDepositLoggedSuccess() async {
    if (!await shouldShowPrompt()) return;
    if (!_requests.isClosed) {
      _requests.add(null);
    }
  }

  @override
  Future<bool> shouldShowPrompt() async {
    if (!_isAndroid) return false;
    if (_preferences.hasDeclinedReview) return false;
    if (_preferences.hasCompletedReview) return false;
    final userId = await _userContext.resolveUserId();
    return _userContext.getFirstDepositLogged(userId);
  }

  @override
  Future<void> markPromptOffered() => _preferences.markReviewOffered();

  @override
  Future<void> markDeclined() => _preferences.markReviewDeclined();

  @override
  Future<void> requestReview({bool forceStoreListing = false}) async {
    if (!forceStoreListing) {
      try {
        if (await _reviewGateway.isAvailable()) {
          await _reviewGateway.requestReview();
          return;
        }
      } on Object {
        // Play may throw; fall through to the listing.
      }
    }
    await _listingLauncher.openListing(_appConfig.androidApplicationId);
  }

  @override
  Future<void> requestReviewAndMarkCompleted() async {
    await requestReview();
    await _preferences.markReviewCompleted();
  }

  /// Test / shutdown helper.
  Future<void> dispose() async {
    await _requests.close();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sprout/core/user/user_context.dart';

import 'play_in_app_review_gateway.dart';
import 'play_prompt_preferences.dart';
import 'play_review_prompt_service.dart';

class PlayReviewPromptServiceImpl implements PlayReviewPromptService {
  PlayReviewPromptServiceImpl({
    required PlayPromptPreferences preferences,
    required PlayInAppReviewGateway reviewGateway,
    required UserContext userContext,
  }) : _preferences = preferences,
       _reviewGateway = reviewGateway,
       _userContext = userContext;

  final PlayPromptPreferences _preferences;
  final PlayInAppReviewGateway _reviewGateway;
  final UserContext _userContext;
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
  Future<void> requestReviewAndMarkCompleted() async {
    try {
      if (await _reviewGateway.isAvailable()) {
        await _reviewGateway.requestReview();
      }
    } on Object {
      // Play may no-op or throw; still mark completed so we do not nag.
    }
    await _preferences.markReviewCompleted();
  }

  /// Test / shutdown helper.
  Future<void> dispose() async {
    await _requests.close();
  }
}

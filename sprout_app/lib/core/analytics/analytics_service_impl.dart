import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'package:sprout/core/analytics/analytics_service.dart';

class AnalyticsServiceImpl implements AnalyticsService {
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> setup() async {
    try {
      _ready = true;
      if (kDebugMode) {
        debugPrint('AnalyticsService.setup: initialized.');
      }
    } on Object catch (e) {
      _ready = false;
      if (kDebugMode) {
        debugPrint('AnalyticsService.setup failed: $e');
      }
    }
  }

  @override
  Future<void> logScreenView(String screenName) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'screen_view',
        parameters: {'screen_name': screenName},
      );
      if (kDebugMode) {
        debugPrint('AnalyticsService: logged screen_view($screenName)');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logScreenView failed: $e');
      }
    }
  }

  @override
  Future<void> logSignInSuccess(SignInMethod method) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'sign_in_success',
        parameters: {'method': method.value},
      );
      if (kDebugMode) {
        debugPrint('AnalyticsService: logged sign_in_success(${method.value})');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logSignInSuccess failed: $e');
      }
    }
  }

  @override
  Future<void> logSignUpSuccess(SignInMethod method) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'sign_up_success',
        parameters: {'method': method.value},
      );
      if (kDebugMode) {
        debugPrint('AnalyticsService: logged sign_up_success(${method.value})');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logSignUpSuccess failed: $e');
      }
    }
  }

  @override
  Future<void> logSignOut() async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'sign_out');
      if (kDebugMode) {
        debugPrint('AnalyticsService: logged sign_out');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logSignOut failed: $e');
      }
    }
  }

  @override
  Future<void> logWizardCompleted() async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'wizard_completed');
      if (kDebugMode) {
        debugPrint('AnalyticsService: logged wizard_completed');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logWizardCompleted failed: $e');
      }
    }
  }

  @override
  Future<void> logFirstDepositLogged() async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'first_deposit_logged');
      if (kDebugMode) {
        debugPrint('AnalyticsService: logged first_deposit_logged');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logFirstDepositLogged failed: $e');
      }
    }
  }
}

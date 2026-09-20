import 'package:flutter/material.dart';

import 'package:sprout/core/analytics/analytics_events.dart';
import 'package:sprout/core/analytics/analytics_service.dart';
import 'package:sprout/core/router/app_route.dart';

/// Maps GoRouter paths to analytics screen names from [ScreenName].
String? _screenNameForRoute(String? routePath) {
  if (routePath == null) return null;

  // Strip leading slash and query params
  final path = routePath.split('?').first;
  final normalized = path.startsWith('/') ? path.substring(1) : path;

  // Map specific routes to screen names from catalog
  return switch (normalized) {
    '' || 'overview' => ScreenName.overview,
    'accounts' => ScreenName.accounts,
    'goals' => ScreenName.goals,
    'settings' => ScreenName.settings,
    'sign-in' => ScreenName.signIn,
    'create-account' => ScreenName.createAccount,
    'verify-otp' => ScreenName.verifyOtp,
    'wizard' => ScreenName.wizard,
    _ => _accountDetailScreenName(normalized),
  };
}

String? _accountDetailScreenName(String path) {
  // Match /accounts/:id
  if (path.startsWith('accounts/') && path.split('/').length == 2) {
    return ScreenName.account;
  }
  return null;
}

/// NavigatorObserver that logs screen_view events to Firebase Analytics.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  AnalyticsNavigatorObserver(this._analyticsService);

  final AnalyticsService _analyticsService;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreenView(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreenView(newRoute);
    }
  }

  void _logScreenView(Route<dynamic> route) {
    final routeName = route.settings.name;
    final screenName = _screenNameForRoute(routeName);
    if (screenName != null) {
      _analyticsService.logEvent(
        AnalyticsEvent.screenView,
        {AnalyticsParam.screenName: screenName},
      );
    }
  }
}

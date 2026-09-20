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
  Future<void> logEvent(String eventName, [Map<String, Object>? parameters]) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: parameters,
      );
      if (kDebugMode) {
        final paramsStr = parameters?.entries.map((e) => '${e.key}=${e.value}').join(', ') ?? '';
        final display = paramsStr.isEmpty ? eventName : '$eventName($paramsStr)';
        debugPrint('AnalyticsService: logged $display');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logEvent($eventName) failed: $e');
      }
    }
  }
}

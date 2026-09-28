import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'play_update_availability_checker.dart';

/// Play Core update-availability check only (no flexible/immediate start).
class PlayUpdateAvailabilityCheckerImpl
    implements PlayUpdateAvailabilityChecker {
  @override
  Future<bool> isUpdateAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable;
    } on Object {
      return false;
    }
  }
}

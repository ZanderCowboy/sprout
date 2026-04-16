import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/sync/export.dart';

class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit() : super(true) {
    _subscription = Connectivity().onConnectivityChanged.listen(_onResults);
    Connectivity().checkConnectivity().then(_onResults);
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _onResults(List<ConnectivityResult> results) {
    final online = _isOnline(results);
    emit(online);
    if (online) {
      unawaited(sl<SyncService>().flushPending());
    }
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}

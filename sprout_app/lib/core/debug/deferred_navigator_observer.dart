import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Forwards [NavigatorObserver] callbacks after the current frame when they
/// fire during build or layout.
///
/// Debug Lens records navigation on a ChangeNotifier synchronously. GoRouter
/// restores the root [Navigator] while HeroControllerScope is still building,
/// so that notify would mark Provider dirty mid-build.
class DeferredNavigatorObserver extends NavigatorObserver {
  DeferredNavigatorObserver(this._inner);

  final NavigatorObserver _inner;

  void _run(void Function() body) {
    switch (SchedulerBinding.instance.schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
        body();
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        SchedulerBinding.instance.addPostFrameCallback((_) => body());
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _run(() => _inner.didPush(route, previousRoute));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _run(() => _inner.didPop(route, previousRoute));
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _run(() => _inner.didRemove(route, previousRoute));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _run(() => _inner.didReplace(newRoute: newRoute, oldRoute: oldRoute));
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _run(() => _inner.didChangeTop(topRoute, previousTopRoute));
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _run(() => _inner.didStartUserGesture(route, previousRoute));
  }

  @override
  void didStopUserGesture() {
    _run(_inner.didStopUserGesture);
  }
}

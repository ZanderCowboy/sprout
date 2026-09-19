import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/debug/deferred_navigator_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('forwards didPush immediately when the scheduler is idle', () {
    expect(SchedulerBinding.instance.schedulerPhase, SchedulerPhase.idle);

    final inner = _RecordingObserver();
    final deferred = DeferredNavigatorObserver(inner);
    final route = _FakeRoute();

    deferred.didPush(route, null);

    expect(inner.pushes, 1);
    expect(inner.lastRoute, same(route));
  });

  test('defers didPush until after the frame during persistent callbacks', () {
    final binding = TestWidgetsFlutterBinding.instance;
    final inner = _RecordingObserver();
    final deferred = DeferredNavigatorObserver(inner);
    final route = _FakeRoute();
    var pushesDuringFrame = -1;

    binding.addPersistentFrameCallback((_) {
      deferred.didPush(route, null);
      pushesDuringFrame = inner.pushes;
    });

    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();

    expect(pushesDuringFrame, 0);
    expect(inner.pushes, 1);
    expect(inner.lastRoute, same(route));
  });
}

class _RecordingObserver extends NavigatorObserver {
  int pushes = 0;
  Route<dynamic>? lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    lastRoute = route;
  }
}

class _FakeRoute extends Route<void> {
  _FakeRoute() : super(settings: const RouteSettings(name: '/test'));
}

// DebugLens 0.0.2 notifies Provider during Navigator restore (build/layout).
// We re-host wrap/show onto a deferred observer so the panel can still push,
// and onto SproutDebugPanelRoute so the canvas follows the app theme.
// ignore_for_file: implementation_imports

import 'package:debug_lens/debug_lens.dart';
import 'package:debug_lens/src/core/debug_lens_config.dart';
import 'package:debug_lens/src/core/debug_role.dart';
import 'package:debug_lens/src/core/debug_store.dart';
import 'package:debug_lens/src/features/settings/data/bubble_store.dart';
import 'package:debug_lens/src/features/settings/data/debug_limits_store.dart';
import 'package:debug_lens/src/shell/debug_bubble.dart';
import 'package:debug_lens/src/shell/debug_lens_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sprout/core/debug/debug_bubble_preferences.dart';
import 'package:sprout/core/debug/deferred_navigator_observer.dart';
import 'package:sprout/core/debug/sprout_debug_panel.dart';

/// Sprout's Debug Lens entry points. Use these instead of [DebugLens.wrap],
/// [DebugLens.show], and [DebugLens.navigatorObserver].
class SproutDebugLens {
  SproutDebugLens._();

  static DebugBubblePreferences? _bubblePrefs;

  /// Root observer. Defers store notifications until after the current frame.
  static final NavigatorObserver navigatorObserver = DeferredNavigatorObserver(
    DebugLensNavigatorObserver(),
  );

  /// Provides Debug Lens state and the draggable bubble.
  static Widget wrap(Widget child) {
    if (!DebugLensConfig.enabled) return child;

    // ignore: invalid_use_of_internal_member
    DebugLensLogger().restoreCaptureSettings();
    DebugLimits.instance.restore();
    BubbleStore.instance.restore();
    return FutureBuilder<DebugBubblePreferences>(
      future: _getBubblePreferences(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DebugLensController()),
              ChangeNotifierProvider(create: (_) => DebugRoleController()),
              ChangeNotifierProvider<DebugStore>.value(
                value: DebugStore.instance,
              ),
              ChangeNotifierProvider<DebugLensLogger>.value(
                value: DebugLensLogger(),
              ),
            ],
            child: child,
          );
        }
        _bubblePrefs = snapshot.data;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DebugLensController()),
            ChangeNotifierProvider(create: (_) => DebugRoleController()),
            ChangeNotifierProvider<DebugStore>.value(
              value: DebugStore.instance,
            ),
            ChangeNotifierProvider<DebugLensLogger>.value(
              value: DebugLensLogger(),
            ),
            ChangeNotifierProvider<DebugBubblePreferences>.value(
              value: snapshot.data!,
            ),
          ],
          child: _SproutDebugLensHost(child: child),
        );
      },
    );
  }

  static Future<DebugBubblePreferences> _getBubblePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return DebugBubblePreferences(prefs);
  }

  /// Returns whether the debug bubble should be shown.
  static bool get isBubbleVisible => _bubblePrefs?.isBubbleVisible ?? true;

  /// Sets whether the debug bubble should be visible.
  static Future<void> setBubbleVisible(bool visible) async {
    if (_bubblePrefs != null) {
      await _bubblePrefs!.setBubbleVisible(visible);
    }
  }

  /// Opens the panel on the host navigator. [context] must be below [wrap].
  static void show(BuildContext context) {
    final controller = context.read<DebugLensController>();
    if (controller.isOpen) return;
    final navigator = navigatorObserver.navigator;
    if (navigator == null) return;
    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: DebugLens.panelRouteName),
      opaque: false,
      pageBuilder: (_, _, _) =>
          SproutDebugPanelRoute(navigatorKey: controller.navigatorKey),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    controller.attachRoute(route);
    navigator.push(route).whenComplete(controller.detachRoute);
  }
}

class _SproutDebugLensHost extends StatelessWidget {
  const _SproutDebugLensHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isOpen = context.watch<DebugLensController>().isOpen;
    final bubbleVisible = context
        .watch<DebugBubblePreferences>()
        .isBubbleVisible;
    return Stack(
      children: [
        child,
        if (!isOpen && bubbleVisible)
          Positioned.fill(
            child: DebugBubble(onTap: () => SproutDebugLens.show(context)),
          ),
      ],
    );
  }
}

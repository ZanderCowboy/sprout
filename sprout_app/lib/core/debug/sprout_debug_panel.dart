// DebugLens 0.0.2 paints a navy canvas and a different seed fill per tool.
// Sprout re-hosts the panel so every page uses the same opaque app surface.
// ignore_for_file: implementation_imports

import 'package:debug_lens/src/shared/theme/debug_theme.dart';
import 'package:debug_lens/src/shell/debug_router.dart';
import 'package:debug_lens/src/shell/debug_routes.dart';
import 'package:flutter/material.dart';

/// Host-navigator route for the Debug Lens panel, themed to Sprout.
class SproutDebugPanelRoute extends StatefulWidget {
  const SproutDebugPanelRoute({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<SproutDebugPanelRoute> createState() => _SproutDebugPanelRouteState();
}

class _SproutDebugPanelRouteState extends State<SproutDebugPanelRoute> {
  bool _nestedCanPop = false;

  void _refreshCanPop() {
    final canPop = widget.navigatorKey.currentState?.canPop() ?? false;
    if (canPop != _nestedCanPop && mounted) {
      setState(() => _nestedCanPop = canPop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_nestedCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.navigatorKey.currentState?.maybePop();
      },
      child: _SproutDebugPanel(
        navigatorKey: widget.navigatorKey,
        onNestedChanged: _refreshCanPop,
        surface: theme.scaffoldBackgroundColor,
        accent: theme.colorScheme.primary,
      ),
    );
  }
}

class _SproutDebugPanel extends StatelessWidget {
  const _SproutDebugPanel({
    required this.navigatorKey,
    required this.surface,
    required this.accent,
    this.onNestedChanged,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback? onNestedChanged;
  final Color surface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _panelTheme(surface: surface, accent: accent),
      child: Stack(
        children: [
          Positioned.fill(
            child: _SproutDebugLensBackground(surface: surface, accent: accent),
          ),
          HeroControllerScope.none(
            child: Navigator(
              key: navigatorKey,
              initialRoute: DebugRoutes.dashboard,
              onGenerateRoute: (settings) =>
                  _onGenerateRoute(settings, surface: surface, accent: accent),
              observers: [_PanelNavObserver(onNestedChanged)],
            ),
          ),
        ],
      ),
    );
  }

  /// Debug Lens seeds each tool's [ColorScheme] (Network is blue). We keep the
  /// page opaque so the previous screen cannot show through, but pin the fill
  /// to the host surface so the canvas does not change color on push/pop.
  static Route<dynamic> _onGenerateRoute(
    RouteSettings settings, {
    required Color surface,
    required Color accent,
  }) {
    final generated = DebugRouter.onGenerateRoute(settings);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        final built = generated is MaterialPageRoute
            ? generated.builder(context)
            : const SizedBox.shrink();
        return ColoredBox(
          color: surface,
          child: Theme(
            data: _panelTheme(surface: surface, accent: accent),
            child: built is Theme ? built.child : built,
          ),
        );
      },
    );
  }

  static ThemeData _panelTheme({
    required Color surface,
    required Color accent,
  }) {
    final base = DebugTheme.build(accent);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        surfaceDim: surface,
        surfaceBright: surface,
        surfaceContainerLowest: surface,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: surface,
        surfaceContainerHighest: surface,
      ),
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
    );
  }
}

/// Same gradient structure as Debug Lens's glass canvas, using the host theme.
class _SproutDebugLensBackground extends StatelessWidget {
  const _SproutDebugLensBackground({
    required this.surface,
    required this.accent,
  });

  final Color surface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              surface,
              Color.lerp(surface, accent, 0.10)!,
              Color.lerp(surface, accent, 0.04)!,
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelNavObserver extends NavigatorObserver {
  _PanelNavObserver(this.onChanged);

  final VoidCallback? onChanged;

  void _notify() {
    final cb = onChanged;
    if (cb == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => cb());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/play_prompts/application/play_review_prompt_service.dart';
import 'package:sprout/features/play_prompts/application/play_update_prompt_service.dart';
import 'package:sprout/features/play_prompts/presentation/play_review_prompt_sheet.dart';
import 'package:sprout/features/play_prompts/presentation/play_update_prompt_sheet.dart';

/// Listens for cold start / resume update checks and review prompt requests.
class PlayPromptsHost extends StatefulWidget {
  const PlayPromptsHost({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<PlayPromptsHost> createState() => _PlayPromptsHostState();
}

class _PlayPromptsHostState extends State<PlayPromptsHost>
    with WidgetsBindingObserver {
  static const int _maxUpdateReadyAttempts = 6;
  static const Duration _updateReadyRetryDelay = Duration(milliseconds: 750);

  StreamSubscription<void>? _reviewSub;
  bool _sheetVisible = false;
  int _updateReadyAttempts = 0;
  Timer? _updateReadyRetry;

  BuildContext? get _navContext => widget.navigatorKey.currentContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reviewSub = sl<PlayReviewPromptService>().reviewPromptRequests.listen((_) {
      unawaited(_showReviewIfEligible());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showUpdateIfEligible());
    });
  }

  @override
  void dispose() {
    _updateReadyRetry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_reviewSub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateReadyAttempts = 0;
      unawaited(_showUpdateIfEligible());
    }
  }

  /// True when the auth gate is still on `/loading`. Showing a sheet there is
  /// racy: go_router redirect tears it down and used to leave the once-per-day
  /// cooldown set without the user ever seeing the prompt (#113).
  bool _isOnLoadingRoute(BuildContext context) {
    final location = GoRouter.maybeOf(context)?.state.matchedLocation;
    return location == AppRoute.loading.path;
  }

  void _scheduleUpdateReadyRetry() {
    if (_updateReadyAttempts >= _maxUpdateReadyAttempts) return;
    if (_updateReadyRetry?.isActive ?? false) return;
    _updateReadyAttempts++;
    _updateReadyRetry = Timer(_updateReadyRetryDelay, () {
      if (!mounted) return;
      unawaited(_showUpdateIfEligible());
    });
  }

  Future<void> _showUpdateIfEligible() async {
    if (_sheetVisible) return;
    final navContext = _navContext;
    if (navContext == null || !navContext.mounted) {
      _scheduleUpdateReadyRetry();
      return;
    }
    if (_isOnLoadingRoute(navContext)) {
      _scheduleUpdateReadyRetry();
      return;
    }

    final service = sl<PlayUpdatePromptService>();
    final shouldShow = await service.shouldShowPrompt();
    if (!shouldShow || _sheetVisible) return;
    final ctx = _navContext;
    if (ctx == null || !ctx.mounted) {
      _scheduleUpdateReadyRetry();
      return;
    }
    if (_isOnLoadingRoute(ctx)) {
      _scheduleUpdateReadyRetry();
      return;
    }

    _sheetVisible = true;
    _updateReadyAttempts = 0;
    try {
      final latest = _navContext;
      if (latest == null || !latest.mounted || _isOnLoadingRoute(latest)) {
        // Do not mark cooldown — sheet never presented.
        _scheduleUpdateReadyRetry();
        return;
      }
      final result = await showPlayUpdatePromptSheet(latest);
      // Mark only after the sheet was presented and closed (Update / Later /
      // dismiss). Prevents accidental same-day suppress when presentation
      // fails or auth redirect disposes the route under us (#113).
      await service.markPromptShown();
      if (result == PlayUpdatePromptResult.update) {
        await service.openStoreListing();
      }
    } finally {
      _sheetVisible = false;
    }
  }

  Future<void> _showReviewIfEligible() async {
    if (_sheetVisible) return;
    final navContext = _navContext;
    if (navContext == null || !navContext.mounted) return;

    final service = sl<PlayReviewPromptService>();
    final shouldShow = await service.shouldShowPrompt();
    if (!shouldShow || _sheetVisible) return;
    final ctx = _navContext;
    if (ctx == null || !ctx.mounted) return;

    _sheetVisible = true;
    try {
      final latest = _navContext;
      if (latest == null || !latest.mounted) return;
      final result = await showPlayReviewPromptSheet(latest);
      switch (result) {
        case PlayReviewPromptResult.rate:
          await service.requestReviewAndMarkCompleted();
        case PlayReviewPromptResult.notNow:
        case PlayReviewPromptResult.dismissed:
          await service.markDeclined();
      }
    } finally {
      _sheetVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

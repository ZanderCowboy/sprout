import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sprout/core/di/service_locator.dart';
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
  StreamSubscription<void>? _reviewSub;
  bool _sheetVisible = false;

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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_reviewSub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_showUpdateIfEligible());
    }
  }

  Future<void> _showUpdateIfEligible() async {
    if (_sheetVisible) return;
    final navContext = _navContext;
    if (navContext == null || !navContext.mounted) return;

    final service = sl<PlayUpdatePromptService>();
    final shouldShow = await service.shouldShowPrompt();
    if (!shouldShow || _sheetVisible) return;
    final ctx = _navContext;
    if (ctx == null || !ctx.mounted) return;

    _sheetVisible = true;
    try {
      await service.markPromptShown();
      final latest = _navContext;
      if (latest == null || !latest.mounted) return;
      final result = await showPlayUpdatePromptSheet(latest);
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

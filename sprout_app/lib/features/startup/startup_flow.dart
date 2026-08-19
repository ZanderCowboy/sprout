import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sprout/app.dart';
import 'package:sprout/core/config/app_environment.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/flags/remote_feature_flag.dart';
import 'package:sprout/core/startup/startup_initializer.dart';
import 'package:sprout/features/startup/startup_error_page.dart';
import 'package:sprout/features/startup/startup_page.dart';
import 'package:sprout/features/startup/startup_splash_page.dart';
import 'package:sprout/ui/export.dart';

class SproutBootstrapApp extends StatefulWidget {
  const SproutBootstrapApp({
    super.key,
    required this.configAssetPath,
    required this.environment,
  });

  final String configAssetPath;
  final AppEnvironment environment;

  @override
  State<SproutBootstrapApp> createState() => _SproutBootstrapAppState();
}

class _SproutBootstrapAppState extends State<SproutBootstrapApp>
    implements StartupProgressReporter {
  final Map<StartupStep, StartupStepStatus> _steps = {
    for (final s in StartupStep.values) s: StartupStepStatus.pending,
  };
  final Map<StartupStep, String?> _details = {
    for (final s in StartupStep.values) s: null,
  };

  bool _ready = false;
  Object? _error;
  StackTrace? _stackTrace;
  bool _running = false;
  bool _showStartupChecks = RemoteFeatureFlag.showStartupChecks.defaultValue;

  @override
  void initState() {
    super.initState();
    _runInit();
  }

  Future<void> _runInit() async {
    if (_running) return;
    setState(() {
      _running = true;
      _ready = false;
      _error = null;
      _stackTrace = null;
      _showStartupChecks = RemoteFeatureFlag.showStartupChecks.defaultValue;
      for (final s in StartupStep.values) {
        _steps[s] = StartupStepStatus.pending;
        _details[s] = null;
      }
    });

    try {
      await initializeApp(
        configAssetPath: widget.configAssetPath,
        environment: widget.environment,
        reporter: this,
        allowSupabase: true,
        strictConfig: true,
      );
      if (!mounted) return;
      setState(() {
        _ready = true;
      });
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('Startup init failed: $e');
        debugPrint('$st');
      }
      if (!mounted) return;
      setState(() {
        _error = e;
        _stackTrace = st;
      });
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _running = false;
      });
    }
  }

  @override
  void update(StartupStep step, StartupStepStatus status, {String? detail}) {
    if (!mounted) return;
    setState(() {
      _steps[step] = status;
      if (detail != null) {
        _details[step] = detail;
      }
    });
  }

  @override
  void onShowStartupChecks(bool enabled) {
    if (!mounted) return;
    setState(() {
      _showStartupChecks = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const SproutApp();
    }

    final error = _error;
    final stack = _stackTrace;
    final isError = error != null;

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(),
      builder: (context, child) => EnvironmentBanner(
        environment: widget.environment,
        child: child ?? const SizedBox.shrink(),
      ),
      home: isError
          ? StartupErrorPage(
              configAssetPath: widget.configAssetPath,
              error: error,
              stackTrace: stack,
              steps: _steps,
              details: _details,
              onRetry: _running ? null : _runInit,
            )
          : _showStartupChecks
          ? StartupPage(
              configAssetPath: widget.configAssetPath,
              steps: _steps,
              details: _details,
            )
          : const StartupSplashPage(),
    );
  }
}

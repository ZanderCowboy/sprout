import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/startup/startup_initializer.dart';

class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({
    super.key,
    required this.configAssetPath,
    required this.error,
    required this.stackTrace,
    required this.steps,
    required this.details,
    required this.onRetry,
    required this.onContinueLocalOnly,
  });

  final String configAssetPath;
  final Object error;
  final StackTrace? stackTrace;
  final Map<StartupStep, StartupStepStatus> steps;
  final Map<StartupStep, String?> details;
  final VoidCallback? onRetry;
  final VoidCallback? onContinueLocalOnly;

  @override
  Widget build(BuildContext context) {
    final canRetry = onRetry != null;
    final canContinue = onContinueLocalOnly != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                AppStrings.appTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                "We couldn’t finish starting Sprout.",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Config: $configAssetPath',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onRetry,
                      child: Text(canRetry ? 'Retry' : 'Retrying…'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onContinueLocalOnly,
                      child: Text(
                        canContinue ? 'Continue local-only' : 'Continuing…',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _Section(
                      title: 'Details',
                      child: Text(
                        '$error',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ),
                    if (kDebugMode && stackTrace != null)
                      _Section(
                        title: 'Stack trace (debug only)',
                        child: Text(
                          '$stackTrace',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white60),
                        ),
                      ),
                    _Section(
                      title: 'Startup steps',
                      child: Column(
                        children: [
                          for (final step in StartupStep.values)
                            _StepRow(
                              step: step,
                              status: steps[step] ?? StartupStepStatus.pending,
                              detail: details[step],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.status,
    required this.detail,
  });

  final StartupStep step;
  final StartupStepStatus status;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      StartupStepStatus.pending =>
        const Icon(Icons.circle_outlined, size: 18),
      StartupStepStatus.running => const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      StartupStepStatus.done =>
        const Icon(Icons.check_circle, size: 18, color: Colors.greenAccent),
      StartupStepStatus.skipped =>
        const Icon(Icons.remove_circle_outline, size: 18, color: Colors.white54),
      StartupStepStatus.failed =>
        const Icon(Icons.error, size: 18, color: Colors.redAccent),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelFor(step)),
                if (detail != null && detail!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _labelFor(StartupStep step) {
  return switch (step) {
    StartupStep.hiveInit => 'Initializing local storage',
    StartupStep.openBoxes => 'Opening boxes',
    StartupStep.loadConfig => 'Loading config',
    StartupStep.initSupabase => 'Connecting to Supabase',
    StartupStep.configureDI => 'Configuring services',
    StartupStep.resolveUser => 'Resolving user',
    StartupStep.migrateUserIds => 'Migrating user data',
    StartupStep.flushPending => 'Flushing pending sync',
    StartupStep.pullRemote => 'Pulling remote data',
  };
}


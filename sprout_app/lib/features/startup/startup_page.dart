import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/startup/startup_initializer.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({
    super.key,
    required this.configAssetPath,
    required this.steps,
    required this.details,
  });

  final String configAssetPath;
  final Map<StartupStep, StartupStepStatus> steps;
  final Map<StartupStep, String?> details;

  @override
  Widget build(BuildContext context) {
    final activeStep = StartupStep.values.firstWhere(
      (s) => steps[s] == StartupStepStatus.running,
      orElse: () => StartupStep.values.firstWhere(
        (s) => steps[s] == StartupStepStatus.pending,
        orElse: () => StartupStep.values.last,
      ),
    );

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
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _labelFor(activeStep),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Config: $configAssetPath',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (final step in StartupStep.values)
                      _StepTile(
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
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
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
      StartupStepStatus.pending => const Icon(Icons.circle_outlined, size: 18),
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

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icon,
      title: Text(_labelFor(step)),
      subtitle: (detail == null || detail!.trim().isEmpty)
          ? null
          : Text(
              detail!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
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


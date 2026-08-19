import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/startup/startup_initializer.dart';
import 'package:sprout/features/startup/startup_error_page.dart';

void main() {
  testWidgets('startup error shows Retry only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StartupErrorPage(
          configAssetPath: 'assets/config/development.json',
          error: 'boom',
          stackTrace: null,
          steps: {
            for (final step in StartupStep.values)
              step: StartupStepStatus.pending,
          },
          details: {for (final step in StartupStep.values) step: null},
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Continue local-only'), findsNothing);
  });
}

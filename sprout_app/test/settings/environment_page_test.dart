import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/features/settings/presentation/environment_page.dart';

void main() {
  testWidgets('Environment page shows relocated soft-prompt tools', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        themeMode: ThemeMode.dark,
        home: const EnvironmentPage(),
      ),
    );

    expect(find.text(AppStrings.environmentPageTitle), findsOneWidget);
    expect(find.text(AppStrings.debugShowUpdatePrompt), findsOneWidget);
    expect(find.text(AppStrings.debugShowReviewPrompt), findsOneWidget);
  });
}

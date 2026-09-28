import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/features/settings/presentation/widgets/settings_footer.dart';

void main() {
  Widget harness({
    required bool busy,
    VoidCallback? onSignOut,
    VoidCallback? onVersionEnvironmentEntry,
  }) {
    return MaterialApp(
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SettingsFooter(
          versionLabel: '1.6.0 (26)',
          busy: busy,
          onSignOut: onSignOut ?? () {},
          onPrivacy: () {},
          onTerms: () {},
          onVersionEnvironmentEntry: onVersionEnvironmentEntry,
        ),
      ),
    );
  }

  testWidgets('idle Sign Out shows logout icon and no progress', (
    tester,
  ) async {
    await tester.pumpWidget(harness(busy: false));

    expect(find.text(AppStrings.signOut), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('busy Sign Out shows progress and disables press', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      harness(
        busy: true,
        onSignOut: () => tapped = true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsNothing);

    await tester.tap(find.text(AppStrings.signOut), warnIfMissed: false);
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('version label has no affordance chrome', (tester) async {
    await tester.pumpWidget(harness(busy: false));

    expect(find.text('1.6.0 (26)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.text('1.6.0 (26)'),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('long-press alone opens Environment entry', (tester) async {
    var entries = 0;
    await tester.pumpWidget(
      harness(
        busy: false,
        onVersionEnvironmentEntry: () => entries++,
      ),
    );

    await tester.longPress(find.text('1.6.0 (26)'));
    await tester.pump();
    expect(entries, 1);
  });

  testWidgets('double-tap alone opens Environment entry', (tester) async {
    var entries = 0;
    await tester.pumpWidget(
      harness(
        busy: false,
        onVersionEnvironmentEntry: () => entries++,
      ),
    );

    final version = find.text('1.6.0 (26)');
    await tester.tap(version);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(version);
    await tester.pumpAndSettle();
    expect(entries, 1);
  });
}

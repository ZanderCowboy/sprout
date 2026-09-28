import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/features/auth/presentation/widgets/delete_account_sheet.dart';

void main() {
  Widget harness({required Widget home}) {
    return MaterialApp(
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: home,
    );
  }

  testWidgets('Delete stays disabled until Confirm is typed exactly', (
    tester,
  ) async {
    late bool? result;
    await tester.pumpWidget(
      harness(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDeleteAccountSheet(context);
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.deleteAccountConfirmHelper), findsOneWidget);

    final deleteFinder = find.text(AppStrings.deleteAccount);
    final deleteButton = tester.widget<FilledButton>(
      find.ancestor(of: deleteFinder, matching: find.byType(FilledButton)),
    );
    expect(deleteButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'confirm');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: deleteFinder,
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byType(TextField),
      AppStrings.deleteAccountConfirmToken,
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: deleteFinder,
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(deleteFinder);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('Cancel returns false without deleting', (tester) async {
    late bool? result;
    await tester.pumpWidget(
      harness(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDeleteAccountSheet(context);
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}

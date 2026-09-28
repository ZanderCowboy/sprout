import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/features/play_prompts/presentation/play_review_prompt_sheet.dart';
import 'package:sprout/features/play_prompts/presentation/play_update_prompt_sheet.dart';

void main() {
  Widget harness({required Widget home}) {
    return MaterialApp(
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      home: home,
    );
  }

  testWidgets('update sheet Update CTA returns update', (tester) async {
    late PlayUpdatePromptResult result;
    await tester.pumpWidget(
      harness(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showPlayUpdatePromptSheet(context);
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
    expect(find.text(AppStrings.playUpdateTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.playUpdateCta));
    await tester.pumpAndSettle();
    expect(result, PlayUpdatePromptResult.update);
  });

  testWidgets('update sheet Later is quiet text button without icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  await showPlayUpdatePromptSheet(context);
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
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text(AppStrings.playUpdateLater), findsOneWidget);
  });

  testWidgets('update sheet Later dismisses', (tester) async {
    late PlayUpdatePromptResult result;
    await tester.pumpWidget(
      harness(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showPlayUpdatePromptSheet(context);
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
    await tester.tap(find.text(AppStrings.playUpdateLater));
    await tester.pumpAndSettle();
    expect(result, PlayUpdatePromptResult.later);
  });

  testWidgets('review sheet Rate returns rate', (tester) async {
    late PlayReviewPromptResult result;
    await tester.pumpWidget(
      harness(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showPlayReviewPromptSheet(context);
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
    expect(find.text(AppStrings.playReviewTitle), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    await tester.tap(find.text(AppStrings.playReviewRateCta));
    await tester.pumpAndSettle();
    expect(result, PlayReviewPromptResult.rate);
  });

  testWidgets('review sheet Not now returns notNow', (tester) async {
    late PlayReviewPromptResult result;
    await tester.pumpWidget(
      harness(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showPlayReviewPromptSheet(context);
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
    await tester.tap(find.text(AppStrings.playReviewNotNow));
    await tester.pumpAndSettle();
    expect(result, PlayReviewPromptResult.notNow);
  });
}

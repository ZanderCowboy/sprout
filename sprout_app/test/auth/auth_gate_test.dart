import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/core/storage/hive_adapters.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/auth/presentation/intro_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntroPage', () {
    testWidgets('last CTA completes intro', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: IntroPage(onCompleted: () => completed = true),
        ),
      );

      expect(find.text(AppStrings.introSlide1Title), findsOneWidget);

      await tester.tap(find.text(AppStrings.next));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(AppStrings.introSlide2Title), findsOneWidget);

      await tester.tap(find.text(AppStrings.next));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(AppStrings.introSlide3Title), findsOneWidget);

      await tester.tap(find.text(AppStrings.createAccount));
      await tester.pump();
      expect(completed, isTrue);
    });

    testWidgets('sign-in link also completes intro', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: GoRouter(
            initialLocation: AppRoute.intro.path,
            routes: [
              GoRoute(
                path: AppRoute.intro.path,
                builder: (context, _) =>
                    IntroPage(onCompleted: () => completed = true),
              ),
              GoRoute(
                path: AppRoute.signIn.path,
                builder: (context, _) => const Scaffold(
                  body: Center(child: Text('Sign In')),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text(AppStrings.introSlide1Title), findsOneWidget);

      await tester.tap(find.text(AppStrings.next));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(AppStrings.introSlide2Title), findsOneWidget);

      await tester.tap(find.text(AppStrings.next));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(AppStrings.introSlide3Title), findsOneWidget);

      await tester.tap(find.text(AppStrings.iAlreadyHaveAnAccount));
      await tester.pump();
      expect(completed, isTrue);
    });
  });

  group('UserContext intro', () {
    late Directory tempDir;
    late Box<dynamic> settingsBox;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('sprout_intro_flag_');
      Hive.init(tempDir.path);
      registerHiveAdapters();
    });

    setUp(() async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      settingsBox = await Hive.openBox<dynamic>('settings_$stamp');
    });

    tearDown(() async {
      await settingsBox.deleteFromDisk();
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('intro_completed persists on UserContext', () async {
      final userContext = UserContext(settingsBox);
      expect(userContext.introCompleted, isFalse);
      final pending = userContext.markIntroCompleted();
      expect(userContext.introCompleted, isTrue);
      await pending;
      expect(userContext.introCompleted, isTrue);
    });

    test('pending welcome toast is one-shot', () async {
      final userContext = UserContext(settingsBox);
      await userContext.setPendingWelcomeToast('u1', 'hello');
      expect(await userContext.takePendingWelcomeToast('u1'), 'hello');
      expect(await userContext.takePendingWelcomeToast('u1'), isNull);
    });
  });
}

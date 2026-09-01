import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/theme/app_radii.dart';
import 'package:sprout/core/theme/app_theme.dart';

void main() {
  test('buildAppTheme is dark with Sprout palette', () {
    final theme = buildAppTheme();

    expect(theme.brightness, Brightness.dark);
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.seed);
    expect(theme.colorScheme.surface, AppColors.surfaceDeep);
    expect(theme.colorScheme.surfaceContainerHighest, AppColors.surfaceMuted);
    expect(theme.scaffoldBackgroundColor, AppColors.surfaceDeep);
  });

  test('buildAppTheme sets typography weights', () {
    final textTheme = buildAppTheme().textTheme;

    expect(textTheme.titleLarge?.fontWeight, FontWeight.w700);
    expect(textTheme.titleMedium?.fontWeight, FontWeight.w700);
    expect(textTheme.titleSmall?.fontWeight, FontWeight.w800);
    expect(textTheme.labelLarge?.fontWeight, FontWeight.w800);
    expect(textTheme.headlineSmall?.fontWeight, FontWeight.w800);
  });

  test('buildAppTheme sets component themes', () {
    final theme = buildAppTheme();

    expect(theme.filledButtonTheme, isNotNull);
    expect(theme.outlinedButtonTheme, isNotNull);
    expect(theme.textButtonTheme, isNotNull);
    expect(theme.dialogTheme, isNotNull);
    expect(theme.bottomSheetTheme, isNotNull);
    expect(theme.snackBarTheme, isNotNull);
    expect(theme.inputDecorationTheme, isNotNull);
    expect(theme.tabBarTheme, isNotNull);
    expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(
      (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(AppRadii.card),
    );
    expect(theme.inputDecorationTheme.fillColor, AppColors.surfaceMuted);
    expect(
      theme.floatingActionButtonTheme.backgroundColor,
      AppColors.accentLime,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';

void main() {
  testWidgets('MaterialApp smoke', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text(AppStrings.appTitle))),
      ),
    );
    expect(find.text(AppStrings.appTitle), findsOneWidget);
  });
}

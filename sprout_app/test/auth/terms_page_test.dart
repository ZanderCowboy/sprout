import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/features/auth/application/terms_of_service_service.dart';
import 'package:sprout/features/auth/application/terms_of_service_service_impl.dart';
import 'package:sprout/features/auth/presentation/terms_page.dart';

import '../mocks/mocks.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._strings);

  final Map<String, String> _strings;

  @override
  Future<ByteData> load(String key) async {
    final value = _strings[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

void main() {
  testWidgets('renders remote markdown when RC has terms', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: TermsPage(
          termsOfService: TermsOfServiceServiceImpl(
            remoteConfig: FakeRemoteConfigService(
              strings: {
                RemoteConfigKeys.termsOfService:
                    '# Remote Terms\n\nFrom Firebase.',
              },
            ),
            assetBundle: _FakeAssetBundle({
              TermsOfServiceService.bundledAssetPath: '# Bundled',
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.termsOfService), findsOneWidget);
    expect(find.byType(Markdown), findsOneWidget);
    expect(find.textContaining('From Firebase.'), findsOneWidget);
  });

  testWidgets('renders bundled markdown when RC is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: TermsPage(
          termsOfService: TermsOfServiceServiceImpl(
            remoteConfig: FakeRemoteConfigService(),
            assetBundle: _FakeAssetBundle({
              TermsOfServiceService.bundledAssetPath:
                  '# Bundled Terms\n\nLocal placeholder.',
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Local placeholder.'), findsOneWidget);
  });
}

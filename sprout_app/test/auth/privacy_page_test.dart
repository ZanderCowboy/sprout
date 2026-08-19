import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/theme/app_theme.dart';
import 'package:sprout/features/auth/application/privacy_policy_service.dart';
import 'package:sprout/features/auth/presentation/privacy_page.dart';

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
  testWidgets('renders remote markdown when RC has privacy policy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PrivacyPage(
          privacyPolicy: PrivacyPolicyService(
            remoteConfig: FakeRemoteConfigService(
              strings: {
                RemoteConfigKeys.privacyPolicy:
                    '# Remote Privacy\n\nFrom Firebase.',
              },
            ),
            assetBundle: _FakeAssetBundle({
              PrivacyPolicyService.bundledAssetPath: '# Bundled',
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
    expect(find.byType(Markdown), findsOneWidget);
    expect(find.textContaining('From Firebase.'), findsOneWidget);
  });

  testWidgets('renders bundled markdown when RC is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PrivacyPage(
          privacyPolicy: PrivacyPolicyService(
            remoteConfig: FakeRemoteConfigService(),
            assetBundle: _FakeAssetBundle({
              PrivacyPolicyService.bundledAssetPath:
                  '# Bundled Privacy\n\nLocal placeholder.',
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Local placeholder.'), findsOneWidget);
  });
}

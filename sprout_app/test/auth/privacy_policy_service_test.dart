import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/features/auth/application/privacy_policy_service.dart';

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
  const bundled = '# Bundled Privacy\n\nLocal placeholder.';

  PrivacyPolicyService service({Map<String, String> remote = const {}}) {
    return PrivacyPolicyService(
      remoteConfig: FakeRemoteConfigService(strings: remote),
      assetBundle: _FakeAssetBundle({
        PrivacyPolicyService.bundledAssetPath: bundled,
      }),
    );
  }

  test('uses bundled markdown when remote string is missing', () async {
    final markdown = await service().loadMarkdown();
    expect(markdown, bundled);
  });

  test('uses bundled markdown when remote string is blank', () async {
    final markdown = await service(
      remote: {RemoteConfigKeys.privacyPolicy: '   '},
    ).loadMarkdown();
    expect(markdown, bundled);
  });

  test('uses remote string when fetch succeeds with content', () async {
    const remote = '# Remote Privacy\n\nFrom Firebase.';
    final markdown = await service(
      remote: {RemoteConfigKeys.privacyPolicy: remote},
    ).loadMarkdown();
    expect(markdown, remote);
  });
}

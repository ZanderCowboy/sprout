import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/features/auth/application/terms_of_service_service.dart';

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
  const bundled = '# Bundled Terms\n\nLocal placeholder.';

  TermsOfServiceService service({Map<String, String> remote = const {}}) {
    return TermsOfServiceService(
      remoteConfig: FakeRemoteConfigService(strings: remote),
      assetBundle: _FakeAssetBundle({
        TermsOfServiceService.bundledAssetPath: bundled,
      }),
    );
  }

  test('uses bundled markdown when remote string is missing', () async {
    final markdown = await service().loadMarkdown();
    expect(markdown, bundled);
  });

  test('uses bundled markdown when remote string is blank', () async {
    final markdown = await service(
      remote: {RemoteConfigKeys.termsOfService: '   '},
    ).loadMarkdown();
    expect(markdown, bundled);
  });

  test('uses remote string when fetch succeeds with content', () async {
    const remote = '# Remote Terms\n\nFrom Firebase.';
    final markdown = await service(
      remote: {RemoteConfigKeys.termsOfService: remote},
    ).loadMarkdown();
    expect(markdown, remote);
  });
}

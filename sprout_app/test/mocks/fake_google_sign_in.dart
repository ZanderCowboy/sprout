import 'package:google_sign_in/google_sign_in.dart';

class FakeGoogleSignIn implements GoogleSignIn {
  FakeGoogleSignInAccount? mockUser;
  GoogleSignInException? mockException;

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    final exception = mockException;
    if (exception != null) {
      throw exception;
    }
    final user = mockUser;
    if (user == null) {
      throw GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'User cancelled',
      );
    }
    return user;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    mockUser = null;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleSignInAccount implements GoogleSignInAccount {
  FakeGoogleSignInAccount({
    required this.id,
    required this.email,
    this.displayName,
    required this.idToken,
    this.accessToken,
  });

  @override
  final String id;

  @override
  final String email;

  @override
  final String? displayName;

  final String idToken;
  final String? accessToken;

  @override
  GoogleSignInAuthentication get authentication => FakeGoogleSignInAuthentication(
        idToken: idToken,
        accessToken: accessToken,
      );

  @override
  GoogleSignInAuthorizationClient get authorizationClient =>
      FakeGoogleSignInAuthorizationClient(accessToken: accessToken);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleSignInAuthentication implements GoogleSignInAuthentication {
  FakeGoogleSignInAuthentication({this.idToken, this.accessToken});

  @override
  final String? idToken;

  @override
  final String? accessToken;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleSignInAuthorizationClient
    implements GoogleSignInAuthorizationClient {
  FakeGoogleSignInAuthorizationClient({this.accessToken});

  final String? accessToken;

  @override
  Future<AuthorizationTokens?> authorizationForScopes(
    List<String> scopes,
  ) async {
    final token = accessToken;
    if (token == null) return null;
    return FakeAuthorizationTokens(accessToken: token);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthorizationTokens implements AuthorizationTokens {
  FakeAuthorizationTokens({required this.accessToken});

  @override
  final String accessToken;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

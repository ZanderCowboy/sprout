import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class FakeSupabaseClient implements SupabaseClient {
  User? mockAuthUser;

  @override
  GoTrueClient get auth => FakeGoTrueClient(mockAuthUser);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoTrueClient implements GoTrueClient {
  FakeGoTrueClient(this.mockAuthUser);

  final User? mockAuthUser;

  @override
  User? get currentUser => mockAuthUser;

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async {
    return AuthResponse(
      user: mockAuthUser,
      session: mockAuthUser != null
          ? Session(
              accessToken: 'mock-access-token',
              tokenType: 'bearer',
              user: mockAuthUser,
            )
          : null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

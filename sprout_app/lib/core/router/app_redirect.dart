import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/auth/export.dart';

/// Auth + intro gate for go_router. Returns a new location or null to stay.
String? resolveAuthRedirect({
  required AuthViewState auth,
  required bool introCompleted,
  required String location,
  Uri? uri,
}) {
  bool locIs(AppRoute route) => location == route.path;

  if (auth is AuthViewLoading) {
    return locIs(AppRoute.loading) ? null : AppRoute.loading.path;
  }

  if (auth is AuthViewGuest) {
    if (!introCompleted) {
      return locIs(AppRoute.intro) ? null : AppRoute.intro.path;
    }
    if (AppRoute.isUnsignedAllowed(location)) return null;
    return _signInWithFrom(uri, location);
  }

  if (locIs(AppRoute.intro) ||
      locIs(AppRoute.signIn) ||
      locIs(AppRoute.loading)) {
    final from = uri?.queryParameters['from'];
    if (from != null && _isSafeInternalFrom(from)) return from;
    return AppRoute.overview.path;
  }
  return null;
}

String _signInWithFrom(Uri? uri, String location) {
  final from = uri?.path ?? location;
  if (!_isSafeInternalFrom(from) || from == AppRoute.loading.path) {
    return AppRoute.signIn.path;
  }
  return Uri(
    path: AppRoute.signIn.path,
    queryParameters: {'from': from},
  ).toString();
}

bool _isSafeInternalFrom(String from) {
  if (!from.startsWith('/') || from.startsWith('//')) return false;
  return from != AppRoute.signIn.path &&
      from != AppRoute.intro.path &&
      from != AppRoute.loading.path &&
      from != AppRoute.terms.path &&
      from != AppRoute.privacy.path;
}

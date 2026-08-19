enum AppRoute {
  loading('/loading'),
  intro('/intro'),
  signIn('/sign-in'),
  terms('/terms'),
  overview('/overview'),
  accounts('/accounts'),
  accountDetail('/accounts/:id'),
  goals('/goals'),
  goalDetail('/goals/:id'),
  settings('/settings'),
  account('/settings/account'),
  transactions('/settings/transactions'),
  transactionDetail('/settings/transactions/:id'),
  recurring('/settings/recurring'),
  budget('/settings/budget');

  const AppRoute(this.path);
  final String path;

  /// Concrete URL for param routes (`:id` → value).
  String location({String? id}) {
    if (path.contains(':id')) {
      if (id == null || id.isEmpty) {
        throw ArgumentError('id required for $name');
      }
      return path.replaceFirst(':id', id);
    }
    return path;
  }

  static const unsignedAllowed = <AppRoute>{intro, signIn, terms};

  static bool isUnsignedAllowed(String location) {
    return unsignedAllowed.any((route) => route.path == location);
  }
}

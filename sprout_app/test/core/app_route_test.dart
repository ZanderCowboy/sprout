import 'package:flutter_test/flutter_test.dart';
import 'package:sprout/core/router/app_route.dart';

void main() {
  test('location returns path when no id is needed', () {
    expect(AppRoute.overview.location(), AppRoute.overview.path);
    expect(AppRoute.signIn.path, '/sign-in');
  });

  test('location substitutes :id', () {
    expect(
      AppRoute.accountDetail.location(id: 'abc'),
      '/accounts/abc',
    );
    expect(
      AppRoute.transactionDetail.location(id: 'tx-1'),
      '/settings/transactions/tx-1',
    );
  });

  test('location throws when id is missing on a param route', () {
    expect(() => AppRoute.goalDetail.location(), throwsArgumentError);
    expect(() => AppRoute.goalDetail.location(id: ''), throwsArgumentError);
  });
}

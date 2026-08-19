import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/router/app_redirect.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/core/router/go_router_refresh_stream.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/presentation/account_page.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/intro_page.dart';
import 'package:sprout/features/auth/presentation/privacy_page.dart';
import 'package:sprout/features/auth/presentation/sign_in_page.dart';
import 'package:sprout/features/auth/presentation/terms_page.dart';
import 'package:sprout/features/budget/presentation/budget_planner_screen.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/home/export.dart';
import 'package:sprout/features/settings/presentation/settings_page.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/features/transactions/presentation/recurring_payments_page.dart';
import 'package:sprout/features/transactions/presentation/transaction_detail_page.dart';
import 'package:sprout/features/transactions/presentation/transactions_page.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required UserContext userContext,
  required GoRouterRefreshStream refreshListenable,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final rootKey = navigatorKey ?? GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoute.loading.path,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      return resolveAuthRedirect(
        auth: authCubit.state,
        introCompleted: userContext.introCompleted,
        location: state.matchedLocation,
        uri: state.uri,
      );
    },
    routes: [
      GoRoute(
        path: AppRoute.loading.path,
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AppRoute.intro.path,
        builder: (context, state) {
          return IntroPage(
            initialPage: userContext.introCompleted ? 2 : 0,
            onCompleted: () {
              userContext.markIntroCompleted();
              context.go(AppRoute.signIn.path);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoute.signIn.path,
        builder: (context, state) {
          return SignInPage(onBackToIntro: () => context.go(AppRoute.intro.path));
        },
      ),
      GoRoute(
        path: AppRoute.terms.path,
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: AppRoute.privacy.path,
        builder: (context, state) => const PrivacyPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => HomeBloc(
                  accountsService: sl(),
                  transactionsService: sl(),
                )..add(const HomeSubscriptionRequested()),
              ),
              BlocProvider(
                create: (_) => GoalsBloc(
                  goalsService: sl(),
                  transactionsService: sl(),
                  accountsService: sl(),
                )..add(const GoalsSubscriptionRequested()),
              ),
            ],
            child: ShellPage(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.overview.path,
                builder: (context, state) => const OverviewPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.accounts.path,
                builder: (context, state) => const AccountsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) {
                      return AccountDetailPage(
                        accountId: state.pathParameters['id']!,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.goals.path,
                builder: (context, state) => const GoalsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) {
                      return GoalDetailPage(goalId: state.pathParameters['id']!);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings.path,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'account',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const AccountPage(),
                  ),
                  GoRoute(
                    path: 'transactions',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const TransactionsPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        parentNavigatorKey: rootKey,
                        builder: (context, state) {
                          return TransactionDetailPage(
                            transactionId: state.pathParameters['id']!,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'recurring',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const RecurringPaymentsPage(),
                  ),
                  GoRoute(
                    path: 'budget',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const BudgetPlannerScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/auth/presentation/auth_gate.dart';
import 'package:sprout/features/connectivity/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/home/export.dart';
import 'package:sprout/features/shell/shell.dart';
import 'package:sprout/ui/export.dart';

class SproutApp extends StatelessWidget {
  const SproutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ConnectivityCubit()),
        BlocProvider(
          create: (_) =>
              AuthCubit(authService: sl<AuthService>(), appConfig: sl()),
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthViewState>(
        builder: (context, state) {
          final signedIn = state is AuthViewSignedIn;
          Widget app = MaterialApp(
            key: ValueKey<String>(signedIn ? 'signed-in' : 'signed-out'),
            title: AppStrings.appTitle,
            theme: buildAppTheme(),
            themeMode: ThemeMode.dark,
            home: const AuthGate(signedIn: ShellPage()),
            debugShowCheckedModeBanner: false,
            builder: (context, child) => EnvironmentBanner(
              environment: sl<AppConfig>().environment,
              child: child ?? const SizedBox.shrink(),
            ),
          );
          if (!signedIn) return app;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    HomeBloc(accountsService: sl(), transactionsService: sl())
                      ..add(const HomeSubscriptionRequested()),
              ),
              BlocProvider(
                create: (_) => GoalsBloc(
                  goalsService: sl(),
                  transactionsService: sl(),
                  accountsService: sl(),
                )..add(const GoalsSubscriptionRequested()),
              ),
            ],
            child: app,
          );
        },
      ),
    );
  }
}

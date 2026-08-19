import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/router/app_router.dart';
import 'package:sprout/core/router/go_router_refresh_stream.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/connectivity/export.dart';
import 'package:sprout/ui/export.dart';

class SproutApp extends StatefulWidget {
  const SproutApp({super.key});

  @override
  State<SproutApp> createState() => _SproutAppState();
}

class _SproutAppState extends State<SproutApp> {
  late final AuthCubit _authCubit;
  late final GoRouterRefreshStream _refresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(authService: sl<AuthService>(), appConfig: sl());
    _refresh = GoRouterRefreshStream(_authCubit.stream);
    _router = createAppRouter(
      authCubit: _authCubit,
      userContext: sl<UserContext>(),
      refreshListenable: _refresh,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    unawaited(_authCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ConnectivityCubit()),
        BlocProvider.value(value: _authCubit),
      ],
      child: BlocListener<AuthCubit, AuthViewState>(
        listener: (context, state) {
          if (state is AuthViewSignedIn && !sl<UserContext>().introCompleted) {
            unawaited(sl<UserContext>().markIntroCompleted());
          }
        },
        child: MaterialApp.router(
          title: AppStrings.appTitle,
          theme: buildAppTheme(),
          themeMode: ThemeMode.dark,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => EnvironmentBanner(
            environment: sl<AppConfig>().environment,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

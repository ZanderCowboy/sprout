import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:debug_lens/debug_lens.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/debug/sprout_debug_lens.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/flags/remote_config_service.dart';
import 'package:sprout/core/router/app_router.dart';
import 'package:sprout/core/router/go_router_refresh_stream.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/auth/export.dart';
import 'package:sprout/features/connectivity/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/ui/export.dart';
import 'package:sprout/bootstrap.dart';

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
      hasExistingSetup: _hasExistingSetup,
      observers: [
        if (shouldEnableDebugLens()) SproutDebugLens.navigatorObserver,
      ],
    );
    unawaited(_setupDebugLens());
  }

  Future<void> _setupDebugLens() async {
    if (!shouldEnableDebugLens()) {
      return;
    }
    DebugLens.debugLensEnabled = true;

    final remoteConfig = sl<RemoteConfigService>();
    if (remoteConfig.isReady) {
      try {
        final rcInstance = FirebaseRemoteConfig.instance;
        final allKeys = rcInstance.getAll();
        final rcMap = <String, Object?>{};
        for (final entry in allKeys.entries) {
          final value = entry.value;
          if (value.source != ValueSource.valueStatic) {
            rcMap[entry.key] = value.asString();
          }
        }
        await DebugLens.instance.setRemoteConfigData(rcMap);
      } on Object {
        // Fail silently if Remote Config is unavailable
      }
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    unawaited(_authCubit.close());
    super.dispose();
  }

  Future<bool> _hasExistingSetup() async {
    final accounts = await sl<AccountsService>().getAccounts();
    if (accounts.isNotEmpty) return true;
    final goals = await sl<GoalsService>().getGoals();
    return goals.isNotEmpty;
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
          builder: (context, child) {
            Widget result = EnvironmentBanner(
              environment: sl<AppConfig>().environment,
              child: child ?? const SizedBox.shrink(),
            );
            if (shouldEnableDebugLens()) {
              result = SproutDebugLens.wrap(result);
            }
            return result;
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/connectivity/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/home/export.dart';
import 'package:sprout/features/shell/shell.dart';

class SproutApp extends StatelessWidget {
  const SproutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ConnectivityCubit()),
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
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: buildAppTheme(),
        themeMode: ThemeMode.dark,
        home: const ShellPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/home/export.dart';

/// Provides shell-scoped blocs for Overview and Goals tabs.
class ShellBlocScope extends StatelessWidget {
  const ShellBlocScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}

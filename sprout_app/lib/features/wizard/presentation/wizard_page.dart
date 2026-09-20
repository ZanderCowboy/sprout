import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/analytics/analytics_service.dart';
import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import 'wizard_cubit.dart';

part '_wizard_body.dart';
part '_brand_row.dart';
part '_progress_dots.dart';
part '_hero_icon.dart';
part '_step_1_goal.dart';
part '_step_2_account.dart';
part '_step_3_deposit.dart';
part '_readonly_row.dart';
part '_footer_actions.dart';

class WizardPage extends StatelessWidget {
  const WizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WizardCubit(
        accountsService: sl<AccountsService>(),
        goalsService: sl<GoalsService>(),
        transactionsService: sl<TransactionsService>(),
        userContext: sl<UserContext>(),
        analyticsService: sl<AnalyticsService>(),
        defaultGoalColorArgb: AppColors.cardColorAt(1).toARGB32(),
        defaultAccountColorArgb: AppColors.cardColorAt(0).toARGB32(),
        defaultGoalIconCodePoint: Icons.savings_rounded.codePoint,
      )..load(),
      child: const _WizardBody(),
    );
  }
}

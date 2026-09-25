import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/purchases/export.dart';
import 'budget_planner_screen.dart';

/// Route guard for Budget Planner that enforces Premium access.
///
/// When the user can access the feature (Premium active or kill switch off),
/// shows [BudgetPlannerScreen]. Otherwise redirects to Settings.
class BudgetPlannerGate extends StatefulWidget {
  const BudgetPlannerGate({super.key});

  @override
  State<BudgetPlannerGate> createState() => _BudgetPlannerGateState();
}

class _BudgetPlannerGateState extends State<BudgetPlannerGate> {
  late final Future<bool> _canUseFuture;

  @override
  void initState() {
    super.initState();
    _canUseFuture = sl<PremiumService>().canUsePremiumFeature(
      isPremiumFeature: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canUseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final canUse = snapshot.data ?? false;
        if (canUse) {
          return const BudgetPlannerScreen();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(AppRoute.settings.path);
          }
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

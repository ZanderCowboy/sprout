import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';

class RecurringDepositsLink extends StatelessWidget {
  const RecurringDepositsLink({
    super.key,
    required this.visible,
    required this.identifier,
  });

  final bool visible;
  final String identifier;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SproutListTile(
        identifier: identifier,
        label: AppStrings.manageRecurringPayments,
        leading: const Icon(Icons.autorenew_rounded),
        title: const Text(AppStrings.manageRecurringPayments),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(AppRoute.recurring.path),
      ),
    );
  }
}

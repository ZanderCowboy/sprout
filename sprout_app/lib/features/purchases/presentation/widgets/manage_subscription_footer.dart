import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/features/purchases/presentation/utils/manage_subscription_colors.dart';

class ManageSubscriptionFooter extends StatelessWidget {
  const ManageSubscriptionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.manageSubscriptionFooter,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05 * 12,
        color: ManageSubscriptionColors.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}

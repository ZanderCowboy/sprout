import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/features/purchases/presentation/utils/manage_subscription_colors.dart';

class ManageSubscriptionContextStrip extends StatelessWidget {
  const ManageSubscriptionContextStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ManageSubscriptionColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.verified_user_rounded,
              color: ManageSubscriptionColors.primary,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.manageSubscriptionMembershipActive,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.05 * 12,
                  color: ManageSubscriptionColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

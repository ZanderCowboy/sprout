import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/ui/export.dart';

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({
    super.key,
    required this.versionLabel,
    required this.busy,
    required this.onSignOut,
    required this.onPrivacy,
    required this.onTerms,
  });

  final String? versionLabel;
  final bool busy;
  final VoidCallback onSignOut;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  static final ButtonStyle _linkStyle = TextButton.styleFrom(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    minimumSize: Size.zero,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SproutOutlinedButton.icon(
          identifier: SemanticsIds.accountSignOut,
          label: AppStrings.signOut,
          onPressed: busy ? null : onSignOut,
          icon: Icon(Icons.logout_rounded, color: scheme.error),
          labelWidget: Text(
            AppStrings.signOut,
            style: textTheme.labelLarge?.copyWith(color: scheme.error),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.45)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.appTitle,
          style: textTheme.titleMedium?.copyWith(color: AppColors.seed),
        ),
        if (versionLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            versionLabel!,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SproutTextButton(
              identifier: SemanticsIds.accountPrivacy,
              label: AppStrings.privacyPolicy,
              onPressed: busy ? null : onPrivacy,
              style: _linkStyle,
              child: Text(
                AppStrings.privacyPolicy,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
              ),
            ),
            Text(
              '·',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SproutTextButton(
              identifier: SemanticsIds.accountTerms,
              label: AppStrings.termsOfService,
              onPressed: busy ? null : onTerms,
              style: _linkStyle,
              child: Text(
                AppStrings.termsOfService,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

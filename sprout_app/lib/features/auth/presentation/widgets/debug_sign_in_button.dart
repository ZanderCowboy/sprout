import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/ui/export.dart';

/// Development-only local sign-in. Hidden in production.
class DebugSignInButton extends StatelessWidget {
  const DebugSignInButton({
    super.key,
    this.enabled = true,
    this.identifier = SemanticsIds.introDebugSignIn,
  });

  final bool enabled;
  final String identifier;

  @override
  Widget build(BuildContext context) {
    final AuthCubit cubit;
    try {
      cubit = context.read<AuthCubit>();
    } on Object {
      return const SizedBox.shrink();
    }
    if (!cubit.debugSignInAvailable) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SproutOutlinedButton(
          identifier: identifier,
          label: AppStrings.debugSignIn,
          onPressed: enabled ? cubit.debugSignIn : null,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.debugSignInDetails,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

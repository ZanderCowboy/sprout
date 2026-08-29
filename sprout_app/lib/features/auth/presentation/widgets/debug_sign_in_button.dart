import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';

/// Development-only local sign-in. Hidden in production.
class DebugSignInButton extends StatelessWidget {
  const DebugSignInButton({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    if (!cubit.debugSignInAvailable) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: enabled ? cubit.debugSignIn : null,
          child: const Text(AppStrings.debugSignIn),
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

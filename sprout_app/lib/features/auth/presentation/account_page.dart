import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: BlocBuilder<AuthCubit, AuthViewState>(
        builder: (context, state) {
          return switch (state) {
            AuthViewLoading() ||
            AuthViewGuest() => const Center(child: CircularProgressIndicator()),
            AuthViewSignedIn(:final user, :final busy, :final errorMessage) =>
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_rounded),
                    title: Text(
                      user.email?.isNotEmpty == true
                          ? user.email!
                          : 'Signed in',
                    ),
                    subtitle: Text('User ID: ${user.id}'),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => context.read<AuthCubit>().signOut(),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign out'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Signing out keeps your local data on this device. '
                    'Cloud sync pauses until you sign in again.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

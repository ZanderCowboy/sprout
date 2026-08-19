import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/auth/application/auth_service.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        authService: sl<AuthService>(),
        appConfig: sl(),
      ),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatefulWidget {
  const _AccountView();

  @override
  State<_AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<_AccountView> {
  late final TextEditingController _emailController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: BlocConsumer<AuthCubit, AuthViewState>(
        listener: (context, state) {
          if (state is AuthViewGuest &&
              _emailController.text != state.email &&
              !state.busy) {
            _emailController.value = TextEditingValue(
              text: state.email,
              selection: TextSelection.collapsed(offset: state.email.length),
            );
          }
          if (state is AuthViewSignedIn) {
            _otpController.clear();
          }
        },
        builder: (context, state) {
          return switch (state) {
            AuthViewLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            AuthViewSignedIn(:final user, :final busy, :final errorMessage) =>
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_rounded),
                    title: Text(user.email?.isNotEmpty == true
                        ? user.email!
                        : 'Signed in'),
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
            AuthViewGuest(
              :final supabaseConfigured,
              :final googleAvailable,
              :final otpSent,
              :final busy,
              :final errorMessage,
              :final infoMessage,
            ) =>
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Sign in to sync your savings across devices.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  if (!supabaseConfigured)
                    Text(
                      'Supabase is not configured for this build. '
                      'You can keep using Sprout with local data only.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  if (supabaseConfigured) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: context.read<AuthCubit>().emailChanged,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => context.read<AuthCubit>().sendOtp(),
                      child: const Text('Send code'),
                    ),
                    if (otpSent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _otpController,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: busy
                            ? null
                            : () => context
                                .read<AuthCubit>()
                                .verifyOtp(_otpController.text),
                        child: const Text('Verify code'),
                      ),
                    ],
                    if (googleAvailable) ...[
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () =>
                                context.read<AuthCubit>().signInWithGoogle(),
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: const Text('Continue with Google'),
                      ),
                    ],
                  ],
                  if (busy) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (infoMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(infoMessage),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
          };
        },
      ),
    );
  }
}

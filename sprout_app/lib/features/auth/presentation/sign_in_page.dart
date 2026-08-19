import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, this.onBackToIntro});

  final VoidCallback? onBackToIntro;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _displayNameController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _openTerms() {
    context.push(AppRoute.terms.path);
  }

  void _openPrivacy() {
    context.push(AppRoute.privacy.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBackToIntro == null
            ? null
            : BackButton(onPressed: widget.onBackToIntro),
        title: const Text('Sign in'),
      ),
      body: BlocConsumer<AuthCubit, AuthViewState>(
        listener: (context, state) {
          if (state is AuthViewGuest && !state.busy) {
            if (_emailController.text != state.email) {
              _emailController.value = TextEditingValue(
                text: state.email,
                selection: TextSelection.collapsed(offset: state.email.length),
              );
            }
            if (_displayNameController.text != state.displayName) {
              _displayNameController.value = TextEditingValue(
                text: state.displayName,
                selection: TextSelection.collapsed(
                  offset: state.displayName.length,
                ),
              );
            }
          }
          if (state is AuthViewSignedIn) {
            _otpController.clear();
          }
        },
        builder: (context, state) {
          return switch (state) {
            AuthViewLoading() || AuthViewSignedIn() => const Center(
              child: CircularProgressIndicator(),
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
                  const SizedBox(height: 8),
                  const Center(
                    // TODO: replace with the Sprout app icon asset.
                    child: CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.eco_rounded, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sign in to sync your savings across devices.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  if (!supabaseConfigured)
                    Text(
                      'Sign-in isn’t configured for this build.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (supabaseConfigured) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _displayNameController,
                      enabled: !busy,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: AppStrings.displayNameOptional,
                        helperText: AppStrings.displayNameExistingAccountHint,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: context.read<AuthCubit>().displayNameChanged,
                    ),
                    const SizedBox(height: 12),
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
                            : () => context.read<AuthCubit>().verifyOtp(
                                _otpController.text,
                              ),
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
                    const SizedBox(height: 24),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          const TextSpan(
                            text: '${AppStrings.byContinuingYouAgree} ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: _openTerms,
                              child: Text(
                                AppStrings.termsOfService,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' ${AppStrings.and} '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: _openPrivacy,
                              child: Text(
                                AppStrings.privacyPolicy,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
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

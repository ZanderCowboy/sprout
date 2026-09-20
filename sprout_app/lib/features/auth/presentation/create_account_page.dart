import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/widgets/debug_sign_in_button.dart';
import 'package:sprout/features/connectivity/presentation/connectivity_cubit.dart';
import 'package:sprout/ui/export.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key, this.onBackToIntro});

  final VoidCallback? onBackToIntro;

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _openTerms() {
    context.push(AppRoute.terms.path);
  }

  void _openPrivacy() {
    context.push(AppRoute.privacy.path);
  }

  void _goToSignIn() {
    context.go(AppRoute.signIn.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBackToIntro == null
            ? null
            : SproutBackButton(
                identifier: SemanticsIds.createAccountBack,
                label: AppStrings.back,
                onPressed: widget.onBackToIntro,
              ),
        title: const Text(AppStrings.createAccount),
      ),
      body: BlocBuilder<ConnectivityCubit, bool>(
        builder: (context, isOnline) {
          return BlocConsumer<AuthCubit, AuthViewState>(
            listener: (context, state) {
              if (state is AuthViewSignedOut && !state.busy) {
                if (_emailController.text != state.email) {
                  _emailController.value = TextEditingValue(
                    text: state.email,
                    selection: TextSelection.collapsed(
                      offset: state.email.length,
                    ),
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
              if (state is AuthViewSignedOut && state.otpSent) {
                context.go(AppRoute.verifyOtp.path);
              }
            },
            builder: (context, state) {
              return switch (state) {
                AuthViewLoading() || AuthViewSignedIn() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AuthViewSignedOut(
                  :final supabaseConfigured,
                  :final googleAvailable,
                  :final busy,
                  :final errorMessage,
                  :final infoMessage,
                ) =>
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 8),
                      const Center(
                        child: CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.eco_rounded, size: 40),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppStrings.createAccountSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      if (!isOnline)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppStrings.offlineSignInBlocked,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!supabaseConfigured)
                        Text(
                          AppStrings.signInNotConfigured,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      if (supabaseConfigured) ...[
                        const SizedBox(height: 16),
                        SproutTextField(
                          identifier: SemanticsIds.createAccountDisplayNameField,
                          controller: _displayNameController,
                          enabled: isOnline && !busy,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: AppStrings.displayNameRequired,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: context
                              .read<AuthCubit>()
                              .displayNameChanged,
                        ),
                        const SizedBox(height: 12),
                        SproutTextField(
                          identifier: SemanticsIds.createAccountEmailField,
                          controller: _emailController,
                          enabled: isOnline && !busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: AppStrings.email,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: context.read<AuthCubit>().emailChanged,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.codeWillBeSent,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SproutFilledButton(
                          identifier: SemanticsIds.createAccountContinue,
                          label: AppStrings.continueButton,
                          onPressed: (!isOnline || busy)
                              ? null
                              : () => context.read<AuthCubit>().sendRegisterOtp(),
                        ),
                        if (googleAvailable) ...[
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(AppStrings.or),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SproutOutlinedButton.icon(
                            identifier: SemanticsIds.createAccountGoogle,
                            label: AppStrings.continueWithGoogle,
                            onPressed: (!isOnline || busy)
                                ? null
                                : () => context
                                      .read<AuthCubit>()
                                      .signInWithGoogle(),
                            icon: const Icon(Icons.g_mobiledata_rounded),
                            labelWidget: const Text(
                              AppStrings.continueWithGoogle,
                            ),
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
                                child: SproutTextButton(
                                  identifier: SemanticsIds.createAccountTermsLink,
                                  label: AppStrings.termsOfService,
                                  onPressed: _openTerms,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
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
                                child: SproutTextButton(
                                  identifier: SemanticsIds.createAccountPrivacyLink,
                                  label: AppStrings.privacyPolicy,
                                  onPressed: _openPrivacy,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
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
                        const SizedBox(height: 16),
                        Center(
                          child: SproutTextButton(
                            identifier: SemanticsIds.createAccountSignInLink,
                            label: AppStrings.iAlreadyHaveAnAccount,
                            onPressed: _goToSignIn,
                            child: Text(
                              AppStrings.iAlreadyHaveAnAccount,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      DebugSignInButton(
                        enabled: isOnline && !busy,
                        identifier: SemanticsIds.createAccountDebugSignIn,
                      ),
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
          );
        },
      ),
    );
  }
}

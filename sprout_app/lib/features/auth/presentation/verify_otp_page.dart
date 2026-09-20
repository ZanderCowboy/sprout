import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/core/router/app_route.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/connectivity/presentation/connectivity_cubit.dart';
import 'package:sprout/ui/export.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  late final TextEditingController _otpController;
  String? _lastAutoSubmittedOtp;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _editEmail(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    if (state is AuthViewSignedOut) {
      if (state.isRegisterPath) {
        context.go(AppRoute.createAccount.path);
      } else {
        context.go(AppRoute.signIn.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SproutBackButton(
          identifier: SemanticsIds.verifyOtpBack,
          label: AppStrings.back,
          onPressed: () => _editEmail(context),
        ),
        title: const Text(AppStrings.verifyYourEmail),
      ),
      body: BlocBuilder<ConnectivityCubit, bool>(
        builder: (context, isOnline) {
          return BlocConsumer<AuthCubit, AuthViewState>(
            listener: (context, state) {
              if (state is AuthViewSignedIn) {
                _otpController.clear();
                _lastAutoSubmittedOtp = null;
              }
            },
            builder: (context, state) {
              return switch (state) {
                AuthViewLoading() || AuthViewSignedIn() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AuthViewSignedOut(
                  :final email,
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
                          child: Icon(Icons.email_outlined, size: 40),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppStrings.checkYourEmail,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SproutTextField(
                        identifier: SemanticsIds.verifyOtpCodeField,
                        controller: _otpController,
                        enabled: isOnline && !busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: AppStrings.verificationCode,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.length == 6 &&
                              value != _lastAutoSubmittedOtp &&
                              isOnline &&
                              !busy) {
                            _lastAutoSubmittedOtp = value;
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              if (!mounted) return;
                              context.read<AuthCubit>().verifyOtp(value);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SproutFilledButton(
                        identifier: SemanticsIds.verifyOtpVerify,
                        label: AppStrings.verifyCode,
                        onPressed: (!isOnline || busy)
                            ? null
                            : () => context.read<AuthCubit>().verifyOtp(
                                _otpController.text,
                              ),
                      ),
                      const SizedBox(height: 12),
                      SproutFilledButton.tonal(
                        identifier: SemanticsIds.verifyOtpResend,
                        label: AppStrings.resendCode,
                        onPressed: (!isOnline || busy)
                            ? null
                            : () => context.read<AuthCubit>().sendOtp(),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SproutTextButton(
                          identifier: SemanticsIds.verifyOtpBack,
                          label: AppStrings.editEmail,
                          onPressed: () => _editEmail(context),
                          child: Text(
                            AppStrings.editEmail,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                          ),
                        ),
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

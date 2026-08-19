import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/di/service_locator.dart';
import '../application/privacy_policy_service.dart';
import 'bloc/privacy_cubit.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, this.privacyPolicy});

  final PrivacyPolicyService? privacyPolicy;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrivacyCubit(
        privacyPolicy: privacyPolicy ?? sl<PrivacyPolicyService>(),
      ),
      child: const _PrivacyView(),
    );
  }
}

class _PrivacyView extends StatelessWidget {
  const _PrivacyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.privacyPolicy)),
      body: BlocBuilder<PrivacyCubit, PrivacyViewState>(
        builder: (context, state) {
          return switch (state) {
            PrivacyViewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            PrivacyViewError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            PrivacyViewReady(:final markdown) => Markdown(
              data: markdown,
              selectable: true,
              padding: const EdgeInsets.all(16),
            ),
          };
        },
      ),
    );
  }
}

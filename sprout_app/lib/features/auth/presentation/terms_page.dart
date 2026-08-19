import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/di/service_locator.dart';
import '../application/terms_of_service_service.dart';
import 'bloc/terms_cubit.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key, this.termsOfService});

  final TermsOfServiceService? termsOfService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TermsCubit(
        termsOfService: termsOfService ?? sl<TermsOfServiceService>(),
      ),
      child: const _TermsView(),
    );
  }
}

class _TermsView extends StatelessWidget {
  const _TermsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.termsOfService)),
      body: BlocBuilder<TermsCubit, TermsViewState>(
        builder: (context, state) {
          return switch (state) {
            TermsViewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TermsViewError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            TermsViewReady(:final markdown) => Markdown(
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

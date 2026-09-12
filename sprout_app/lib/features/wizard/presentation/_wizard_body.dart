part of 'wizard_page.dart';

class _WizardBody extends StatelessWidget {
  const _WizardBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<WizardCubit, WizardState>(
      listenWhen: (prev, curr) =>
          curr is WizardSkipped || curr is WizardCompleted,
      listener: (context, state) {
        if (state is WizardSkipped) {
          context.go(AppRoute.overview.path);
        } else if (state is WizardCompleted) {
          context.go(AppRoute.overview.path, extra: {'showWelcomeToast': true});
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceDeep,
        body: SafeArea(
          child: BlocBuilder<WizardCubit, WizardState>(
            builder: (context, state) {
              if (state is! WizardReady) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  _BrandRow(
                    onSkip: state.submitting
                        ? null
                        : () => context.read<WizardCubit>().skip(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _ProgressDots(currentStep: state.step),
                          const SizedBox(height: 8),
                          Text(
                            'Step ${state.step} of 3',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          if (state.step == 1)
                            _Step1Goal(state: state)
                          else if (state.step == 2)
                            _Step2Account(state: state)
                          else
                            _Step3Deposit(state: state),
                        ],
                      ),
                    ),
                  ),
                  _FooterActions(state: state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

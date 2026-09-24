part of 'wizard_page.dart';

class _FooterActions extends StatelessWidget {
  const _FooterActions({required this.state});

  final WizardReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WizardCubit>();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceBar,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (state.step > 1)
            Expanded(
              child: SproutOutlinedButton(
                identifier: SemanticsIds.wizardBack,
                label: AppStrings.back,
                onPressed: state.submitting ? null : cubit.goBack,
              ),
            ),
          if (state.step > 1) const SizedBox(width: 12),
          Expanded(
            child: state.step == 3
                ? SproutFilledButton(
                    identifier: SemanticsIds.wizardFinish,
                    label: AppStrings.wizardFinish,
                    onPressed: cubit.canFinish && !state.submitting
                        ? cubit.finish
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navSelected,
                      foregroundColor: Colors.white,
                    ),
                  )
                : SproutFilledButton(
                    identifier: SemanticsIds.wizardNext,
                    label: AppStrings.next,
                    onPressed: state.submitting
                        ? null
                        : (state.step == 1
                              ? (cubit.canGoToStep2 ? cubit.goToStep2 : null)
                              : (cubit.canGoToStep3 ? cubit.goToStep3 : null)),
                  ),
          ),
        ],
      ),
    );
  }
}

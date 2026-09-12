import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/features/accounts/export.dart';
import 'package:sprout/features/goals/export.dart';
import 'package:sprout/features/transactions/export.dart';
import 'package:sprout/ui/export.dart';

import 'wizard_cubit.dart';

class WizardPage extends StatelessWidget {
  const WizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WizardCubit(
        accountsService: sl<AccountsService>(),
        goalsService: sl<GoalsService>(),
        transactionsService: sl<TransactionsService>(),
        userContext: sl<UserContext>(),
        defaultGoalColorArgb: AppColors.cardColorAt(1).toARGB32(),
        defaultAccountColorArgb: AppColors.cardColorAt(0).toARGB32(),
      )..load(),
      child: const _WizardBody(),
    );
  }
}

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

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.onSkip});

  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/sprout-icon.png',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 12),
          Text(
            AppStrings.appTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          SproutTextButton(
            identifier: SemanticsIds.wizardSkip,
            label: AppStrings.wizardSkip,
            onPressed: onSkip,
          ),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == currentStep
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withOpacity(0.3),
            ),
          ),
          if (i < 3) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          'assets/images/sprout-icon.png',
          width: 28,
          height: 28,
          color: color,
        ),
      ),
    );
  }
}

class _Step1Goal extends StatefulWidget {
  const _Step1Goal({required this.state});

  final WizardReady state;

  @override
  State<_Step1Goal> createState() => _Step1GoalState();
}

class _Step1GoalState extends State<_Step1Goal> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.goalName);
    _targetController = TextEditingController(text: widget.state.goalTargetText);
    _nameController.addListener(_onNameChanged);
    _targetController.addListener(_onTargetChanged);
  }

  void _onNameChanged() {
    context.read<WizardCubit>().setGoalName(_nameController.text);
  }

  void _onTargetChanged() {
    context.read<WizardCubit>().setGoalTarget(_targetController.text);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _targetController.removeListener(_onTargetChanged);
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _HeroIcon(color: AppColors.accentCoral),
        const SizedBox(height: 16),
        Text(
          AppStrings.wizardGoalTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.wizardGoalSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SproutTextField(
                  identifier: SemanticsIds.wizardGoalName,
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.goalName,
                    errorText: widget.state.goalNameError,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                SproutTextField(
                  identifier: SemanticsIds.wizardGoalTarget,
                  controller: _targetController,
                  decoration: InputDecoration(
                    labelText: AppStrings.targetAmount,
                    errorText: widget.state.goalTargetError,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.color,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Semantics(
                        identifier: SemanticsIds.colorSwatchAt(i + 1),
                        button: true,
                        label: AppStrings.colorNumber(i + 1),
                        selected: widget.state.goalColorArgb ==
                            AppColors.cardPalette[i].toARGB32(),
                        child: GestureDetector(
                          onTap: () => context
                              .read<WizardCubit>()
                              .setGoalColor(
                                  AppColors.cardPalette[i].toARGB32()),
                          child: CircleAvatar(
                            backgroundColor: AppColors.cardPalette[i],
                            child: widget.state.goalColorArgb ==
                                    AppColors.cardPalette[i].toARGB32()
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step2Account extends StatefulWidget {
  const _Step2Account({required this.state});

  final WizardReady state;

  @override
  State<_Step2Account> createState() => _Step2AccountState();
}

class _Step2AccountState extends State<_Step2Account> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.accountName);
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    context.read<WizardCubit>().setAccountName(_nameController.text);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _HeroIcon(
          color: AppColors.accentViolet,
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.wizardAccountTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.wizardAccountSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SproutTextField(
                  identifier: SemanticsIds.wizardAccountName,
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.accountName,
                    errorText: widget.state.accountNameError,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.color,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Semantics(
                        identifier: SemanticsIds.colorSwatchAt(i + 1),
                        button: true,
                        label: AppStrings.colorNumber(i + 1),
                        selected: widget.state.accountColorArgb ==
                            AppColors.cardPalette[i].toARGB32(),
                        child: GestureDetector(
                          onTap: () => context
                              .read<WizardCubit>()
                              .setAccountColor(
                                  AppColors.cardPalette[i].toARGB32()),
                          child: CircleAvatar(
                            backgroundColor: AppColors.cardPalette[i],
                            child: widget.state.accountColorArgb ==
                                    AppColors.cardPalette[i].toARGB32()
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step3Deposit extends StatefulWidget {
  const _Step3Deposit({required this.state});

  final WizardReady state;

  @override
  State<_Step3Deposit> createState() => _Step3DepositState();
}

class _Step3DepositState extends State<_Step3Deposit> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.state.depositAmountText);
    _noteController = TextEditingController(text: widget.state.depositNote);
    _amountController.addListener(_onAmountChanged);
    _noteController.addListener(_onNoteChanged);
  }

  void _onAmountChanged() {
    context.read<WizardCubit>().setDepositAmount(_amountController.text);
  }

  void _onNoteChanged() {
    context.read<WizardCubit>().setDepositNote(_noteController.text);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _noteController.removeListener(_onNoteChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final targetCents = parseZarToCents(widget.state.goalTargetText) ?? 0;
    return Column(
      children: [
        _HeroIcon(color: AppColors.accentLime),
        const SizedBox(height: 16),
        Text(
          AppStrings.wizardDepositTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${AppStrings.wizardDepositSubtitle} ${widget.state.goalName.trim()}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReadOnlyRow(
                  label: AppStrings.goals,
                  value: widget.state.goalName.trim(),
                ),
                const SizedBox(height: 12),
                _ReadOnlyRow(
                  label: AppStrings.accounts,
                  value: widget.state.accountName.trim(),
                ),
                const SizedBox(height: 20),
                SproutTextField(
                  identifier: SemanticsIds.wizardDepositAmount,
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: AppStrings.amount,
                    errorText: widget.state.depositAmountError,
                    helperText: widget.state.depositAmountError == null
                        ? '${AppStrings.wizardMinimumDeposit} • ${AppStrings.wizardMaximumDeposit} ${formatZarFromCents(targetCents)}'
                        : null,
                    helperMaxLines: 2,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SproutTextField(
                  identifier: SemanticsIds.wizardDepositNote,
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: AppStrings.note,
                    hintText: AppStrings.optional,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.wizardDepositHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

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
            color: scheme.outlineVariant.withOpacity(0.5),
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
                onPressed: state.submitting ? null : () => cubit.goBack(),
              ),
            ),
          if (state.step > 1) const SizedBox(width: 12),
          Expanded(
            child: state.step == 3
                ? SproutFilledButton(
                    identifier: SemanticsIds.wizardFinish,
                    label: AppStrings.wizardFinish,
                    onPressed:
                        cubit.canFinish && !state.submitting
                            ? () => cubit.finish()
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
                            ? (cubit.canGoToStep2 ? () => cubit.goToStep2() : null)
                            : (cubit.canGoToStep3
                                ? () => cubit.goToStep3()
                                : null)),
                  ),
          ),
        ],
      ),
    );
  }
}

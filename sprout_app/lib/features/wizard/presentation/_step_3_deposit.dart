part of 'wizard_page.dart';

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
    final skipDeposit = widget.state.allocateLater;
    return Column(
      children: [
        const _HeroIcon(
          icon: Icons.payments_outlined,
          color: AppColors.seed,
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.wizardDepositTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.wizardDepositSubtitle,
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
                  enabled: !skipDeposit,
                  decoration: InputDecoration(
                    labelText: AppStrings.amount,
                    errorText:
                        skipDeposit ? null : widget.state.depositAmountError,
                    helperText: skipDeposit ||
                            widget.state.depositAmountError != null
                        ? null
                        : '${AppStrings.wizardMinimumDeposit} • ${AppStrings.wizardMaximumDeposit} ${formatZarFromCents(targetCents)}',
                    helperMaxLines: 2,
                    errorMaxLines: 2,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SproutCheckboxTile(
                  identifier: SemanticsIds.wizardAllocateLater,
                  label: AppStrings.wizardAllocateLater,
                  value: skipDeposit,
                  onChanged: widget.state.submitting
                      ? null
                      : (checked) => context
                          .read<WizardCubit>()
                          .setAllocateLater(checked ?? false),
                  subtitle: const Text(AppStrings.wizardAllocateLaterSubtitle),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SproutTextField(
                  identifier: SemanticsIds.wizardDepositNote,
                  controller: _noteController,
                  enabled: !skipDeposit,
                  decoration: const InputDecoration(
                    labelText: AppStrings.note,
                    hintText: AppStrings.optional,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.wizardDepositHint,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

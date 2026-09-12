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

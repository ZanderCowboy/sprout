part of 'wizard_page.dart';

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
        const _HeroIcon(
          icon: Icons.account_balance_wallet_outlined,
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
                    errorMaxLines: 3,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.color,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SproutColorSwatches(
                  selectedArgb: widget.state.accountColorArgb,
                  onSelected: (colorArgb) =>
                      context.read<WizardCubit>().setAccountColor(colorArgb),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

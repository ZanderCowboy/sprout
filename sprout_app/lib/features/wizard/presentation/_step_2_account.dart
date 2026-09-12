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

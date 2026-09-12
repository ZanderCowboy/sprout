part of 'wizard_page.dart';

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

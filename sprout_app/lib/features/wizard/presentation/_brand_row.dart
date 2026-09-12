part of 'wizard_page.dart';

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.onSkip});

  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          AppAssets.sproutIcon.image(
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

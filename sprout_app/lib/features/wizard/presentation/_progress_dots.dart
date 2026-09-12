part of 'wizard_page.dart';

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

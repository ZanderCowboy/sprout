part of 'wizard_page.dart';

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

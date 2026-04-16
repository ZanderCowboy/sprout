import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sprout/core/core.dart';

/// Center nav action: gradient disc, soft glow, gentle breathing scale, haptic tap.
class EnticingAddButton extends StatefulWidget {
  const EnticingAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<EnticingAddButton> createState() => _EnticingAddButtonState();
}

class _EnticingAddButtonState extends State<EnticingAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _breath;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.072).animate(
      CurvedAnimation(parent: _breath, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    const size = 58.0;
    const iconSize = 31.0;

    return Tooltip(
      message: AppStrings.actionAdd,
      child: Semantics(
        button: true,
        label: AppStrings.actionAdd,
        child: ScaleTransition(
          scale: _scale,
          child: SizedBox(
            width: size + 10,
            height: size + 10,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentLime.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.seed.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onTap,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(
                              AppColors.accentLime,
                              Colors.white,
                              0.22,
                            )!,
                            AppColors.accentLime,
                            Color.lerp(
                              AppColors.accentLime,
                              AppColors.seed,
                              0.28,
                            )!,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.surfaceDeep,
                          size: iconSize,
                          shadows: [
                            Shadow(
                              color: Color(0x33FFFFFF),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


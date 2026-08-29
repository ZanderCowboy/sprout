import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'widgets/debug_sign_in_button.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key, required this.onCompleted, this.initialPage = 0});

  final VoidCallback onCompleted;
  final int initialPage;

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  late final PageController _controller;
  int _index = 0;

  static const _slideCount = 3;

  @override
  void initState() {
    super.initState();
    _index = widget.initialPage.clamp(0, _slideCount - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastSlide => _index == _slideCount - 1;

  Future<void> _goNext() async {
    if (_isLastSlide) {
      widget.onCompleted();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.appTitle,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _index = index),
                  children: const [
                    _IntroSlide(
                      icon: Icons.savings_rounded,
                      accent: AppColors.seed,
                      title: 'Track your savings in one place',
                      body:
                          'See your accounts, activity, and totals together so you always know where you stand.',
                    ),
                    _IntroSlide(
                      icon: Icons.flag_rounded,
                      accent: AppColors.accentViolet,
                      title: 'Set goals and watch them grow',
                      body:
                          'Give each goal a target and watch progress build as you save.',
                    ),
                    _IntroSlide(
                      icon: Icons.cloud_sync_rounded,
                      accent: AppColors.accentSky,
                      title: 'Sign in so your data stays with you',
                      body:
                          'Your savings stay with your account, not only on this device.',
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slideCount; i++)
                    _IntroDot(selected: i == _index),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _goNext,
                  child: Text(_isLastSlide ? 'Sign in' : 'Next'),
                ),
              ),
              const SizedBox(height: 12),
              const DebugSignInButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: accent),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroDot extends StatelessWidget {
  const _IntroDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.28);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: selected ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

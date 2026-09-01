import 'package:flutter/material.dart';

import 'package:sprout/core/constants/app_colors.dart';
import 'package:sprout/core/constants/app_strings.dart';
import 'package:sprout/core/constants/semantics_ids.dart';
import 'package:sprout/ui/export.dart';
import 'widgets/debug_sign_in_button.dart';
import 'widgets/intro_dot.dart';
import 'widgets/intro_slide.dart';

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
                    IntroSlide(
                      icon: Icons.savings_rounded,
                      accent: AppColors.seed,
                      title: AppStrings.introSlide1Title,
                      body: AppStrings.introSlide1Body,
                    ),
                    IntroSlide(
                      icon: Icons.flag_rounded,
                      accent: AppColors.accentViolet,
                      title: AppStrings.introSlide2Title,
                      body: AppStrings.introSlide2Body,
                    ),
                    IntroSlide(
                      icon: Icons.cloud_sync_rounded,
                      accent: AppColors.accentSky,
                      title: AppStrings.introSlide3Title,
                      body: AppStrings.introSlide3Body,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slideCount; i++)
                    IntroDot(selected: i == _index),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: SproutFilledButton(
                  identifier: SemanticsIds.introNext,
                  label: _isLastSlide ? AppStrings.signIn : AppStrings.next,
                  onPressed: _goNext,
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

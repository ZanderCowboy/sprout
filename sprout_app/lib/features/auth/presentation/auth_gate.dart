import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/di/service_locator.dart';
import 'package:sprout/core/user/user_context.dart';
import 'package:sprout/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:sprout/features/auth/presentation/intro_page.dart';
import 'package:sprout/features/auth/presentation/sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.userContext,
    this.signedIn = const SizedBox.shrink(),
  });

  final UserContext? userContext;
  final Widget signedIn;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _lastIntroPage = 2;

  late bool _showingIntro;

  UserContext get _userContext => widget.userContext ?? sl<UserContext>();

  @override
  void initState() {
    super.initState();
    _showingIntro = !_userContext.introCompleted;
  }

  void _completeIntro() {
    unawaited(_userContext.markIntroCompleted());
    setState(() => _showingIntro = false);
  }

  void _backToIntro() {
    setState(() => _showingIntro = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthViewState>(
      listener: (context, state) {
        if (state is AuthViewSignedIn && !_userContext.introCompleted) {
          unawaited(_userContext.markIntroCompleted());
        }
      },
      builder: (context, state) {
        return switch (state) {
          AuthViewLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          AuthViewSignedIn() => widget.signedIn,
          AuthViewGuest() =>
            _showingIntro
                ? IntroPage(
                    onCompleted: _completeIntro,
                    initialPage: _userContext.introCompleted
                        ? _lastIntroPage
                        : 0,
                  )
                : SignInPage(onBackToIntro: _backToIntro),
        };
      },
    );
  }
}

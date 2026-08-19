import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/constants/app_strings.dart';
import '../../application/privacy_policy_service.dart';

sealed class PrivacyViewState extends Equatable {
  const PrivacyViewState();

  @override
  List<Object?> get props => [];
}

final class PrivacyViewLoading extends PrivacyViewState {
  const PrivacyViewLoading();
}

final class PrivacyViewReady extends PrivacyViewState {
  const PrivacyViewReady({required this.markdown});

  final String markdown;

  @override
  List<Object?> get props => [markdown];
}

final class PrivacyViewError extends PrivacyViewState {
  const PrivacyViewError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class PrivacyCubit extends Cubit<PrivacyViewState> {
  PrivacyCubit({required PrivacyPolicyService privacyPolicy})
    : _privacyPolicy = privacyPolicy,
      super(const PrivacyViewLoading()) {
    unawaited(load());
  }

  final PrivacyPolicyService _privacyPolicy;

  Future<void> load() async {
    emit(const PrivacyViewLoading());
    try {
      final markdown = await _privacyPolicy.loadMarkdown();
      if (isClosed) return;
      emit(PrivacyViewReady(markdown: markdown));
    } on Object {
      if (isClosed) return;
      emit(const PrivacyViewError(message: AppStrings.privacyLoadFailed));
    }
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sprout/core/constants/app_strings.dart';
import '../../application/terms_of_service_service.dart';

sealed class TermsViewState extends Equatable {
  const TermsViewState();

  @override
  List<Object?> get props => [];
}

final class TermsViewLoading extends TermsViewState {
  const TermsViewLoading();
}

final class TermsViewReady extends TermsViewState {
  const TermsViewReady({required this.markdown});

  final String markdown;

  @override
  List<Object?> get props => [markdown];
}

final class TermsViewError extends TermsViewState {
  const TermsViewError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class TermsCubit extends Cubit<TermsViewState> {
  TermsCubit({required TermsOfServiceService termsOfService})
    : _termsOfService = termsOfService,
      super(const TermsViewLoading()) {
    unawaited(load());
  }

  final TermsOfServiceService _termsOfService;

  Future<void> load() async {
    emit(const TermsViewLoading());
    try {
      final markdown = await _termsOfService.loadMarkdown();
      if (isClosed) return;
      emit(TermsViewReady(markdown: markdown));
    } on Object {
      if (isClosed) return;
      emit(const TermsViewError(message: AppStrings.termsLoadFailed));
    }
  }
}

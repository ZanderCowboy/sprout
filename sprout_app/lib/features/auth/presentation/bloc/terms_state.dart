part of 'terms_cubit.dart';

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

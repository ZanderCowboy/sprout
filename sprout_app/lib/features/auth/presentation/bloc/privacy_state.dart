part of 'privacy_cubit.dart';

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

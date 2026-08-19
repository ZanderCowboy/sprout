import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.isAnonymous,
    this.email,
  });

  final String id;
  final String? email;
  final bool isAnonymous;

  bool get isVerified => !isAnonymous;

  @override
  List<Object?> get props => [id, email, isAnonymous];
}

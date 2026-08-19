import 'package:sprout/core/constants/app_strings.dart';
import '../../domain/auth_user.dart';

String accountTileTitle(AuthUser user) {
  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final email = user.email?.trim();
  if (email != null && email.isNotEmpty) return email;
  return AppStrings.account;
}

String accountTileSubtitle(AuthUser user) {
  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) {
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email;
  }
  return user.signedInWithGoogle
      ? AppStrings.signedInWithGoogle
      : AppStrings.signedInWithEmail;
}

String accountAvatarInitial(AuthUser user) {
  final source = accountTileTitle(user);
  if (source.isEmpty) return 'A';
  return source[0].toUpperCase();
}

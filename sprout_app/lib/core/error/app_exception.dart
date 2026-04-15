import 'failure.dart';

sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  Failure toFailure() => switch (this) {
        NetworkAppException(:final message) => NetworkFailure(message),
        CacheAppException(:final message) => CacheFailure(message),
        AuthAppException(:final message) => AuthFailure(message),
        ValidationAppException(:final message) => ValidationFailure(message),
        ServerAppException(:final message) => ServerFailure(message),
        UnknownAppException(:final message) => UnknownFailure(message),
      };
}

final class NetworkAppException extends AppException {
  const NetworkAppException([super.message = 'Network error']);
}

final class CacheAppException extends AppException {
  const CacheAppException([super.message = 'Local storage error']);
}

final class AuthAppException extends AppException {
  const AuthAppException([super.message = 'Authentication required']);
}

final class ValidationAppException extends AppException {
  const ValidationAppException(super.message);
}

final class ServerAppException extends AppException {
  const ServerAppException([super.message = 'Server error']);
}

final class UnknownAppException extends AppException {
  const UnknownAppException([super.message = 'Something went wrong']);
}

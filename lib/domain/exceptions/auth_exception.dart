sealed class AuthException implements Exception {
  final String message;
  final String code;
  const AuthException(this.code, this.message);
}

final class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('user-not-found', 'User not found');
}

final class WrongPasswordException extends AuthException {
  const WrongPasswordException() : super('wrong-password', 'Wrong password');
}

final class InvalidEmailException extends AuthException {
  const InvalidEmailException() : super('invalid-email', 'Invalid email');
}

final class UserDisabledException extends AuthException {
  const UserDisabledException() : super('user-disabled', 'User disabled');
}

final class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
    : super('email-already-in-use', 'Email already in use');
}

final class WeakPasswordException extends AuthException {
  const WeakPasswordException() : super('weak-password', 'Weak password');
}

final class OperationNotAllowedException extends AuthException {
  const OperationNotAllowedException()
    : super('operation-not-allowed', 'Operation not allowed');
}

final class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
    : super('too-many-requests', 'Too many requests');
}

final class UnknownAuthException extends AuthException {
  const UnknownAuthException(String code) : super(code, 'Unknown auth error');
}

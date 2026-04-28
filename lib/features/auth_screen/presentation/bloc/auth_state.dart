abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSentSuccess extends AuthState {
  final String email;
  AuthOtpSentSuccess({required this.email});
}

class AuthVerifiedSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
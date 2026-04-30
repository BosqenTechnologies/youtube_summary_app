abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSentSuccess extends AuthState {
  final String email;
  final bool isTestEmail; // Tells OTP screen to show the debug hint banner

  AuthOtpSentSuccess({
    required this.email,
    this.isTestEmail = false,
  });
}

class AuthVerifiedSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
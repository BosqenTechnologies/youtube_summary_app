abstract class AuthRepository {
  Future<void> sendOtp({required String email});
  Future<void> verifyOtp({required String email, required String otp});
}
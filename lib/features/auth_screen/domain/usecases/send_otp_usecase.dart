import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;
  SendOtpUseCase(this.repository);

  Future<void> call(String email) async {
    return await repository.sendOtp(email: email);
  }
}
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> sendOtp({required String email}) async {
    await remoteDataSource.sendOtp(email);
  }

  @override
  Future<void> verifyOtp({required String email, required String otp}) async {
    await remoteDataSource.verifyOtp(email, otp);
  }
}
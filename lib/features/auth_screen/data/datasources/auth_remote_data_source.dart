import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String otp);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> sendOtp(String email) async {
    await supabaseClient.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true, // Creates user if they don't exist
    );
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    await supabaseClient.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String otp);
}

// ─────────────────────────────────────────────────────────────────────────────
// HOW THE TEST BYPASS WORKS
//
// Values are injected at BUILD TIME via --dart-define flags.
// They are never hardcoded in source code.
//
// FOR APK (run on your laptop terminal):
//   flutter build apk --debug \
//     --dart-define=ENABLE_TEST_BYPASS=true \
//     --dart-define=TEST_EMAIL_1=pradeep@bosqen.com \
//     --dart-define=TEST_EMAIL_2=lead@bosqen.com \
//     --dart-define=TEST_OTP_PIN=123456
//
// FOR WEB (Vercel reads these from its Environment Variables dashboard):
//   The values are already set in Vercel → Environment Variables → Preview
//   Vercel automatically passes them to the flutter build web command.
//
// FOR PRODUCTION (no flags passed):
//   ENABLE_TEST_BYPASS is empty string → treated as false
//   _isTestBuild = false → bypass is completely inactive
//   Real users go through normal Supabase OTP flow always.
// ─────────────────────────────────────────────────────────────────────────────

// This is false by default. Only becomes true when
// --dart-define=ENABLE_TEST_BYPASS=true is passed at build time.
const bool _isTestBuild = bool.fromEnvironment('ENABLE_TEST_BYPASS');

// These are empty strings by default.
const String _testEmail1 = String.fromEnvironment('TEST_EMAIL_1');
const String _testEmail2 = String.fromEnvironment('TEST_EMAIL_2');
const String _testEmail3 = String.fromEnvironment('TEST_EMAIL_3');
const String _testEmail4 = String.fromEnvironment('TEST_EMAIL_4');
const String _testOtpPin = String.fromEnvironment('TEST_OTP_PIN');

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  bool _isTestEmail(String email) {
    if (!_isTestBuild) return false;

    final emailLower = email.toLowerCase().trim();
    final testEmails = <String>{
      _testEmail1,
      _testEmail2,
      _testEmail3,
      _testEmail4,
    }.where((e) => e.isNotEmpty).map((e) => e.toLowerCase()).toSet();

    if (testEmails.isEmpty) return false;
    return testEmails.contains(emailLower);
  }

  bool _isTestOtp(String otp) {
    if (!_isTestBuild) return false;
    if (_testOtpPin.isEmpty) return false;
    return otp.trim() == _testOtpPin.trim();
  }

  @override
  Future<void> sendOtp(String email) async {
    // TEST BYPASS — APK debug build OR Vercel Preview build
    if (_isTestEmail(email)) {
      await Future.delayed(const Duration(milliseconds: 400));
      return; // No email sent, no Supabase call
    }

    // PRODUCTION PATH — all real users
    await supabaseClient.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    // TEST BYPASS
    if (_isTestEmail(email)) {
      if (!_isTestOtp(otp)) {
        throw AuthException('Token has expired or is invalid');
      }

      try {
        await supabaseClient.auth.signInWithPassword(
          email: email,
          password: _testOtpPin,
        );
        return;
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('invalid') ||
            e.message.toLowerCase().contains('credentials') ||
            e.message.toLowerCase().contains('not found')) {
          await supabaseClient.auth.signUp(
            email: email,
            password: _testOtpPin,
          );
          await supabaseClient.auth.signInWithPassword(
            email: email,
            password: _testOtpPin,
          );
          return;
        }
        rethrow;
      }
    }

    // PRODUCTION PATH
    await supabaseClient.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
  }
}
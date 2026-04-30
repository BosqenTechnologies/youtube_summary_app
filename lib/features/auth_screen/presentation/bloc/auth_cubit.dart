import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:youtube_summary_app/core/error/auth_error_mapper.dart';

import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_state.dart';

// ── Dart-define test email detection (mirrors data source) ──────────────────
// These are only populated when --dart-define flags are passed at build time.
// Empty strings in production release builds.
const String _dartDefineEmail1 = String.fromEnvironment('TEST_EMAIL_1');
const String _dartDefineEmail2 = String.fromEnvironment('TEST_EMAIL_2');
const String _dartDefineEmail3 = String.fromEnvironment('TEST_EMAIL_3');
const String _dartDefineEmail4 = String.fromEnvironment('TEST_EMAIL_4');

class AuthCubit extends Cubit<AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  AuthCubit({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
  }) : super(AuthInitial());

  /// Returns true only in debug builds for configured test emails
  bool _isDebugTestEmail(String email) {
    if (!kDebugMode) return false;
    final emailLower = email.toLowerCase().trim();
    final testEmails = {
      _dartDefineEmail1.toLowerCase(),
      _dartDefineEmail2.toLowerCase(),
      _dartDefineEmail3.toLowerCase(),
      _dartDefineEmail4.toLowerCase(),
    }.where((e) => e.isNotEmpty).toSet();
    return testEmails.contains(emailLower);
  }

  Future<void> sendOtp(String email) async {
    emit(AuthLoading());
    try {
      await sendOtpUseCase.call(email);
      emit(AuthOtpSentSuccess(
        email: email,
        isTestEmail: _isDebugTestEmail(email), // Only true in debug mode
      ));
    } on AuthException catch (e) {
      emit(AuthError(message: AuthErrorMapper.map(e.message)));
    } catch (e) {
      emit(AuthError(message: AuthErrorMapper.map(e.toString())));
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    emit(AuthLoading());
    try {
      await verifyOtpUseCase.call(email, otp);
      emit(AuthVerifiedSuccess());
    } on AuthException catch (e) {
      emit(AuthError(message: AuthErrorMapper.map(e.message)));
    } catch (e) {
      emit(AuthError(message: AuthErrorMapper.map(e.toString())));
    }
  }
}
import 'package:flutter_bloc/flutter_bloc.dart';
// 🔥 FIX: Hide Supabase's AuthState to avoid collision with your custom AuthState
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
// Import your custom state normally
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  AuthCubit({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
  }) : super(AuthInitial());

  Future<void> sendOtp(String email) async {
    emit(AuthLoading());
    try {
      await sendOtpUseCase.call(email);
      emit(AuthOtpSentSuccess(email: email));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Failed to send OTP. Please try again.'));
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    emit(AuthLoading());
    try {
      await verifyOtpUseCase.call(email, otp);
      emit(AuthVerifiedSuccess());
    } on AuthException catch (e) {
      // Specifically handle invalid OTP from Supabase
      if (e.message.toLowerCase().contains('invalid') || e.message.toLowerCase().contains('expired')) {
        emit(AuthError(message: 'Invalid OTP. Please try again.'));
      } else {
        emit(AuthError(message: e.message));
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to verify OTP.'));
    }
  }
}
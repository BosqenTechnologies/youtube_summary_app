import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

// How long (in seconds) until OTP is considered expired in the UI.
// Should match the OTP expiry you set in Supabase Dashboard →
// Authentication → Policies → OTP Expiry
const int _otpExpirySeconds = 60;

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isTestEmail;

  const OtpScreen({
    super.key,
    required this.email,
    this.isTestEmail = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  // ── Timer State ─────────────────────────────────────────────────────────────
  Timer? _countdownTimer;
  int _secondsRemaining = _otpExpirySeconds;
  bool get _isOtpExpired => _secondsRemaining <= 0;
  bool get _canResend => _isOtpExpired;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = _otpExpirySeconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _verifyOtp() {
    final otp = _otpController.text.trim();

    // Client-side validation
    if (otp.isEmpty) {
      _showError('Please enter the 6-digit code sent to your email.');
      return;
    }
    if (otp.length != 6) {
      _showError('The code must be exactly 6 digits. Please check and try again.');
      return;
    }
    if (_isOtpExpired && !widget.isTestEmail) {
      _showError('This code has expired. Please request a new one using the button below.');
      return;
    }

    context.read<AuthCubit>().verifyOtp(widget.email, otp);
  }

  void _resendOtp() {
    if (!_canResend) return;
    _otpController.clear();
    context.read<AuthCubit>().sendOtp(widget.email);
    _startCountdown(); // Restart the timer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new code has been sent to your email.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── UI Helpers ───────────────────────────────────────────────────────────────

  String get _timerDisplay {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    if (mins > 0) {
      return '${mins}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }

  Color _timerColor(Color primaryColor) {
    if (_secondsRemaining > 30) return primaryColor;
    if (_secondsRemaining > 10) return Colors.orange;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor =
        isDark ? AppColors.primaryRedDark : AppColors.primaryRedLight;
    final primaryText =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondaryText =
        isDark ? AppColors.darkSecondaryTonal : AppColors.lightSecondaryTonal;
    final inputFill = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.lightSurfaceContainerLow;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showError(state.message); // Already mapped to user-readable text
        } else if (state is AuthVerifiedSuccess) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
        // Re-trigger countdown when new OTP is sent (resend flow)
        else if (state is AuthOtpSentSuccess) {
          _startCountdown();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Title ──────────────────────────────────────────────────
                Text(
                  AppStrings.otpScreenTitle,
                  style: TextStyle(
                    fontSize: AppDimensions.fontTitleLarge,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),

                // ── Subtitle ───────────────────────────────────────────────
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal,
                      color: secondaryText,
                    ),
                    children: [
                      const TextSpan(text: AppStrings.otpScreenSubtitle),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Debug Test Email Hint Banner (debug builds only) ────────
                if (widget.isTestEmail) ...[
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusNormal),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.science_outlined,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🧪 Debug Test Account',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppDimensions.fontNormal,
                                ),
                              ),
                              Text(
                                'Use the TEST_OTP_PIN from your --dart-define flags.',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: AppDimensions.fontTiny,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.spacingHuge),

                // ── OTP Input Field ────────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Field label with timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.otpLabel,
                              style: TextStyle(
                                fontSize: AppDimensions.fontTiny,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: secondaryText,
                              ),
                            ),
                            // ── Countdown Timer ───────────────────────────
                            if (!widget.isTestEmail)
                              _isOtpExpired
                                  ? Text(
                                      'Code expired',
                                      style: TextStyle(
                                        fontSize: AppDimensions.fontTiny,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.errorRed,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 12,
                                          color: _timerColor(primaryColor),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _timerDisplay,
                                          style: TextStyle(
                                            fontSize: AppDimensions.fontTiny,
                                            fontWeight: FontWeight.bold,
                                            color: _timerColor(primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),

                        // OTP TextField
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          enabled: !_isOtpExpired || widget.isTestEmail,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: TextStyle(
                            fontSize: AppDimensions.fontTitleMedium,
                            letterSpacing: 12.0,
                            fontWeight: FontWeight.bold,
                            color: (_isOtpExpired && !widget.isTestEmail)
                                ? secondaryText.withValues(alpha: 0.4)
                                : primaryText,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: AppStrings.otpHint,
                            hintStyle: TextStyle(
                              letterSpacing: 12.0,
                              color: secondaryText.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.paddingMedium,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusNormal),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusNormal),
                              borderSide: _isOtpExpired && !widget.isTestEmail
                                  ? BorderSide(
                                      color: AppColors.errorRed.withValues(alpha: 0.5),
                                      width: AppDimensions.borderWidth,
                                    )
                                  : BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusNormal),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: AppDimensions.borderWidth,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusNormal),
                              borderSide: BorderSide(
                                color: AppColors.errorRed.withValues(alpha: 0.4),
                                width: AppDimensions.borderWidth,
                              ),
                            ),
                          ),
                        ),

                        // ── Expired Warning Message ──────────────────────
                        if (_isOtpExpired && !widget.isTestEmail) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 14, color: AppColors.errorRed),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'This code has expired. Request a new one below.',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontTiny,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXLarge),

                // ── Verify Button ──────────────────────────────────────────
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    // Disable verify button if OTP expired (except test emails)
                    final isDisabled =
                        isLoading || (_isOtpExpired && !widget.isTestEmail);

                    return SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isDisabled ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: AppColors.textLight,
                          disabledBackgroundColor:
                              primaryColor.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusNormal),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: AppDimensions.progressIndicatorSize,
                                width: AppDimensions.progressIndicatorSize,
                                child: CircularProgressIndicator(
                                  color: AppColors.textLight,
                                  strokeWidth:
                                      AppDimensions.progressIndicatorStroke,
                                ),
                              )
                            : Text(
                                AppStrings.verifyOtp,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontButton,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.spacingLarge),

                // ── Resend Button ──────────────────────────────────────────
                // Only shown for real users (not test email accounts)
                if (!widget.isTestEmail)
                  Column(
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: TextStyle(
                          fontSize: AppDimensions.fontNormal,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _canResend ? _resendOtp : null,
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          disabledForegroundColor:
                              secondaryText.withValues(alpha: 0.5),
                        ),
                        child: Text(
                          _canResend
                              ? AppStrings.resendOtp
                              : 'Resend code in $_timerDisplay',
                          style: TextStyle(
                            color: _canResend
                                ? primaryColor
                                : secondaryText.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: AppDimensions.fontNormal,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: AppDimensions.spacingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
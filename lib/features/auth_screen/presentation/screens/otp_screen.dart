import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';// Ensure correct import path

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 6-digit code.'),
          backgroundColor: AppColors.errorRed, // Fixed color
        ),
      );
      return;
    }
    context.read<AuthCubit>().verifyOtp(widget.email, otp);
  }

  void _resendOtp() {
    context.read<AuthCubit>().sendOtp(widget.email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.otpSentSuccess)),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- 4-Color System Setup ---
    final primaryColor = isDark ? AppColors.primaryRedDark : AppColors.primaryRedLight;
    final primaryText = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondaryText = isDark ? AppColors.darkSecondaryTonal : AppColors.lightSecondaryTonal;
    final inputFill = isDark ? AppColors.darkSurfaceContainerLow : AppColors.lightSurfaceContainerLow;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        } else if (state is AuthVerifiedSuccess) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryText), // Primary Text
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
                Text(
                  AppStrings.otpScreenTitle,
                  style: TextStyle(
                    fontSize: AppDimensions.fontTitleLarge,
                    fontWeight: FontWeight.bold,
                    color: primaryText, // Primary Text
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal,
                      color: secondaryText, // Secondary Text
                    ),
                    children: [
                      const TextSpan(text: AppStrings.otpScreenSubtitle),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryText, // Primary Text
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingHuge),
                
                // ✨ FIX: Wrap the OTP Field in a constrained layout so it isn't massive
                Center(
                  child: SizedBox(
                    width: 260, // Constrains the width for a tidy, boxed look
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.otpLabel,
                          style: TextStyle(
                            fontSize: AppDimensions.fontTiny,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: secondaryText, // Secondary Text
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(
                            fontSize: AppDimensions.fontTitleMedium,
                            letterSpacing: 12.0, // Increased spacing for cleaner look
                            fontWeight: FontWeight.bold,
                            color: primaryText, // Primary Text
                          ),
                          decoration: InputDecoration(
                            counterText: "",
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
                              borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: AppDimensions.borderWidth,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppDimensions.spacingXLarge),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: AppColors.textLight, // ✨ FIX: White text on red
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: AppDimensions.progressIndicatorSize,
                                width: AppDimensions.progressIndicatorSize,
                                child: CircularProgressIndicator(
                                  color: AppColors.textLight,
                                  strokeWidth: AppDimensions.progressIndicatorStroke,
                                ),
                              )
                            : const Text(
                                AppStrings.verifyOtp,
                                style: TextStyle(
                                  fontSize: AppDimensions.fontButton,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight, // Explicitly white
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                TextButton(
                  onPressed: _resendOtp,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor, // Adds correct splash color
                  ),
                  child: Text(
                    AppStrings.resendOtp,
                    style: TextStyle(
                      color: primaryColor, // Brand color
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.fontNormal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
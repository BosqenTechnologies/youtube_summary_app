import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';
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
          backgroundColor: Theme.of(context).colorScheme.error,
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

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        } else if (state is AuthVerifiedSuccess) {
          // Navigation is handled automatically by AuthGate listening to Supabase session!
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal,
                      color: theme.textTheme.bodyMedium?.color ??
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    children: [
                      const TextSpan(text: AppStrings.otpScreenSubtitle),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingHuge),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.otpLabel,
                    style: TextStyle(
                      fontSize: AppDimensions.fontTiny,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: theme.textTheme.labelSmall?.color ??
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
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
                    letterSpacing: 8.0,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color ??
                        theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    counterText: "", // Hides the '0/6' character counter
                    hintText: AppStrings.otpHint,
                    hintStyle: TextStyle(
                      letterSpacing: 8.0,
                      color: theme.inputDecorationTheme.hintStyle?.color ??
                          theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingMedium),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusNormal),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusNormal),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: AppDimensions.borderWidth),
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
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusNormal),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: AppDimensions.progressIndicatorSize,
                                width: AppDimensions.progressIndicatorSize,
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.onPrimary,
                                  strokeWidth:
                                      AppDimensions.progressIndicatorStroke,
                                ),
                              )
                            : const Text(
                                AppStrings.verifyOtp,
                                style: TextStyle(
                                  fontSize: AppDimensions.fontButton,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    AppStrings.resendOtp,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final bool _isSignUp = false;

  void _submitEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address (e.g. name@example.com).');
      return;
    }

    context.read<AuthCubit>().sendOtp(email);
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
          // Error message is already user-readable (mapped in AuthCubit)
          _showError(state.message);
        } else if (state is AuthOtpSentSuccess) {
          final authCubit = context.read<AuthCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: authCubit,
                child: OtpScreen(
                  email: state.email,
                  isTestEmail: state.isTestEmail, // Pass debug flag to OTP screen
                ),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppStrings.appName,
            style: TextStyle(
              color: primaryColor,
              fontSize: AppDimensions.fontTitleMedium,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isSignUp) ...[
                  Text(
                    AppStrings.createAccount,
                    style: TextStyle(
                      fontSize: AppDimensions.fontTitleLarge,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  Text(
                    AppStrings.joinRevolution,
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal,
                      color: secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Text(
                    AppStrings.welcomeBack,
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal,
                      color: secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppDimensions.spacingHuge),
                Text(
                  AppStrings.emailLabel,
                  style: TextStyle(
                    fontSize: AppDimensions.fontTiny,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSmall),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitEmail(),
                  style: TextStyle(
                    fontSize: AppDimensions.fontNormal,
                    color: primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.emailHint,
                    hintStyle: TextStyle(
                      color: secondaryText.withValues(alpha: 0.6),
                      fontSize: AppDimensions.fontNormal,
                    ),
                    prefixIcon:
                        Icon(Icons.email_outlined, color: secondaryText),
                    filled: true,
                    fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingNormal),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusNormal),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusNormal),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusNormal),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: AppDimensions.borderWidth,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXLarge),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: AppColors.textLight,
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
                            : const Text(
                                AppStrings.signIn,
                                style: TextStyle(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
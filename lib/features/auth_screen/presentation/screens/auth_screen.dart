import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  bool _isSignUp = false;

  void _submitEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    context.read<AuthCubit>().sendOtp(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
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
        } else if (state is AuthOtpSentSuccess) {
          
          // 🔥 FIX: Grab the existing cubit before navigating
          final authCubit = context.read<AuthCubit>();
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                // 🔥 FIX: Pass the existing cubit to the new OtpScreen route
                value: authCubit, 
                child: OtpScreen(email: state.email),
              ),
            ),
          );
          
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppStrings.appName,
            style: TextStyle(
              color: theme.colorScheme.primary,
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
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  Text(
                    AppStrings.joinRevolution,
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal,
                      color: theme.textTheme.bodyMedium?.color ??
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const SizedBox(height: AppDimensions.spacingMedium),
                  Text(
                    AppStrings.welcomeBack,
                    style: TextStyle(
                      fontSize: AppDimensions.fontNormal,
                      color: theme.textTheme.bodyMedium?.color ??
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                    color: theme.textTheme.labelSmall?.color ??
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSmall),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: AppDimensions.fontNormal,
                    color: theme.textTheme.bodyMedium?.color ??
                        theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.emailHint,
                    hintStyle: TextStyle(
                        color: theme.inputDecorationTheme.hintStyle?.color ??
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: AppDimensions.fontNormal),
                    prefixIcon: Icon(Icons.email_outlined,
                        color: theme.iconTheme.color ??
                            theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.surfaceContainerHighest,
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
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitEmail,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppStrings.signIn,
                                    style: const TextStyle(
                                      fontSize: AppDimensions.fontButton,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingLarge),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text(
                //       _isSignUp
                //           ? AppStrings.alreadyHaveAccount
                //           : AppStrings.needAccount,
                //       style: TextStyle(
                //           color: theme.textTheme.bodySmall?.color ??
                //               theme.colorScheme.onSurface.withValues(alpha: 0.7),
                //           fontSize: AppDimensions.fontSmall),
                //     ),
                //     GestureDetector(
                //       onTap: () {
                //         setState(() {
                //           _isSignUp = !_isSignUp;
                //         });
                //       },
                //       child: Text(
                //         _isSignUp ? AppStrings.signIn : AppStrings.signUp,
                //         style: TextStyle(
                //           color: theme.colorScheme.primary,
                //           fontWeight: FontWeight.bold,
                //           fontSize: AppDimensions.fontSmall,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
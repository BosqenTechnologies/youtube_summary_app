import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'package:youtube_summary_app/core/constants/app_strings.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false; 
  bool _obscurePassword = true; 

  final supabase = Supabase.instance.client;

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        await supabase.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.accountCreatedSuccess)),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        // 🔥 NEW: Check if error is because email already exists during sign up
        String errorMessage = error.message;
        if (_isSignUp && (errorMessage.toLowerCase().contains('already') || errorMessage.toLowerCase().contains('registered'))) {
          errorMessage = 'This email ID already exists. Please sign in instead.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.errorRed),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppStrings.unexpectedError),
              backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isSignUp 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
                onPressed: () {
                  setState(() {
                    _isSignUp = false;
                  });
                },
              )
            : null,
        centerTitle: true,
        title: const Text(
          AppStrings.appName,
          style: TextStyle(
            color: AppColors.primaryRed,
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
            vertical: AppDimensions.paddingLarge
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isSignUp) ...[
                const Text(
                  AppStrings.createAccount,
                  style: TextStyle(
                    fontSize: AppDimensions.fontTitleLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingSmall),
                const Text(
                  AppStrings.joinRevolution,
                  style: TextStyle(
                    fontSize: AppDimensions.fontNormal,
                    color: AppColors.textSubtext,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const SizedBox(height: AppDimensions.spacingMedium),
                const Text(
                  AppStrings.welcomeBack,
                  style: TextStyle(
                    fontSize: AppDimensions.fontNormal,
                    color: AppColors.textSubtext,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppDimensions.spacingHuge),

              _buildInputLabel(AppStrings.emailLabel),
              const SizedBox(height: AppDimensions.spacingSmall),
              _buildTextField(
                controller: _emailController,
                hintText: AppStrings.emailHint,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppDimensions.spacingLarge),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel(AppStrings.passwordLabel),
                  if (!_isSignUp)
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        AppStrings.forgotPassword,
                        style: TextStyle(
                          fontSize: AppDimensions.fontTiny,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              _buildTextField(
                controller: _passwordController,
                hintText: AppStrings.passwordHint,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                isPassword: true,
              ),
              
              if (_isSignUp) ...[
                const SizedBox(height: AppDimensions.spacingSmall),
                const Text(
                  AppStrings.passwordConstraint,
                  style: TextStyle(
                    fontSize: AppDimensions.fontTiny, 
                    color: AppColors.textSubtext
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.spacingXLarge),

              SizedBox(
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: AppDimensions.progressIndicatorSize,
                          width: AppDimensions.progressIndicatorSize,
                          child: CircularProgressIndicator(
                            color: AppColors.textLight,
                            strokeWidth: AppDimensions.progressIndicatorStroke,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? AppStrings.createAccount : AppStrings.signIn,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontButton,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(width: AppDimensions.spacingSmall),
                              const Icon(Icons.arrow_forward),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLarge),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? AppStrings.alreadyHaveAccount : AppStrings.needAccount,
                    style: const TextStyle(
                      color: AppColors.textSubtext, 
                      fontSize: AppDimensions.fontSmall
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(
                      _isSignUp ? AppStrings.signIn : AppStrings.signUp,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: AppDimensions.fontSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppDimensions.fontTiny,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: AppColors.textLabel,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: AppDimensions.fontNormal, 
        color: AppColors.textDark
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.inputHintColor, 
          fontSize: AppDimensions.fontNormal
        ),
        prefixIcon: Icon(prefixIcon, color: AppColors.inputIconColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.inputIconColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingNormal
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
          borderSide: const BorderSide(
            color: AppColors.primaryRed, 
            width: AppDimensions.borderWidth
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Colors now come from ThemeData to keep UI adaptive across light/dark modes
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
          SnackBar(content: Text(errorMessage), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text(AppStrings.unexpectedError),
              backgroundColor: Theme.of(context).colorScheme.error),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isSignUp 
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                onPressed: () {
                  setState(() {
                    _isSignUp = false;
                  });
                },
              )
            : null,
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
            vertical: AppDimensions.paddingLarge
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
                    color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const SizedBox(height: AppDimensions.spacingMedium),
                Text(
                  AppStrings.welcomeBack,
                  style: TextStyle(
                    fontSize: AppDimensions.fontNormal,
                    color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                          child: Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(
                              fontSize: AppDimensions.fontTiny,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
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
                Text(
                  AppStrings.passwordConstraint,
                  style: TextStyle(
                    fontSize: AppDimensions.fontTiny, 
                    color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.spacingXLarge),

              SizedBox(
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: AppDimensions.progressIndicatorSize,
                          width: AppDimensions.progressIndicatorSize,
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onPrimary,
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
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7), 
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
                      style: TextStyle(
                        color: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: AppDimensions.fontTiny,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: theme.textTheme.labelSmall?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: AppDimensions.fontNormal, 
        color: theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.inputDecorationTheme.hintStyle?.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6), 
          fontSize: AppDimensions.fontNormal
        ),
        prefixIcon: Icon(prefixIcon, color: theme.iconTheme.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.iconTheme.color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHighest,
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
          borderSide: BorderSide(
            color: theme.colorScheme.primary, 
            width: AppDimensions.borderWidth
          ),
        ),
      ),
    );
  }
}
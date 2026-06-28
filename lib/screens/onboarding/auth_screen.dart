// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show ImageFilter;
import '../../app_theme.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/error_helper.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/social_auth_buttons.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final result = await AuthService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (result.success) {
          await context.read<UserProvider>().loadUser();
          if (!mounted) return;
          
          final role = context.read<UserProvider>().user?.userRole;
          if (role == null || role.isEmpty || role == 'unset') {
            Navigator.pushReplacementNamed(context, '/role-selection');
          } else {
            Navigator.pushReplacementNamed(context, '/welcome');
          }
        } else {
          ErrorHelper.showError(context, result.error ?? 'Authentication failed');
        }
      } else {
        // Sign-up
        final result = await AuthService.instance.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          userRole: '', // Role is not set in Step 1
        );

        if (!mounted) return;

        if (result.success) {
          await context.read<UserProvider>().loadUser();
          if (!mounted) return;
          // Transition directly to role selection since role is empty
          Navigator.pushReplacementNamed(context, '/role-selection');
        } else if (result.emailVerificationRequired) {
          ErrorHelper.showSuccess(context, 'Verification sent! Please check your email.');
          _toggleMode();
        } else {
          ErrorHelper.showError(context, result.error ?? 'Registration failed');
        }
      }
    } catch (e) {
      if (mounted) ErrorHelper.showError(context, 'Exception: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;

      if (result.success) {
        await context.read<UserProvider>().loadUser();
        if (!mounted) return;
        
        final user = context.read<UserProvider>().user;
        if (user == null || user.userRole.isEmpty || user.userRole == 'unset') {
          // New user -> transition to Step 2
          Navigator.pushReplacementNamed(context, '/role-selection');
        } else {
          // Existing user with role -> welcome
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      } else if (result.error == 'Redirecting to Google...') {
        return;
      } else {
        ErrorHelper.showError(context, result.error ?? 'Google Sign-In failed');
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showError(context, 'Exception: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (BuildContext context) {
        int currentStep = 1;
        bool dialogLoading = false;
        String resetEmail = '';
        String resetToken = '';
        bool obscureNewPassword = true;

        final emailResetController = TextEditingController(text: _emailController.text);
        final codeResetController = TextEditingController();
        final newPasswordController = TextEditingController();

        final requestFormKey = GlobalKey<FormState>();
        final verifyFormKey = GlobalKey<FormState>();
        final resetFormKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildStepContent() {
              if (currentStep == 1) {
                return Form(
                  key: requestFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Forgot Password',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your email address and we will send you a 6-digit verification code to reset your password.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: emailResetController,
                        hint: 'Email Address',
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: dialogLoading ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: dialogLoading
                                  ? null
                                  : () async {
                                      if (!requestFormKey.currentState!.validate()) return;
                                      setState(() => dialogLoading = true);
                                      final res = await AuthService.instance.sendResetPasswordEmail(
                                        email: emailResetController.text.trim(),
                                      );
                                      setState(() => dialogLoading = false);
                                      if (res.success) {
                                        resetEmail = emailResetController.text.trim();
                                        setState(() => currentStep = 2);
                                        if (context.mounted) {
                                          ErrorHelper.showSuccess(context, 'Reset code sent to your email.');
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ErrorHelper.showError(context, res.error ?? 'Failed to send reset code');
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2E93),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: dialogLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Send Code',
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              } else if (currentStep == 2) {
                return Form(
                  key: verifyFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Verify OTP Code',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We have sent a 6-digit code to $resetEmail. Please enter it below to verify.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: codeResetController,
                        hint: '6-digit Code',
                        icon: Icons.security,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Code required';
                          if (v.trim().length < 6) return 'Enter full code';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: dialogLoading ? null : () => setState(() => currentStep = 1),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Back',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: dialogLoading
                                  ? null
                                  : () async {
                                      if (!verifyFormKey.currentState!.validate()) return;
                                      setState(() => dialogLoading = true);
                                      final res = await AuthService.instance.exchangeResetPasswordToken(
                                        email: resetEmail,
                                        code: codeResetController.text.trim(),
                                      );
                                      setState(() => dialogLoading = false);
                                      if (res.isSuccess) {
                                        resetToken = res.data!;
                                        setState(() => currentStep = 3);
                                        if (context.mounted) {
                                          ErrorHelper.showSuccess(context, 'Code verified successfully.');
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ErrorHelper.showError(context, res.error ?? 'Invalid code');
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2E93),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: dialogLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Verify',
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: dialogLoading
                            ? null
                            : () async {
                                setState(() => dialogLoading = true);
                                final res = await AuthService.instance.sendResetPasswordEmail(
                                  email: resetEmail,
                                );
                                setState(() => dialogLoading = false);
                                if (res.success) {
                                  if (context.mounted) {
                                    ErrorHelper.showSuccess(context, 'Reset code resent successfully.');
                                  }
                                } else {
                                  if (context.mounted) {
                                    ErrorHelper.showError(context, res.error ?? 'Failed to resend code');
                                  }
                                }
                              },
                        child: Text(
                          'Resend Code',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF2E93).withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Form(
                  key: resetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Reset Password',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please enter your new secure password.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: newPasswordController,
                        hint: 'New Password',
                        icon: Icons.lock_outline,
                        obscureText: obscureNewPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: dialogLoading ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: dialogLoading
                                  ? null
                                  : () async {
                                      if (!resetFormKey.currentState!.validate()) return;
                                      setState(() => dialogLoading = true);
                                      final res = await AuthService.instance.resetPassword(
                                        newPassword: newPasswordController.text.trim(),
                                        token: resetToken,
                                      );
                                      setState(() => dialogLoading = false);
                                      if (res.success) {
                                        if (context.mounted) {
                                          ErrorHelper.showSuccess(context, 'Password reset successfully. Please log in.');
                                          Navigator.of(context).pop();
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ErrorHelper.showError(context, res.error ?? 'Failed to reset password');
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2E93),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: dialogLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Reset',
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                borderRadius: 24,
                blur: 15,
                backgroundColor: const Color(0xFF0F0B1E).withValues(alpha: 0.7),
                borderColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(28),
                child: buildStepContent(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Stack(
          children: [
            // Ambient Glows
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x40D4A5FF), Colors.transparent],
                  ),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  duration: 4.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x30FF6B6B), Colors.transparent],
                  ),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  duration: 3.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2E93).withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ]),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 800.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 24),
                      Text(
                        _isLogin ? 'Welcome Back, Mama' : 'Begin Your Motherhood Journey',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .moveY(begin: 10, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? 'Sign in to your sacred space'
                            : 'Start your beautiful journey with us',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 48),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (!_isLogin) ...[
                                    _buildTextField(
                                      controller: _nameController,
                                      hint: 'What should we call you?',
                                      icon: Icons.person_outline,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Name required' : null,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'Email Address',
                                    icon: Icons.alternate_email,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v!.isEmpty) return 'Email required';
                                      if (!v.contains('@')) {
                                        return 'Invalid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.white60,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (v) {
                                      if (_isLogin) {
                                        return v!.isEmpty ? 'Password required' : null;
                                      }
                                      return v!.length < 6 ? 'Min 6 characters' : null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isLogin) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFFF2E93).withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ] else ...[
                                    const SizedBox(height: 24),
                                  ],
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF2E93),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 8,
                                        shadowColor:
                                            const Color(0xFFFF2E93).withValues(alpha: 0.5),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 3),
                                            )
                                          : Text(
                                              'Continue',
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          'OR',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white60,
                                              fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2))),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SocialAuthButtons(
                                    onGoogleSignIn: _handleGoogleSignIn,
                                    onAppleSignIn: () async {
                                      // Handled similarly if needed
                                    },
                                    isLoading: _isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .moveY(begin: 20, end: 0),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _isLoading ? null : _toggleMode,
                        child: Text(
                          _isLogin
                              ? "Don't have an account? Sign Up"
                              : "Already have an account? Log In",
                          style: GoogleFonts.outfit(
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: const Color(0xFFFF2E93).withValues(alpha: 0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: MaaColors.error.withValues(alpha: 0.8), width: 1),
        ),
      ),
      validator: validator,
    );
  }
}

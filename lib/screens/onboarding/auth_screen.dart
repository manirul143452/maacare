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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

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
      AuthResult result;
      
      if (_isLogin) {
        result = await AuthService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        result = await AuthService.instance.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        );
      }

      if (!mounted) return;

      if (result.success) {
        // Load user data
        await context.read<UserProvider>().loadUser();
        if (!mounted) return;
        
        if (_isLogin) {
          // Login: go directly to home (skip onboarding)
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Signup: go to onboarding for new users
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else if (result.emailVerificationRequired) {
        ErrorHelper.showSuccess(context, 'Verification sent! Please check your email.');
        _toggleMode();
      } else {
        ErrorHelper.showError(context, result.error ?? 'Authentication failed');
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: MaaColors.pink.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ]
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      _isLogin ? 'Welcome Back, Mama' : 'Join the Sisterhood',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _isLogin ? 'Sign in to your sacred space' : 'Start your beautiful journey with us',
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
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                                    validator: (v) => v!.isEmpty ? 'Name required' : null,
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
                                    if (!v.contains('@')) return 'Invalid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                                ),
                                
                                const SizedBox(height: 32),
                                
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MaaColors.pink,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor: MaaColors.pink.withOpacity(0.5),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                          )
                                        : Text(
                                            _isLogin ? 'Sign In' : 'Create Account',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In",
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
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
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
          borderSide: BorderSide(color: MaaColors.pink.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MaaColors.error.withOpacity(0.8), width: 1),
        ),
      ),
      validator: validator,
    );
  }
}

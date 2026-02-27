// ============================================================
//  AuthScreen – MaaCare Premium Dark Authentication
//  Cinematic, mysterious, and high-fidelity entry
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/insforge_service.dart';
import '../../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
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
      bool success;
      if (_isLogin) {
        success = await InsForgeService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        success = await InsForgeService.instance.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );
      }

      if (success && mounted) {
        // Load the user profile into the provider
        await context.read<UserProvider>().loadUser();
        
        if (mounted) {
          final user = context.read<UserProvider>().user;
          if (user == null) {
            // First time user, go to onboarding
            Navigator.pushReplacementNamed(context, '/onboarding');
          } else {
            // Returning user, go home
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Login failed. Check your credentials.' : 'Signup failed. Email may be in use.'),
            backgroundColor: MaaColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      body: Stack(
        children: [
          // Cinematic Background
          const ParticleBackgroundView(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Hook
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MaaColors.pink.withAlpha(20),
                        border: Border.all(color: MaaColors.pink.withAlpha(50)),
                      ),
                      child: const Text('🤱', style: TextStyle(fontSize: 60)),
                    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      _isLogin ? 'Welcome Back, Mama' : 'Join the Sisterhood',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: MaaColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                    
                    Text(
                      _isLogin ? 'Sign in to your sacred space' : 'Start your beautiful journey with us',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: MaaColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 40),
                    
                    // Auth Form
                    GlassContainer(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline, size: 20),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Name required' : null,
                              ).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Email Address',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                              ),
                              validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline, size: 20),
                              ),
                              validator: (val) => val == null || val.length < 6 ? 'Min. 6 chars' : null,
                            ).animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: 32),
                            
                            NeonButton(
                              label: _isLogin ? 'Sign In' : 'Create Account',
                              isLoading: _isLoading,
                              onPressed: _submit,
                            ).animate().fadeIn(delay: 400.ms),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Toggle Mode
                    TextButton(
                      onPressed: _toggleMode,
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin ? "Don't have an account? " : "Already a member? ",
                          style: GoogleFonts.poppins(color: MaaColors.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: _isLogin ? "Sign Up" : "Log In",
                              style: const TextStyle(color: MaaColors.pink, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticleBackgroundView extends StatelessWidget {
  const ParticleBackgroundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: MaaColors.darkGradient,
          ),
        ),
        ...List.generate(25, (index) {
          final random = index * 41 % 100;
          final size = 1.0 + (index % 3);
          return Positioned(
            left: (random * 3.6) % MediaQuery.of(context).size.width,
            top: (random * 5.2) % MediaQuery.of(context).size.height,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MaaColors.pink.withAlpha(50),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).moveY(
                begin: 0,
                end: -50,
                duration: Duration(seconds: 5 + (index % 5)),
                curve: Curves.easeInOut,
              );
        }),
      ],
    );
  }
}

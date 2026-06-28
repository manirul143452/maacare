// ============================================================
//  WelcomeScreen – MaaCare Premium Dark
//  Cinematic dark entry with particle effects
// ============================================================

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/maacare_backend_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 10, end: 20).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Navigate based on VALID session after 4 seconds
    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;

      // isLoggedIn now checks token expiry, so this is bulletproof
      if (!MaaCareBackendService.instance.isLoggedIn) {
        // No valid session → go to Login/Signup
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }

      // Valid token exists → check if profile is complete
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUser();

      if (!mounted) return;

      if (userProvider.user != null) {
        final role = userProvider.user!.userRole;
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else if (role == 'unmarried_girl') {
          Navigator.pushReplacementNamed(context, '/period_dashboard');
        } else if (role == 'mother') {
          Navigator.pushReplacementNamed(context, '/mother_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
      } else if (MaaCareBackendService.instance.isLoggedIn) {
        // Logged in (possibly via Google OAuth) but no profile row yet → role selection
        Navigator.pushReplacementNamed(context, '/role-selection');
      } else {
        // Logged in but no profile → go to onboarding (email/password flow)
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: MaaColors.background,
      body: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: MaaColors.darkGradient,
            ),
          ),
          
          // Animated particles
          ...List.generate(30, (index) {
            final random = index * 37 % 100;
            final size = 2.0 + (index % 4);
            return Positioned(
              left: (random * 3.6) % MediaQuery.of(context).size.width,
              top: (random * 5.2) % MediaQuery.of(context).size.height,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index % 3 == 0
                      ? MaaColors.pink.withAlpha(40)
                      : index % 3 == 1
                          ? MaaColors.gold.withAlpha(35)
                          : MaaColors.softPurple.withAlpha(40),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveY(
                  begin: 0,
                  end: -40,
                  duration: Duration(seconds: 4 + (index % 4)),
                  curve: Curves.easeInOut,
                );
          }),
          
          // Radial glow behind main content
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MaaColors.pink.withAlpha(30),
                    MaaColors.softPurple.withAlpha(20),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // Main content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing baby animation container
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MaaColors.pink.withAlpha(100),
                            blurRadius: _pulseAnimation.value,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: MaaColors.softPurple.withAlpha(60),
                            blurRadius: _pulseAnimation.value * 1.5,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: MaaColors.cardDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MaaColors.pink.withAlpha(100),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Lottie.network(
                        'https://lottie.host/6134a6d4-89c0-4286-9f4a-71860d5b6f3a/P1A6j4yNf9.json',
                        width: 150,
                        height: 150,
                        repeat: true,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('👶', style: TextStyle(fontSize: 80));
                        },
                      ),
                    ),
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 40),
                
                // Welcome text with glow
                Text(
                  'हाय मम्मी!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: MaaColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: MaaColors.pink.withAlpha(150),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  'आज तुम्हारा मूड कैसा है?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: MaaColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
                
                const SizedBox(height: 24),
                
                // Animated emojis
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEmoji('😍', 0),
                    _buildEmoji('💕', 100),
                    _buildEmoji('🌸', 200),
                  ],
                ).animate().fadeIn(delay: 800.ms),
                
                const SizedBox(height: 40),
                
                // Points card with glassmorphism
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: MaaColors.glassBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: MaaColors.glassBorder),
                    boxShadow: [
                      BoxShadow(
                        color: MaaColors.gold.withAlpha(40),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: MaaColors.goldGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('⭐', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+10 पॉइंट्स!',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: MaaColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'तू सुपर मॉम है! 💪',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: MaaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1200.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
                
                const SizedBox(height: 30),
                
                // Curiosity teaser
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MaaColors.pink.withAlpha(20),
                        MaaColors.softPurple.withAlpha(20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MaaColors.pink.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔮', style: TextStyle(fontSize: 18))
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 2000.ms, color: MaaColors.pink),
                      const SizedBox(width: 12),
                      Text(
                        'What\'s your baby up to today?',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: MaaColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1500.ms).moveY(begin: 20, end: 0),
              ],
            ),
          ),
          
          // Bottom social proof
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: MaaColors.glassBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MaaColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: MaaColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MaaColors.success.withAlpha(150),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(width: 10),
                    Text(
                      '1,23,456 Mamas online',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: MaaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildEmoji(String emoji, int delayMs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MaaColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaaColors.glassBorder),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -12, duration: 1.seconds, curve: Curves.easeInOut)
        .fadeIn(delay: Duration(milliseconds: delayMs));
  }
}
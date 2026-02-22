// ============================================================
//  SplashScreen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_conditions_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _greeting = 'You are never alone, Mama 💕';
  bool _showGreet = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    final name = prefs.getString('user_name') ?? '';

    if (onboardingDone && name.isNotEmpty) {
      if (mounted) {
        setState(() {
          _greeting = 'Hi $name! Your baby is excited today! ✨';
          _showGreet = true;
        });
      }
    } else {
      await Future.delayed(500.ms);
      if (mounted) setState(() => _showGreet = true);
    }

    await Future.delayed(2500.ms);
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    final legalAccepted = prefs.getBool('legal_accepted') ?? false;

    if (!legalAccepted) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrivacyPolicyScreen(
            showAcceptButton: true,
            onAccept: () async {
              await prefs.setBool('legal_accepted', true);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TermsConditionsScreen(
                    showAcceptButton: true,
                    onAccept: () async {
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, '/onboarding');
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    if (onboardingDone) {
      await userProvider.loadUser();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MaaColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kawaii Logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: MaaColors.white.withAlpha(240),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MaaColors.deepPink.withAlpha(100),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🤱',
                    style: TextStyle(fontSize: 70),
                  ),
                ),
              )
                  .animate()
                  .scale(delay: 200.ms, duration: 800.ms, curve: Curves.elasticOut)
                  .shimmer(delay: 1000.ms, duration: 1500.ms)
                  .shake(hz: 2),
              const SizedBox(height: 32),
              Text(
                'MaaCare',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: MaaColors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .moveY(begin: 20, end: 0, curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              if (_showGreet)
                Text(
                  _greeting,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: MaaColors.white.withAlpha(240),
                        fontWeight: FontWeight.w500,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
              const SizedBox(height: 80),
              // Subtle "Baby Giggle" indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MaaColors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👶', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Magic is loading...',
                      style: TextStyle(
                          color: MaaColors.white.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 2.seconds)
                  .moveY(begin: 0, end: -5, duration: 1.seconds, curve: Curves.easeInOut),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  SplashScreen – MaaCare Premium Dark
//  Cinematic dark splash with particle effects
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../app_theme.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_conditions_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  String _greeting = 'Welcome back, Mama 💕';
  String _curiosityTeaser = 'What\'s your baby up to today?';
  bool _showGreet = false;
  bool _showTeaser = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('MAACARE_DEBUG: SplashScreen.initState');
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    debugPrint('MAACARE_DEBUG: _loadState starting');
    debugPrint('MAACARE_DEBUG: Uri.base is ${Uri.base.toString()}');
    debugPrint('MAACARE_DEBUG: Uri.base.fragment is ${Uri.base.fragment}');
    
    // Initialize Auth Service (SecureStorage, Auto-refresh)
    try {
      await AuthService.instance.initialize().timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('MAACARE_DEBUG: AuthService init timed out after 5s');
      });
      debugPrint('MAACARE_DEBUG: AuthService initialized');

      if (kIsWeb) {
        final uri = Uri.base;
        debugPrint('MAACARE_DEBUG: Checking web URL for OAuth tokens: ${uri.toString()}');
        
        // Check for 'code' or 'insforge_code' in query parameters (PKCE Flow)
        if (uri.queryParameters.containsKey('code') || uri.queryParameters.containsKey('insforge_code')) {
          final code = uri.queryParameters['code'] ?? uri.queryParameters['insforge_code']!;
          debugPrint('MAACARE_DEBUG: Web OAuth code detected, exchanging...');
          final result = await AuthService.instance.exchangeOAuthCodeWeb(code);
          if (result.success) {
            debugPrint('MAACARE_DEBUG: Web OAuth code exchanged successfully');
          } else {
            debugPrint('MAACARE_DEBUG: Web OAuth code exchange failed: ${result.error}');
          }
        } 
        // Check for 'access_token' in fragment or query (Implicit Flow / Supabase Default)
        else {
          String? accessToken;
          String? refreshToken;

          // Supabase appends tokens as fragment (e.g., #access_token=xxx&refresh_token=yyy)
          if (uri.fragment.contains('access_token=')) {
            final uriFragment = Uri.splitQueryString(uri.fragment);
            accessToken = uriFragment['access_token'];
            refreshToken = uriFragment['refresh_token'];
          } else if (uri.queryParameters.containsKey('access_token')) {
            accessToken = uri.queryParameters['access_token'];
            refreshToken = uri.queryParameters['refresh_token'];
          }

          if (accessToken != null) {
            debugPrint('MAACARE_DEBUG: Web OAuth token detected in URL fragment/query, saving session...');
            await AuthService.instance.saveSessionWeb(accessToken, refreshToken: refreshToken);
            // Re-initialize to load the newly saved session
            await AuthService.instance.initialize();
            debugPrint('MAACARE_DEBUG: Session saved and initialized successfully');
          }
        }
      }
    } catch (e) {
      debugPrint('MAACARE_DEBUG: AuthService init error: $e');
    }
    
    // Initialize Notifications
    try {
      await NotificationService.instance.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('MAACARE_DEBUG: NotificationService init timed out after 5s');
        },
      );
    } catch (e) {
      debugPrint('MAACARE_DEBUG: NotificationService init error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    final name = prefs.getString('user_name') ?? '';

    // Curiosity teasers
    final teasers = [
      'What\'s your baby up to today?',
      'Unlock your baby\'s secret development! 🔮',
      'Your daily wellness insight awaits...',
      'How is your little one growing today?',
      'Discover what makes today special 💫',
    ];
    _curiosityTeaser = teasers[DateTime.now().second % teasers.length];

    if (onboardingDone && name.isNotEmpty) {
      if (mounted) {
        setState(() {
          _greeting = 'Welcome back, $name! ✨';
          _showGreet = true;
        });
      }
    } else {
      await Future.delayed(400.ms);
      if (mounted) setState(() => _showGreet = true);
    }

    await Future.delayed(600.ms);
    if (mounted) setState(() => _showTeaser = true);

    await Future.delayed(2500.ms);
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    final legalAccepted = prefs.getBool('legal_accepted') ?? false;

    // Check legal acceptance first
    if (!legalAccepted) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PrivacyPolicyScreen(
            showAcceptButton: true,
            onAccept: () async {
              await prefs.setBool('legal_accepted', true);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      TermsConditionsScreen(
                    showAcceptButton: true,
                    onAccept: () async {
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    // Use restoreSession() – this handles process-kill + background resume correctly.
    // It: (1) checks in-memory token, (2) reloads from SecureStorage if needed,
    // (3) refreshes near-expiry tokens, before making any navigation decision.
    debugPrint('MAACARE_DEBUG: Calling restoreSession()...');
    final isAuthenticated = await AuthService.instance.restoreSession().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        debugPrint('MAACARE_DEBUG: restoreSession timed out – treating as unauthenticated');
        return false;
      },
    );
    final userId = AuthService.instance.getCurrentUserId();

    debugPrint('MAACARE_DEBUG: Auth status - isAuthenticated: $isAuthenticated, userId: $userId');

    if (!isAuthenticated || userId == null) {
      debugPrint('MAACARE_DEBUG: Not authenticated, navigating to auth');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth');
    } else if (onboardingDone) {
      debugPrint('MAACARE_DEBUG: Onboarding done, loading user');
      try {
        await userProvider.loadUser().timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('MAACARE_DEBUG: loadUser timed out after 5s');
        });
        debugPrint('MAACARE_DEBUG: User loaded, checking user role for dashboard routing...');

        // Sync OneSignal Player ID to backend for push notifications
        debugPrint('MAACARE_DEBUG: Syncing OneSignal token...');
        await PushNotificationService.instance.syncPlayerIdToBackend(userId);
      } catch (e) {
        debugPrint('MAACARE_DEBUG: Error loading user details: $e');
      }
      if (!mounted) return;
      if (userProvider.user != null) {
        final role = userProvider.user!.userRole;
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else if (role == 'unmarried_girl') {
          Navigator.pushReplacementNamed(context, '/period_dashboard');
        } else if (role == 'mother') {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    } else {
      debugPrint('MAACARE_DEBUG: Onboarding not done, checking if user role exists...');
      try {
        await userProvider.loadUser().timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('MAACARE_DEBUG: loadUser timed out after 5s');
        });
      } catch (_) {}
      if (!mounted) return;
      if (userProvider.user != null && userProvider.user!.userRole.isNotEmpty && userProvider.user!.userRole != 'unset') {
        final role = userProvider.user!.userRole;
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else if (role == 'unmarried_girl') {
          Navigator.pushReplacementNamed(context, '/period_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (AuthService.instance.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: MaaColors.darkGradient,
            ),
          ),

          // Animated particles
          ...List.generate(25, (index) {
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
                      ? MaaColors.pink.withAlpha(50)
                      : index % 3 == 1
                          ? MaaColors.gold.withAlpha(40)
                          : MaaColors.softPurple.withAlpha(45),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .moveY(
                  begin: 0,
                  end: -40,
                  duration: Duration(seconds: 4 + (index % 3)),
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: 800.ms);
          }),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing logo container
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              MaaColors.pink.withAlpha(60),
                              MaaColors.softPurple.withAlpha(30),
                              Colors.transparent,
                            ],
                            stops: const [0.3, 0.7, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MaaColors.pink.withAlpha(100),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: MaaColors.softPurple.withAlpha(60),
                              blurRadius: 60,
                              spreadRadius: 25,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: MaaColors.pink.withAlpha(150),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: MaaColors.darkShadow,
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 70,
                                height: 70,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
                    .animate()
                    .scale(
                        delay: 200.ms,
                        duration: 800.ms,
                        curve: Curves.elasticOut)
                    .shimmer(delay: 1500.ms, duration: 2000.ms),

                const SizedBox(height: 40),

                // App name with glow
                Text(
                  'MaaCare',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: MaaColors.textPrimary,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: MaaColors.pink.withAlpha(150),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .moveY(begin: 20, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 16),

                // Greeting
                if (_showGreet)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: MaaColors.glassBackground,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: MaaColors.glassBorder),
                    ),
                    child: Text(
                      _greeting,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MaaColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

                const SizedBox(height: 24),

                // Curiosity teaser
                if (_showTeaser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MaaColors.pink.withAlpha(25),
                          MaaColors.softPurple.withAlpha(25),
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
                        const Text('🔮', style: TextStyle(fontSize: 20))
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(
                                duration: 2000.ms,
                                color: MaaColors.pink.withAlpha(100)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _curiosityTeaser,
                            style: const TextStyle(
                              color: MaaColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms).moveX(begin: 20, end: 0),

                const SizedBox(height: 80),

                // Loading indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: MaaColors.glassBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(MaaColors.pink),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Preparing your experience...',
                        style: TextStyle(
                          color: MaaColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    ).animate(onPlay: (c) => c.repeat()).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(width: 10),
                    const Text(
                      '1,23,456 Mamas online',
                      style: TextStyle(
                        color: MaaColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ),
          ),
        ],
      ),
    );
  }
}

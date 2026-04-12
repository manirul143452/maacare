// ============================================================
//  SubscriptionScreen – MaaCare Premium
//  Full Razorpay Web integration + premium UI
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/price_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../constants.dart';
import '../../providers/user_provider.dart';
import '../../services/razorpay_web_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isAnnual = true;
  int _secondsLeft = 3600; // 1 hour countdown
  int _liveMamas = 12456;
  Timer? _timer;
  String _lastJoiner = 'Sarah from Bangalore just joined! 🌸';

  final List<String> _joiners = [
    'Sarah from Bangalore just joined! 🌸',
    'Priya from Mumbai opted for Super Mom! ✨',
    'Anjali from Delhi is now a Pro Mama! 👑',
    'Deepa from Kolkata joined the club! 💖',
    'Megha from Pune just upgraded! 🚀',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
        if (timer.tick % 5 == 0) {
          _liveMamas += (timer.tick % 3 == 0) ? 1 : -1;
          _lastJoiner = _joiners[timer.tick ~/ 5 % _joiners.length];
        }
      });
    });
  }

  List<_Plan> get _activePlans {
    return [
      _Plan(
        title: 'Free',
        subtitle: 'Basic Care',
        price: 0,
        period: 'Forever free',
        emoji: '🌱',
        features: [
          'Basic pregnancy tracking',
          'Symptom checker',
          'Community access',
          '3 AI chats per day',
          'Vaccination reminders',
        ],
        isFree: true,
      ),
      if (!_isAnnual)
        _Plan(
          title: 'Super Mom 👑',
          subtitle: 'Monthly Premium',
          price: 29900, // ₹299
          period: 'per month',
          emoji: '👑',
          features: [
            'Unlimited AI Companion',
            'Priority Doctor Access',
            'Advanced nutrition guide',
            'Personalized meal plans',
            'Ad-free experience',
            'Exclusive Pink Badge',
            '24/7 Premium Support',
          ],
          isPremium: true,
        )
      else
        _Plan(
          title: 'Super Mom Annual 🏆',
          subtitle: 'Yearly Premium',
          price: 199900, // ₹1999
          period: 'per year (Save ₹589!)',
          emoji: '🏆',
          features: [
            'Everything in Monthly',
            'Birth plan assistance',
            'Postpartum care guide',
            'Baby growth tracker',
            'Priority support',
            'Free consultation session',
            'Family sharing (2 members)',
          ],
          isPremium: true,
          isBestValue: true,
        ),
    ];
  }

  void _handleUpgrade(_Plan plan) async {
    if (plan.isFree) return;

    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    setState(() => _isProcessing = true);

    if (kIsWeb) {
      RazorpayWebService.instance.openCheckout(
        keyId: AppConstants.razorpayKey,
        amount: plan.price,
        currency: 'INR',
        name: 'MaaCare',
        description: plan.title,
        email: user?.email ?? '',
        phone: user?.phone ?? '',
        onSuccess: (paymentId) async {
          setState(() => _isProcessing = false);
          // Mark user as premium in database
          await userProvider.markPremium(
              planName: plan.title, paymentId: paymentId);
          if (mounted) {
            _showSuccessDialog(paymentId);
          }
        },
        onFailed: (error) {
          setState(() => _isProcessing = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: $error'),
                backgroundColor: MaaColors.error,
              ),
            );
          }
        },
        onDismiss: () {
          setState(() => _isProcessing = false);
        },
      );
    } else {
      // Mobile: Use razorpay_flutter package
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use the web app for payments'),
          backgroundColor: MaaColors.softPurple,
        ),
      );
    }
  }

  void _showSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64))
                .animate()
                .scale(curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'Welcome to Super Mom Club!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MaaColors.gold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Payment ID: $paymentId',
              style: GoogleFonts.outfit(
                  fontSize: 11, color: MaaColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaaColors.gold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Start My Premium Journey! 👶',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: MaaColors.background,
      body: Stack(
        children: [
          // Background Particles
          ...List.generate(30, (index) {
            final random = index * 37 % 100;
            return Positioned(
              left: (random * 3.6) % MediaQuery.of(context).size.width,
              top: (random * 8.2) % MediaQuery.of(context).size.height,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index % 2 == 0
                      ? MaaColors.pink.withAlpha(40)
                      : MaaColors.gold.withAlpha(30),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveY(
                  begin: 0,
                  end: -30,
                  duration: Duration(seconds: 3 + (index % 4)),
                );
          }),

          // Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [MaaColors.pink.withAlpha(50), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildLiveCounter(),
                              const SizedBox(height: 16),
                              _buildHeaderSection(),
                              const SizedBox(height: 12),
                              _buildTimerBadge(),
                              const SizedBox(height: 32),
                              _buildPricingToggle(),
                              const SizedBox(height: 32),
                              ..._activePlans.asMap().entries.map((entry) {
                                final i = entry.key;
                                final plan = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _PlanCard(
                                    plan: plan,
                                    isCurrentPlan:
                                        plan.isFree ? !isPremium : isPremium,
                                    isProcessing: _isProcessing,
                                    onUpgrade: () => _handleUpgrade(plan),
                                  )
                                      .animate()
                                      .fadeIn(delay: (i * 100).ms)
                                      .slideY(begin: 0.2, end: 0),
                                );
                              }),
                              _buildTrustSection(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildJoinedTicker(),
              ],
            ),
          ),

          // Full-screen loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: MaaColors.gold),
                    SizedBox(height: 16),
                    Text('Opening Payment...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Premium Hub 👑',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildLiveCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                duration: 800.ms,
              ),
          const SizedBox(width: 10),
          Text(
            '$_liveMamas Mamas online now',
            style: GoogleFonts.poppins(
              color: MaaColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Text(
          'Become a Super Mom! 👑',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: MaaColors.white,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn().moveY(begin: 20, end: 0),
        const SizedBox(height: 8),
        Text(
          'Join the elite club of thousands of mamas\ngetting the best care for their babies.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: MaaColors.textSecondary,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildTimerBadge() {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: MaaColors.pink.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MaaColors.pink.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, color: MaaColors.pink, size: 14),
          const SizedBox(width: 6),
          Text(
            'Special offer ends in $minutes:$seconds',
            style: GoogleFonts.poppins(
              color: MaaColors.pink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
    );
  }

  Widget _buildPricingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: MaaColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem('Monthly', !_isAnnual),
          _buildToggleItem('Yearly', _isAnnual, badge: 'Save 20%'),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, {String? badge}) {
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = (label == 'Yearly')),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: 300.ms,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? MaaColors.pink : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? MaaColors.white : MaaColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -12,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MaaColors.gold,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: MaaColors.gold.withAlpha(100), blurRadius: 4),
                  ],
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.white,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).shake(hz: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildTrustSection() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TrustBadge(icon: Icons.lock_rounded, label: 'Secure Pay'),
            SizedBox(width: 24),
            _TrustBadge(icon: Icons.verified_user_rounded, label: 'SSL Ready'),
            SizedBox(width: 24),
            _TrustBadge(
                icon: Icons.support_agent_rounded, label: '24/7 Support'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Trusted by 10,000+ Mamas worldwide. Powered by Razorpay.',
          style: GoogleFonts.poppins(fontSize: 11, color: MaaColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildJoinedTicker() {
    return Container(
      width: double.infinity,
      color: MaaColors.pink.withAlpha(20),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          _lastJoiner,
          style: GoogleFonts.poppins(
            color: MaaColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ).animate(key: ValueKey(_lastJoiner)).fadeIn().slideX(begin: 1, end: 0),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isCurrentPlan;
  final bool isProcessing;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isProcessing,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isBestValue ? MaaColors.gold : MaaColors.glassBorder,
          width: plan.isBestValue ? 1.5 : 1,
        ),
        boxShadow: plan.isPremium
            ? [
                BoxShadow(
                  color: MaaColors.pink.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (plan.isBestValue)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: const BoxDecoration(
                    color: MaaColors.gold,
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(20)),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: MaaColors.white,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MaaColors.white.withAlpha(10),
                          shape: BoxShape.circle,
                        ),
                        child: Text(plan.emoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: MaaColors.white,
                              ),
                            ),
                            Text(
                              plan.subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: MaaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        PriceFormatter.format(plan.price),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: MaaColors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          plan.period,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: MaaColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...plan.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: MaaColors.success, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                f,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: MaaColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          isCurrentPlan || isProcessing ? null : onUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            plan.isBestValue ? MaaColors.gold : MaaColors.pink,
                        foregroundColor: MaaColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(MaaColors.white)),
                            )
                          : Text(
                              isCurrentPlan
                                  ? 'Current Plan'
                                  : (plan.isFree
                                      ? 'Current Plan'
                                      : 'Upgrade Now 🚀'),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: MaaColors.textMuted, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: MaaColors.textMuted),
        ),
      ],
    );
  }
}

class _Plan {
  final String title;
  final String subtitle;
  final int price;
  final String period;
  final String emoji;
  final List<String> features;
  final bool isFree;
  final bool isPremium;
  final bool isBestValue;

  _Plan({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.emoji,
    required this.features,
    this.isFree = false,
    this.isPremium = false,
    this.isBestValue = false,
  });
}

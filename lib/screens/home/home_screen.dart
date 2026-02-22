// ============================================================
//  HomeScreen – MaaCare Premium Dark Dashboard
//  Dark, mysterious, psychologically attractive design
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/home'),
    _NavItem(icon: Icons.chat_bubble_rounded, label: 'Maa AI', route: '/chat'),
    _NavItem(icon: Icons.favorite_rounded, label: 'Tracker', route: '/tracker'),
    _NavItem(icon: Icons.people_rounded, label: 'Park', route: '/community'),
    _NavItem(icon: Icons.person_rounded, label: 'Me', route: '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 8, end: 15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUser();
      NotificationService.instance.scheduleDailyMoodCheck();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      body: Stack(
        children: [
          // Particle background
          ...List.generate(20, (index) {
            final random = index * 37 % 100;
            final size = 1.5 + (index % 3);
            return Positioned(
              left: (random * 3.6) % MediaQuery.of(context).size.width,
              top: (random * 5.2) % MediaQuery.of(context).size.height,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index % 3 == 0
                      ? MaaColors.pink.withAlpha(30)
                      : index % 3 == 1
                          ? MaaColors.gold.withAlpha(25)
                          : MaaColors.softPurple.withAlpha(30),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveY(
                  begin: 0,
                  end: -25,
                  duration: Duration(seconds: 3 + (index % 4)),
                  curve: Curves.easeInOut,
                );
          }),
          SafeArea(child: _buildBody()),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                MaaColors.pink,
                MaaColors.softPurple,
                MaaColors.gold,
              ],
              numberOfParticles: 25,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MaaColors.pink.withAlpha(150),
                blurRadius: _pulseAnimation.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            backgroundColor: MaaColors.pink,
            child: const Text('🤖', style: TextStyle(fontSize: 24)),
            tooltip: 'Talk to Maa AI',
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MaaColors.glassBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CircularProgressIndicator(
                    color: MaaColors.pink,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          );
        }

        final user = provider.user;
        final week = user?.pregnancyWeek ?? 0;
        final fruitData = getBabyFruitForWeek(week);

        return RefreshIndicator(
          onRefresh: () => provider.loadUser(),
          color: MaaColors.pink,
          backgroundColor: MaaColors.cardDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(user),
                const SizedBox(height: 24),
                _buildCuriosityTeaser(),
                const SizedBox(height: 20),
                _buildBabyWeekCard(week, fruitData),
                const SizedBox(height: 20),
                _buildMoodTracker(provider, user),
                const SizedBox(height: 20),
                _buildHealthSupportCard(),
                const SizedBox(height: 20),
                _buildPointsCard(user),
                const SizedBox(height: 20),
                _buildDailyTip(week),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildSocialProof(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel? user) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: MaaColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn().moveX(begin: -20, end: 0),
            Text(
              user?.name ?? 'Mama',
              style: GoogleFonts.poppins(
                fontSize: 26,
                color: MaaColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 100.ms).moveX(begin: -20, end: 0),
            Text(
              'You\'re doing amazingly! ✨',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: MaaColors.pink,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MaaColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: MaaColors.pink.withAlpha(80),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: MaaColors.cardDark,
              child: user?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) => _buildInitial(user),
                      ),
                    )
                  : _buildInitial(user),
            ),
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
      ],
    );
  }

  Widget _buildInitial(UserModel? user) {
    return Text(
      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
      style: const TextStyle(
        color: MaaColors.pink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCuriosityTeaser() {
    final teasers = [
      '🔮 Unlock your baby\'s secret today?',
      '💫 What milestone awaits this week?',
      '🌟 Discover your pregnancy superpower!',
      '👶 Your baby has a message for you...',
    ];
    final teaser = teasers[DateTime.now().minute % teasers.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MaaColors.pink.withAlpha(20),
            MaaColors.softPurple.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaaColors.pink.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Text('🔮', style: TextStyle(fontSize: 18))
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: MaaColors.pink.withAlpha(100)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              teaser,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: MaaColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: MaaColors.pink.withAlpha(150),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildBabyWeekCard(int week, Map<String, String> fruitData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: MaaColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MaaColors.pink.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: MaaColors.pink.withAlpha(80),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: MaaColors.softPurple.withAlpha(40),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MaaColors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Week $week',
                    style: GoogleFonts.poppins(
                      color: MaaColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your baby is the size of',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'a ${fruitData['fruit']}! ${fruitData['emoji']}',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fruitData['size']} long 👶',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                // Glowing progress bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: MaaColors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (week / 40).clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              MaaColors.white,
                              MaaColors.gold,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: MaaColors.gold.withAlpha(150),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${40 - week} weeks until you meet! 🌟',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white.withAlpha(200),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MaaColors.white.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                fruitData['emoji'] ?? '👶',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).shake(hz: 1, rotation: 0.03),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildMoodTracker(UserProvider provider, UserModel? user) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MaaColors.pink.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🌤', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Text(
                'How are you feeling today?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          MoodSelector(
            selectedMood: user?.mood,
            onSelect: (mood) async {
              await provider.updateMood(mood);
              _confetti.play();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Mood logged! You\'re amazing! +5 ⭐'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: MaaColors.cardLight,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildHealthSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MaaColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: MaaColors.darkShadow,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: MaaColors.successGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: MaaColors.success.withAlpha(100),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Text('🩺', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Support',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MaaColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Track symptoms, get expert help',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: MaaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Glowing heart progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MaaColors.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MaaColors.pink.withAlpha(20),
                  ),
                  child: const Center(
                    child: Text('❤️', style: TextStyle(fontSize: 24)),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Health Score',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: MaaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: MaaColors.cardDark,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(MaaColors.pink),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '75%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.pink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Doctor button with pulse
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/consult'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaaColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.video_call_rounded, color: MaaColors.white),
              label: Text(
                'Doctor in 1 Tap',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.white,
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 2000.ms,
                color: MaaColors.white.withAlpha(30),
              ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildPointsCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: MaaColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MaaColors.gold.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: MaaColors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user?.points ?? 0} MaaPoints',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user?.badgeTitle ?? '🌸 New Mom',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MaaColors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                Text(
                  '${user?.streak ?? 0}',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'streak',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white.withAlpha(180),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildDailyTip(int week) {
    final tips = [
      'Drink 8–10 glasses of water today 💧 Your baby needs it!',
      'Take a 15-min walk for better circulation 🚶‍♀️',
      'Practice deep breathing for 5 minutes 🌬️',
      'Eat iron-rich foods today – spinach, dal, or ragi 🥬',
      'Journal 3 things you\'re grateful for today 📖',
      'Take your prenatal vitamins! They\'re tiny but mighty 💊',
      'Rest when you need to. Your body is doing incredible work 💕',
    ];
    final tip = tips[week % tips.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MaaColors.softPurple.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MaaColors.softPurple.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('💡', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Tip',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MaaColors.softPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).moveX(begin: 20, end: 0);
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('💬', 'Maa AI', '/chat', MaaColors.pink),
      _QuickAction('📊', 'Tracker', '/tracker', MaaColors.softPurple),
      _QuickAction('🩺', 'Symptoms', '/symptoms', MaaColors.warning),
      _QuickAction('🧘', 'Self Care', '/selfcare', MaaColors.softGreen),
      _QuickAction('🍱', 'Nutrition', '/nutrition', MaaColors.lightBlue),
      _QuickAction('💉', 'Vaccines', '/vaccinations', MaaColors.peach),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MaaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final a = entry.value;
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, a.route),
              child: Container(
                decoration: BoxDecoration(
                  color: MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: a.color.withAlpha(30)),
                  boxShadow: [
                    BoxShadow(
                      color: MaaColors.darkShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(a.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: MaaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (800 + index * 50).ms)
                .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: MaaColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaaColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
            '${AppConstants.momsOnline} Mamas are with you right now!',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MaaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        boxShadow: [
          BoxShadow(
            color: MaaColors.darkShadow,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.transparent,
        indicatorColor: MaaColors.pink.withAlpha(30),
        elevation: 0,
        onDestinationSelected: (index) {
          if (index == 0) {
            setState(() => _selectedIndex = index);
            return;
          }
          setState(() => _selectedIndex = index);
          Navigator.pushNamed(context, _navItems[index].route);
        },
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon, color: MaaColors.textMuted),
                  selectedIcon: Icon(item.icon, color: MaaColors.pink),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(
      {required this.icon, required this.label, required this.route});
}

class _QuickAction {
  final String emoji;
  final String label;
  final String route;
  final Color color;
  const _QuickAction(this.emoji, this.label, this.route, this.color);
}
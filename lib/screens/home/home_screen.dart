// ============================================================
//  HomeScreen – MaaCare Dashboard
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../app_theme.dart';
import '../../constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/maa_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUser();
      NotificationService.instance.scheduleDailyMoodCheck();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.offWhite,
      body: Stack(
        children: [
          SafeArea(child: _buildBody()),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [MaaColors.deepPink, MaaColors.peach, MaaColors.gold],
              numberOfParticles: 20,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        backgroundColor: MaaColors.deepPink,
        child: const Text('🤖', style: TextStyle(fontSize: 24)),
        tooltip: 'Talk to Maa AI',
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: MaaColors.deepPink),
          );
        }

        final user = provider.user;
        final week = user?.pregnancyWeek ?? 0;
        final fruitData = getBabyFruitForWeek(week);

        return RefreshIndicator(
          onRefresh: () => provider.loadUser(),
          color: MaaColors.deepPink,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(user),
                const SizedBox(height: 20),
                _buildBabyWeekCard(week, fruitData),
                const SizedBox(height: 16),
                _buildMoodTracker(provider, user),
                const SizedBox(height: 16),
                _buildPointsCard(user),
                const SizedBox(height: 16),
                _buildDailyTip(week),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 16),
                _buildSocialProof(),
                const SizedBox(height: 80),
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
              '$greeting, ${user?.name ?? 'Mama'} 💕',
              style: Theme.of(context).textTheme.headlineLarge,
            ).animate().fadeIn().moveX(begin: -20, end: 0),
            Text(
              'You\'re doing amazingly!',
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: MaaColors.pink,
            child: Text(
              user?.name.isNotEmpty == true
                  ? user!.name[0].toUpperCase()
                  : 'M',
              style: const TextStyle(
                  color: MaaColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
      ],
    );
  }

  Widget _buildBabyWeekCard(int week, Map<String, String> fruitData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: MaaColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MaaColors.deepPink.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week $week',
                  style: const TextStyle(
                    color: MaaColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your baby is the size of',
                  style: TextStyle(
                      color: MaaColors.white.withAlpha(200), fontSize: 13),
                ),
                Text(
                  'a ${fruitData['fruit']}! ${fruitData['emoji']}',
                  style: const TextStyle(
                    color: MaaColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fruitData['size']} long 👶',
                  style: TextStyle(
                      color: MaaColors.white.withAlpha(200), fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Progress bar with Flowers
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (week / 40).clamp(0.0, 1.0),
                        backgroundColor: MaaColors.white.withAlpha(80),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(MaaColors.white),
                        minHeight: 10,
                      ),
                    ),
                    Positioned(
                      left: (week / 40 * 100).clamp(0, 95).toDouble(),
                      top: -4,
                      child: const Text('🌸', style: TextStyle(fontSize: 16))
                          .animate(onPlay: (c) => c.repeat())
                          .rotate(begin: -0.2, end: 0.2, duration: 1.seconds, curve: Curves.easeInOut),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${40 - week} weeks until you meet! 🌟',
                  style: TextStyle(
                      color: MaaColors.white.withAlpha(200), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            fruitData['emoji'] ?? '👶',
            style: const TextStyle(fontSize: 72),
          ).animate(onPlay: (c) => c.repeat()).shake(hz: 2),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack).fadeIn(delay: 300.ms);
  }

  Widget _buildMoodTracker(UserProvider provider, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: MaaColors.cardShadow, blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling today? 🌤',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: MaaColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: MaaColors.gold.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user?.points ?? 0} MaaPoints',
                style: const TextStyle(
                  color: MaaColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                user?.badgeTitle ?? '🌸 New Mom',
                style: TextStyle(
                    color: MaaColors.white.withAlpha(200), fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              Text(
                '${user?.streak ?? 0} day streak',
                style: const TextStyle(
                    color: MaaColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).moveY(begin: 20, end: 0);
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
        gradient: MaaColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MaaColors.pink.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Tip',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: MaaColors.deepPink,
                          fontSize: 14,
                        )),
                const SizedBox(height: 4),
                Text(tip,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                        )),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).moveX(begin: 20, end: 0);
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('💬', 'Talk to\nMaa AI', '/chat'),
      _QuickAction('📊', 'Pregnancy\nTracker', '/tracker'),
      _QuickAction('🩺', 'Symptom\nChecker', '/symptoms'),
      _QuickAction('🧘', 'Self\nCare', '/selfcare'),
      _QuickAction('🍱', 'Nutrition', '/nutrition'),
      _QuickAction('💉', 'Vaccines', '/vaccinations'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: actions.map((a) {
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, a.route),
              child: Container(
                decoration: BoxDecoration(
                  color: MaaColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: MaaColors.cardShadow,
                        blurRadius: 12,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: MaaColors.textDark),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: MaaColors.softPurple.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👩‍👩‍👧‍👦', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(
            '${AppConstants.momsOnline} Mamas are with you right now!',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MaaColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      backgroundColor: MaaColors.white,
      indicatorColor: MaaColors.pink.withAlpha(60),
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        Navigator.pushReplacementNamed(context, _navItems[index].route);
      },
      destinations: _navItems
          .map((item) => NavigationDestination(
                icon: Icon(item.icon, color: MaaColors.textGrey),
                selectedIcon: Icon(item.icon, color: MaaColors.deepPink),
                label: item.label,
              ))
          .toList(),
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
  const _QuickAction(this.emoji, this.label, this.route);
}

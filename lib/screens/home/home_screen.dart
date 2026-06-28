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
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/auto_sync_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/error_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/language_picker_sheet.dart';
import '../community/parents_park_screen.dart';
import 'widgets/pregnancy_progress_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  Timer? _countdownTimer;
  String _timeRemainingStr = "";

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
      _fetchData();
      NotificationService.instance.scheduleDailyMoodCheck();
      _startCountdown();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final user = context.read<UserProvider>().user;
        if (user?.dueDate != null) {
          final diff = user!.dueDate!.difference(DateTime.now());
          if (diff.isNegative) {
            setState(() => _timeRemainingStr = "Mama, it's Baby Day! 👶");
          } else {
            final days = diff.inDays;
            final hours = diff.inHours % 24;
            final minutes = diff.inMinutes % 60;
            final seconds = diff.inSeconds % 60;
            setState(() {
              _timeRemainingStr =
                  "${days}d : ${hours}h : ${minutes}m : ${seconds}s";
            });
          }
        }
      }
    });
  }

  Future<void> _fetchData() async {
    final userProvider = context.read<UserProvider>();
    final communityProvider = context.read<CommunityProvider>();

    await userProvider.loadUser();

    if (userProvider.error != null && mounted) {
      ErrorHelper.showError(context, userProvider.error!);
    }

    final user = userProvider.user;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    if (user.userRole != 'mother') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Unauthorised role for Maternal Dashboard.'),
            backgroundColor: Colors.red,
          ),
        );
        if (user.userRole == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else if (user.userRole == 'unmarried_girl') {
          Navigator.pushReplacementNamed(context, '/period_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
      }
      return;
    }

    // Initialize auto-sync service with providers
    if (!AutoSyncService.instance.isInitialized) {
      await AutoSyncService.instance.initialize(
        userProvider: userProvider,
        communityProvider: communityProvider,
      );

      // Enable background sync for notifications
      await AutoSyncService.instance.enableBackgroundSync();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    // Trim image cache on screen exit to free memory
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Particle background — static widget with its own lifecycle
          const _ParticleBackground(),
          SafeArea(
            child: Consumer<UserProvider>(
              builder: (context, provider, _) => LoadingOverlay(
                isLoading: provider.isLoading,
                child: _buildBody(provider),
              ),
            ),
          ),
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
            tooltip: 'Talk to Maa AI',
            child: const Text('🤖', style: TextStyle(fontSize: 24)),
          ),
        );
      },
    );
  }

  Widget _buildBody(UserProvider provider) {
    if (!provider.isLoading &&
        provider.error != null &&
        provider.user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).connectionLost,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).dashboardError,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(180)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaaColors.pink,
                  foregroundColor: MaaColors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = provider.user;
    final week = user?.pregnancyWeek ?? 0;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: MaaColors.pink,
      backgroundColor: Theme.of(context).cardTheme.color ?? MaaColors.cardDark,
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
            PregnancyProgressCard(week: week, timeRemainingStr: _timeRemainingStr),
            const SizedBox(height: 20),
            _buildMoodTracker(provider, user),
            const SizedBox(height: 20),
            if (!(user?.isPremium ?? false))
              _buildPremiumBanner()
                  .animate()
                  .fadeIn(delay: 450.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 20),
            _buildHealthSupportCard(),
            const SizedBox(height: 20),
            _buildPointsCard(user),
            const SizedBox(height: 20),
            _buildDailyTip(week),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildLatestInParentsPark(),
            const SizedBox(height: 20),
            _buildSocialProof(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning
        : hour < 17
            ? l10n.goodAfternoon
            : l10n.goodEvening;
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
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn().moveX(begin: -20, end: 0),
            Text(
              user?.name ?? l10n.mama,
              style: GoogleFonts.poppins(
                fontSize: 26,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 100.ms).moveX(begin: -20, end: 0),
            Text(
              l10n.doingAmazingly,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
        // Translation Button
        _buildTranslationButton(),
        const SizedBox(width: 12),
        // Notification Bell with Badge
        _buildNotificationBell(),
        const SizedBox(width: 12),
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
                      child: user!.avatarUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(user.avatarUrl!.split(',').last),
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              errorBuilder: (_, __, ___) => _buildInitial(user),
                            )
                          : CachedNetworkImage(
                              imageUrl: user.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              memCacheWidth: 150,
                              placeholder: (ctx, url) => _buildInitial(user),
                              errorWidget: (ctx, url, error) => _buildInitial(user),
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

  Widget _buildTranslationButton() {
    return GestureDetector(
      onTap: () => LanguagePickerSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MaaColors.glassBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MaaColors.glassBorder,
          ),
        ),
        child: const Icon(
          Icons.translate_rounded,
          color: MaaColors.textMuted,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return StreamBuilder<int>(
      stream: PushNotificationService.instance.onBadgeCountChanged,
      initialData: PushNotificationService.instance.unreadCount,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: unreadCount > 0
                  ? MaaColors.pink.withAlpha(30)
                  : MaaColors.glassBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unreadCount > 0
                    ? MaaColors.pink.withAlpha(50)
                    : MaaColors.glassBorder,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  unreadCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_outlined,
                  color: unreadCount > 0 ? MaaColors.pink : MaaColors.textMuted,
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: MaaColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MaaColors.pink.withAlpha(60),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 600.ms);
      },
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
                color: Theme.of(context).colorScheme.onSurface,
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
                AppLocalizations.of(context).howFeelingToday,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
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

              // Save mood score to Health Insights chart history
              // Emoji → numeric score (1.0 sad → 5.0 happy)
              const moodScores = {
                '😢': 1.0, 'Sad': 1.0, 'Crying': 1.0,
                '😔': 2.0, 'Low': 2.0,
                '😰': 2.0, 'Anxious': 2.0, 'Worried': 2.0,
                '😐': 3.0, 'Okay': 3.0, 'Neutral': 3.0,
                '🙂': 4.0, 'Good': 4.0,
                '😊': 4.0, 'Happy': 4.0, 'Grateful': 4.0,
                '😄': 5.0, 'Great': 5.0, 'Excited': 5.0,
              };
              final score = moodScores[mood] ?? 3.0;
              try {
                final prefs = await SharedPreferences.getInstance();
                final raw = prefs.getString('insights_mood_logs');
                final history = raw != null
                    ? (jsonDecode(raw) as List).map((e) => (e as num).toDouble()).toList()
                    : <double>[3.0, 3.0, 3.0, 3.0, 3.0, 3.0];
                history.add(score);
                // Keep rolling 7-day window
                final trimmed = history.length > 7
                    ? history.sublist(history.length - 7)
                    : history;
                await prefs.setString(
                    'insights_mood_logs', jsonEncode(trimmed));
              } catch (_) {}

              if (mounted) {
                ErrorHelper.showSuccess(
                    context, AppLocalizations.of(context).moodLogged);
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(20)),
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
                      AppLocalizations.of(context).healthSupport,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).trackSymptomsHelp,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(180),
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
                ).animate(onPlay: (c) => c.repeat()).scale(
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
                        AppLocalizations.of(context).yourHealthScore,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: MaaColors.cardDark,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(MaaColors.pink),
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
              icon:
                  const Icon(Icons.video_call_rounded, color: MaaColors.white),
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
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildRewardsBottomSheet(user),
        );
      },
      child: Container(
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
      ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0),
    );
  }

  Widget _buildRewardsBottomSheet(UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: MaaColors.gold.withAlpha(50), width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: MaaColors.textMuted.withAlpha(100),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: MaaColors.goldGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Rewards',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${user?.points ?? 0} MaaPoints Available',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'How to earn MaaPoints?',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          _buildRewardTask('Log daily mood', '+10 Points', '🌤', true),
          const SizedBox(height: 12),
          _buildRewardTask('Complete daily checklist', '+20 Points', '✅', true),
          const SizedBox(height: 12),
          _buildRewardTask('Engage in Parents Park', '+15 Points', '💬', true),
          const SizedBox(height: 12),
          _buildRewardTask('Read Health Articles', '+5 Points', '📚', true),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaaColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppLocalizations.of(context).keepEarning,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRewardTask(
      String title, String reward, String emoji, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaaColors.gold.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaaColors.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text(reward,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: MaaColors.gold)),
              ],
            ),
          ),
        ],
      ),
    );
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
      const _QuickAction(Icons.chat_bubble_rounded, 'Maa AI', '/chat',
          MaaColors.pink, Icons.chat_bubble_outline),
      const _QuickAction(Icons.track_changes_rounded, 'Tracker', '/tracker',
          MaaColors.softPurple, Icons.track_changes_outlined),
      const _QuickAction(Icons.healing_rounded, 'Symptoms', '/symptoms',
          MaaColors.warning, Icons.healing_outlined),
      const _QuickAction(Icons.spa_rounded, 'Self Care', '/selfcare',
          MaaColors.softGreen, Icons.spa_outlined),
      const _QuickAction(Icons.restaurant_menu_rounded, 'Nutrition',
          '/nutrition', MaaColors.lightBlue, Icons.restaurant_menu_outlined),
      const _QuickAction(Icons.vaccines_rounded, 'Vaccines', '/vaccinations',
          MaaColors.peach, Icons.vaccines_outlined),
      const _QuickAction(Icons.child_care_rounded, 'Baby Growth', '/child-growth',
          MaaColors.pink, Icons.child_care_outlined),
      const _QuickAction(Icons.analytics_rounded, 'Insights', '/health-insights',
          MaaColors.gold, Icons.analytics_outlined),
      const _QuickAction(Icons.video_call_rounded, 'Consult', '/consult',
          MaaColors.success, Icons.video_call_outlined),
      const _QuickAction(Icons.menu_book_rounded, 'Care Guide', '/guide',
          MaaColors.gold, Icons.menu_book_outlined),
      const _QuickAction(Icons.shield_rounded, 'Contraception & Planning',
          '/contraception', Color(0xFF7C4DFF), Icons.shield_outlined),
      const _QuickAction(Icons.family_restroom_rounded, 'Planning', '/planning',
          MaaColors.softGreen, Icons.family_restroom_outlined),
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: a.color.withAlpha(40)),
                  boxShadow: [
                    BoxShadow(
                      color: a.color.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Gradient Icon Container
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            a.color.withAlpha(180),
                            a.color.withAlpha(80),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: a.color.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          a.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MaaColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (800 + index * 50).ms).scale(
                begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
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
          ).animate(onPlay: (c) => c.repeat()).scale(
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
        color: Theme.of(context).cardTheme.color ?? MaaColors.cardDark,
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
            .map<NavigationDestination>((item) => NavigationDestination(
                  icon: Icon(item.icon, color: MaaColors.textMuted),
                  selectedIcon: Icon(item.icon, color: MaaColors.pink),
                  label: () {
                    switch (item.label) {
                      case 'Home':
                        return AppLocalizations.of(context).navHome;
                      case 'Tracker':
                        return AppLocalizations.of(context).navTracker;
                      case 'Park':
                        return AppLocalizations.of(context).navCommunity;
                      case 'Me':
                        return AppLocalizations.of(context).navProfile;
                      default:
                        return item.label;
                    }
                  }(),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: MaaColors.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MaaColors.gold.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  'Join Super Mom Club! 👑',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlock unlimited AI chat, priority doctor visits, and 20+ premium perks.',
                  style: GoogleFonts.poppins(
                    color: MaaColors.white.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaaColors.white,
                    foregroundColor: MaaColors.gold,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Try it Now! 🚀',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Text('🎁', style: TextStyle(fontSize: 48))
              .animate(onPlay: (c) => c.repeat())
              .shake(hz: 1, rotation: 0.1),
        ],
      ),
    );
  }

  Widget _buildLatestInParentsPark() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        // Auto-fetch posts when widget builds (if not already loading or fetched)
        if (!provider.isLoading &&
            !provider.hasFetched &&
            provider.error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.fetchPosts(limit: 5);
          });
        }

        final posts = provider.posts.take(5).toList();

        // Fallback content if no posts yet
        final displayItems = posts.isEmpty
            ? _getFallbackPosts()
            : posts
                .map((p) => _PostDisplayItem(
                      id: p.id,
                      text: p.content,
                      imageUrl: p.imageUrl,
                      likes: p.likes,
                      authorName: p.anonymous
                          ? 'Anonymous Mama'
                          : (p.authorName ?? 'Mama'),
                      weekTag: p.weekTag,
                    ))
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MaaColors.pink.withAlpha(150),
                            MaaColors.softPurple.withAlpha(100)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Latest in Parents Park',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ParentsParkScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(AppLocalizations.of(context).viewAll,
                      style: GoogleFonts.poppins(
                          color: MaaColors.pink, fontWeight: FontWeight.w600)),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Live indicator when using real data
            if (posts.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MaaColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MaaColors.success.withAlpha(50)),
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
                              spreadRadius: 1),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat()).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                        duration: 1000.ms),
                    const SizedBox(width: 8),
                    Text(
                      'Live Updates',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MaaColors.success,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _buildParentsParkCard(item, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<_PostDisplayItem> _getFallbackPosts() {
    return [
      _PostDisplayItem(
        id: '1',
        text:
            'How to handle teething? Looking for tips from experienced mamas 💕',
        imageUrl: null,
        likes: 24,
        authorName: 'Priya M.',
        weekTag: 16,
      ),
      _PostDisplayItem(
        id: '2',
        text: 'Nursery room ideas that saved my sanity! 🌸',
        imageUrl: null,
        likes: 89,
        authorName: 'Anonymous Mama',
        weekTag: 24,
      ),
      _PostDisplayItem(
        id: '3',
        text: 'My 20-week scan experience - everything you need to know! 👶',
        imageUrl: null,
        likes: 156,
        authorName: 'Sarah K.',
        weekTag: 20,
      ),
      _PostDisplayItem(
        id: '4',
        text: 'Best pregnancy yoga routines for beginners 🧘‍♀️',
        imageUrl: null,
        likes: 42,
        authorName: 'Anonymous Mama',
        weekTag: 12,
      ),
    ];
  }

  Widget _buildParentsParkCard(_PostDisplayItem post, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParentsParkScreen()),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MaaColors.cardDark,
              MaaColors.cardDark.withAlpha(200),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MaaColors.pink.withAlpha(30)),
          boxShadow: [
            BoxShadow(
              color: MaaColors.darkShadow,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with author
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MaaColors.pink.withAlpha(40),
                          MaaColors.softPurple.withAlpha(20),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            gradient: MaaColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              post.authorName[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.authorName,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MaaColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        post.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: MaaColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  // Footer with likes and week tag
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MaaColors.pink.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_rounded,
                                  color: MaaColors.pink, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likes}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: MaaColors.pink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.weekTag > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MaaColors.softPurple.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Week ${post.weekTag}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: MaaColors.softPurple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // "Read More" overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        MaaColors.cardDark,
                        MaaColors.cardDark.withAlpha(0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: MaaColors.pink.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MaaColors.pink.withAlpha(50)),
                      ),
                      child: Text(
                        'Read More',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: MaaColors.pink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0),
    );
  }
}

// Helper class for displaying posts
class _PostDisplayItem {
  final String id;
  final String text;
  final String? imageUrl;
  final int likes;
  final String authorName;
  final int weekTag;

  _PostDisplayItem({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.likes,
    required this.authorName,
    required this.weekTag,
  });
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(
      {required this.icon, required this.label, required this.route});
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final IconData? outlinedIcon;
  const _QuickAction(this.icon, this.label, this.route, this.color,
      [this.outlinedIcon]);
}

// ─── Isolated particle widget: AnimationControllers owned & disposed here ─────
class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();
  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with TickerProviderStateMixin {
  static const int _count = 12;
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _count,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(seconds: 3 + (i % 4)),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -25)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(_count, (i) {
            final random = i * 37 % 100;
            final dotSize = 1.5 + (i % 3).toDouble();
            final color = i % 3 == 0
                ? MaaColors.pink.withAlpha(30)
                : i % 3 == 1
                    ? MaaColors.gold.withAlpha(25)
                    : MaaColors.softPurple.withAlpha(30);
            return Positioned(
              left: (random * 3.6) % size.width,
              top: (random * 5.2) % size.height,
              child: AnimatedBuilder(
                animation: _animations[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _animations[i].value),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

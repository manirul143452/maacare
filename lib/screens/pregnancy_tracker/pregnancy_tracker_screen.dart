// ============================================================
//  Pregnancy Tracker Screen – MaaCare
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../app_theme.dart';
import '../../constants.dart';
import '../../data/pregnancy_data.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/error_helper.dart';
import 'weekly_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PregnancyTrackerScreen extends StatefulWidget {
  const PregnancyTrackerScreen({super.key});

  @override
  State<PregnancyTrackerScreen> createState() => _PregnancyTrackerScreenState();
}

class _PregnancyTrackerScreenState extends State<PregnancyTrackerScreen> {
  final Map<String, bool> _tasks = {
    '💧 Drink 8 glasses of water': false,
    '🧘 10-min prenatal yoga': false,
    '💊 Take prenatal vitamins': false,
    '🚶 15-min walk': false,
    '😴 Rest for 30 min': false,
    '📖 Read a chapter / journaling': false,
  };

  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _setupMidnightTimer();
    // Delay slightly to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _setupMidnightTimer() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationToMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationToMidnight, () {
      if (mounted) {
        setState(() {}); // Force chronological recalculation of week
        // Set up the next cycle for subsequent days
        _setupMidnightTimer(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌸 A new day! Your pregnancy milestones have updated. 👶')),
        );
      }
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final provider = context.read<UserProvider>();
    await provider.loadUser();
    if (provider.error != null && mounted) {
      ErrorHelper.showError(context, provider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${AppLocalizations.of(context).navTracker} 🤰')),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          final provider = context.read<UserProvider>();
          if (provider.user?.points != null && provider.user!.points < 100) {
            debugPrint('Mama, keep tracking to earn your first badge! 🌸');
          }
        },
        child: Consumer<UserProvider>(
          builder: (ctx, provider, _) {
            final user = provider.user;
            final week = user?.pregnancyWeek ?? 0;
            final fruitData = getBabyFruitForWeek(week);
            final milestones = _getMilestones(week);
            return LoadingOverlay(
              isLoading: provider.isLoading,
              child: provider.error != null &&
                      user == null &&
                      !provider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 48, color: MaaColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('Could not load your tracker data.',
                              style: TextStyle(color: MaaColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchData,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: MaaColors.pink,
                                foregroundColor: MaaColors.white),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      color: MaaColors.pink,
                      backgroundColor: Theme.of(context).cardTheme.color ?? MaaColors.cardDark,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Baby card
                            _buildBabyCard(week, fruitData),
                            const SizedBox(height: 20),
                            // Trimester info
                            _buildTrimesterInfo(week),
                            const SizedBox(height: 20),
                            // Daily tasks
                            _buildDailyTasks(provider),
                            const SizedBox(height: 20),
                            // Milestones
                            _buildMilestones(milestones, week),
                            const SizedBox(height: 20),
                            // All Weeks Journey
                            _buildWeeklyJourney(week),
                            const SizedBox(height: 16),
                            _buildTrackerSocialProof(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBabyCard(int week, Map<String, String> fruitData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: MaaColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: MaaColors.deepPink.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(
                  color: MaaColors.pink.withAlpha(50),
                  blurRadius: 20,
                  spreadRadius: 5)
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(70),
              child: Image.asset(
                'assets/images/weeks/week_${week < 4 ? 4 : (week > 41 ? 41 : week)}.jpg',
                width: 140,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  fruitData['emoji'] ?? '👶',
                  style: const TextStyle(fontSize: 80),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shake(hz: 1, duration: 2.seconds),
              ),
            ),
          )
              .animate()
              .scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'Week $week – ${fruitData['fruit']}',
            style: const TextStyle(
              color: MaaColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn().scale(),
          Text(
            'About ${fruitData['size']} long 💕',
            style: TextStyle(
                color: MaaColors.white.withAlpha(220),
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: (week / 40).clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: MaaColors.white.withAlpha(60),
              valueColor: const AlwaysStoppedAnimation<Color>(MaaColors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Week $week of 40 – ${((week / 40) * 100).toStringAsFixed(0)}% complete!',
            style: TextStyle(
                color: MaaColors.white.withAlpha(200),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildTrimesterInfo(int week) {
    final String trimester;
    final String info;
    final String emoji;

    if (week <= 13) {
      trimester = '1st Trimester';
      info = 'Your baby\'s organs are forming. Rest well and stay hydrated!';
      emoji = '🌱';
    } else if (week <= 26) {
      trimester = '2nd Trimester';
      info = 'You may start feeling baby move! This is the "golden trimester".';
      emoji = '🌻';
    } else {
      trimester = '3rd Trimester';
      info = 'Almost there! Baby is gaining weight and preparing for birth.';
      emoji = '🌺';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: MaaColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaaColors.pink.withAlpha(80)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trimester,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MaaColors.deepPink)),
                const SizedBox(height: 4),
                Text(info,
                    style: const TextStyle(
                        fontSize: 13, color: MaaColors.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasks(UserProvider provider) {
    final completedCount = _tasks.values.where((v) => v).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s Tasks ✅',
                style: Theme.of(context).textTheme.titleLarge),
            Text(
              '$completedCount/${_tasks.length}',
              style: const TextStyle(
                  color: MaaColors.deepPink, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._tasks.keys.map((task) {
          final done = _tasks[task]!;
          return CheckboxListTile(
            title: Text(
              task,
              style: TextStyle(
                fontSize: 14,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? MaaColors.textGrey : MaaColors.textDark,
              ),
            ),
            value: done,
            activeColor: MaaColors.deepPink,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
            onChanged: (val) async {
              setState(() => _tasks[task] = val!);
              if (val == true) {
                await provider.addPoints(AppConstants.pointsPerTask);
                if (mounted) {
                  ErrorHelper.showSuccess(context,
                      '✅ Task done! +${AppConstants.pointsPerTask} MaaPoints 🌟');
                }
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildMilestones(List<Map<String, dynamic>> milestones, int week) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Milestones 🏆', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...milestones.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          final reached = week >= (m['week'] as int);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: reached ? MaaColors.success.withAlpha(20) : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: reached
                    ? MaaColors.success.withAlpha(80)
                    : MaaColors.pink.withAlpha(60),
                width: reached ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: MaaColors.cardShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Text(reached ? '✅' : '⭕', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['title'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              reached ? MaaColors.success : MaaColors.textDark,
                        ),
                      ),
                      Text(
                        'Week ${m['week']}',
                        style: const TextStyle(
                            fontSize: 12, color: MaaColors.textGrey),
                      ),
                    ],
                  ),
                ),
                if (reached)
                  IconButton(
                    icon: const Icon(Icons.share_rounded,
                        color: MaaColors.deepPink, size: 20),
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'I reached a new milestone on MaaCare! 🏆 "${m['title']}" at Week ${m['week']}! ${m['emoji']}\n\nYou are never alone, Mama! 💕',
                          subject: 'MaaCare Milestone! 🎉',
                        ),
                      );
                    },
                    tooltip: 'Share milestone!',
                  ).animate().scale(curve: Curves.elasticOut),
                Text(m['emoji'] as String,
                    style: const TextStyle(fontSize: 28)),
              ],
            ),
          ).animate().fadeIn(delay: (idx * 50).ms).moveX(begin: 30, end: 0);
        }),
      ],
    );
  }

  Widget _buildWeeklyJourney(int currentWeek) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('The 40-Week Journey 📅',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...weeklyPregnancyData.keys.map((weekNum) {
          final info = weeklyPregnancyData[weekNum]!;
          final isCurrent = weekNum == currentWeek;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? MaaColors.softPurple.withAlpha(60)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent
                    ? MaaColors.pink.withAlpha(100)
                    : MaaColors.pink.withAlpha(30),
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: MaaColors.cardShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyDetailScreen(week: weekNum),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/weeks/week_$weekNum.jpg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: MaaColors.pink.withAlpha(20),
                          child: const Center(
                              child: Icon(Icons.child_care_rounded,
                                  color: MaaColors.pink)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week $weekNum: ${info['title']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isCurrent
                                  ? MaaColors.deepPink
                                  : MaaColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            info['size'] ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: MaaColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isCurrent
                          ? MaaColors.deepPink
                          : MaaColors.textGrey.withAlpha(150),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrackerSocialProof() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.pink.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Text('🦋', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '842 other Mamas in your week are tracking their milestones today! You\'re doing great! ✨',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.textDark),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  List<Map<String, dynamic>> _getMilestones(int week) {
    return [
      {'week': 8, 'title': 'Heartbeat detected', 'emoji': '💓'},
      {'week': 12, 'title': 'End of first trimester', 'emoji': '🎉'},
      {'week': 16, 'title': 'Sex can be detected', 'emoji': '👶'},
      {'week': 20, 'title': 'Anatomy scan / Halfway!', 'emoji': '🌟'},
      {'week': 24, 'title': 'Baby starts hearing', 'emoji': '👂'},
      {'week': 28, 'title': 'Third trimester begins', 'emoji': '🌺'},
      {'week': 36, 'title': 'Baby is full-term soon', 'emoji': '🏠'},
      {'week': 40, 'title': 'Due date! Hello baby!', 'emoji': '🎊'},
    ];
  }
}

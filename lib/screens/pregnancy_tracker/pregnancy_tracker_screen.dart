// ============================================================
//  Pregnancy Tracker Screen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../app_theme.dart';
import '../../constants.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/maa_button.dart';

class PregnancyTrackerScreen extends StatefulWidget {
  const PregnancyTrackerScreen({super.key});

  @override
  State<PregnancyTrackerScreen> createState() =>
      _PregnancyTrackerScreenState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pregnancy Tracker 🤰')),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                  // Development facts
                  _buildDevFacts(week),
                  const SizedBox(height: 16),
                  _buildTrackerSocialProof(),
                  const SizedBox(height: 80),
                ],
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
          BoxShadow(color: MaaColors.deepPink.withAlpha(60), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Text(
            fruitData['emoji'] ?? '👶',
            style: const TextStyle(fontSize: 80),
          ).animate(onPlay: (c) => c.repeat()).shake(hz: 1, duration: 2.seconds),
          const SizedBox(height: 12),
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
                color: MaaColors.white.withAlpha(220), fontSize: 16, fontWeight: FontWeight.w600),
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
                color: MaaColors.white.withAlpha(200), fontSize: 13, fontWeight: FontWeight.w500),
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
                  color: MaaColors.deepPink,
                  fontWeight: FontWeight.w700),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '✅ Task done! +${AppConstants.pointsPerTask} MaaPoints 🌟'),
                  ));
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
        Text('Milestones 🏆',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...milestones.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          final reached = week >= (m['week'] as int);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: reached
                  ? MaaColors.success.withAlpha(20)
                  : MaaColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: reached
                    ? MaaColors.success.withAlpha(80)
                    : MaaColors.pink.withAlpha(60),
                width: reached ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: MaaColors.cardShadow, blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Text(reached ? '✅' : '⭕',
                    style: const TextStyle(fontSize: 22)),
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
                          color: reached
                              ? MaaColors.success
                              : MaaColors.textDark,
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
                    icon: const Icon(Icons.share_rounded, color: MaaColors.deepPink, size: 20),
                    onPressed: () {
                      Share.share(
                        'I reached a new milestone on MaaCare! 🏆 "${m['title']}" at Week ${m['week']}! ${m['emoji']}\n\nYou are never alone, Mama! 💕',
                        subject: 'MaaCare Milestone! 🎉',
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

  Widget _buildDevFacts(int week) {
    final facts = _getWeekFacts(week);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.softPurple.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👶 Baby\'s Development',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.textDark)),
          const SizedBox(height: 10),
          ...facts.map((fact) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌸 ',
                        style: TextStyle(fontSize: 14)),
                    Expanded(
                        child: Text(fact,
                            style: const TextStyle(
                                fontSize: 13, color: MaaColors.textGrey))),
                  ],
                ),
              )),
        ],
      ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '842 other Mamas in your week are tracking their milestones today! You\'re doing great! ✨',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MaaColors.textDark),
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

  List<String> _getWeekFacts(int week) {
    if (week < 8) {
      return [
        'Neural tube (brain and spine) is forming',
        'Heart begins to beat',
        'Basic facial features developing',
      ];
    } else if (week < 16) {
      return [
        'Fingers and toes are forming',
        'Baby can make facial expressions',
        'Digestive system developing',
      ];
    } else if (week < 24) {
      return [
        'Baby can hear your voice!',
        'Eyebrows and lashes forming',
        'Baby practices breathing movements',
      ];
    } else if (week < 32) {
      return [
        'Baby opens and closes eyes',
        'Bones are hardening',
        'Baby responds to light and sound',
      ];
    } else {
      return [
        'Baby is gaining fat for warmth',
        'Lungs are almost fully developed',
        'Baby is in position for birth',
      ];
    }
  }
}

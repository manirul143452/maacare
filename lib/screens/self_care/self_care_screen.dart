// ============================================================
//  Self Care Screen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _journalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Care 🧘'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MaaColors.deepPink,
          unselectedLabelColor: MaaColors.textGrey,
          indicatorColor: MaaColors.deepPink,
          tabs: const [
            Tab(text: '📖 Journal'),
            Tab(text: '🧘 Yoga'),
            Tab(text: '🌬️ Meditation'),
          ],
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (_journalController.text.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your journal draft is saved, Mama! 📖')),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildJournal(),
            _buildYoga(),
            _buildMeditation(),
          ],
        ),
      ),
    );
  }

  Widget _buildJournal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: MaaColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌟 Micro-win of the day!',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  '"You took care of yourself today. That is incredible, Mama!" 💕',
                  style: TextStyle(
                      fontSize: 13, color: MaaColors.textGrey, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('How are you feeling today?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _journalController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText:
                  'Write freely... your thoughts, feelings, dreams for baby 💕',
            ),
          ),
          const SizedBox(height: 16),
          MaaButton(
            label: 'Save Entry 📖',
            onPressed: () {
              if (_journalController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Journal saved! You\'re amazing 🌟')),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          Text('Gratitude prompts 💕',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...[
            '3 things I am grateful for today...',
            'One thing my body did amazing today...',
            'A message I want to tell my baby...',
            'What made me smile today...',
          ].map((prompt) => GestureDetector(
                onTap: () {
                  _journalController.text = '$prompt\n';
                  _journalController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _journalController.text.length),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: MaaColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: MaaColors.pink.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Text('✍️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(prompt,
                            style: const TextStyle(
                                fontSize: 13,
                                color: MaaColors.textGrey)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: MaaColors.textGrey),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildYoga() {
    final yogaVideos = [
      {
        'title': 'Morning Stretch – 1st Trimester',
        'duration': '10 min',
        'emoji': '🌅',
        'level': 'Beginner',
      },
      {
        'title': 'Hip Opening Yoga – 2nd Trimester',
        'duration': '20 min',
        'emoji': '🌻',
        'level': 'Intermediate',
      },
      {
        'title': 'Breathing & Relaxation – 3rd Trimester',
        'duration': '15 min',
        'emoji': '🌺',
        'level': 'Beginner',
      },
      {
        'title': 'Prenatal Strength Flow',
        'duration': '30 min',
        'emoji': '💪',
        'level': 'Intermediate',
      },
      {
        'title': 'Evening Wind-Down Yoga',
        'duration': '12 min',
        'emoji': '🌙',
        'level': 'Beginner',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: yogaVideos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final video = yogaVideos[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MaaColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: MaaColors.cardShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(video['emoji']!,
                      style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video['title']!,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_rounded,
                            size: 14, color: MaaColors.textGrey),
                        const SizedBox(width: 4),
                        Text(video['duration']!,
                            style: const TextStyle(
                                fontSize: 12, color: MaaColors.textGrey)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: MaaColors.pink.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(video['level']!,
                              style: const TextStyle(
                                  fontSize: 10, color: MaaColors.deepPink)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_rounded,
                    color: MaaColors.deepPink, size: 36),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Starting "${video['title']!}" 🧘 You\'re doing great!')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeditation() {
    final guides = [
      {
        'title': 'Body Scan Relaxation',
        'desc': 'Release tension from head to toe',
        'duration': '10 min',
        'emoji': '🌊',
      },
      {
        'title': '4-7-8 Breathing',
        'desc': 'Calm anxiety instantly',
        'duration': '5 min',
        'emoji': '🌬️',
      },
      {
        'title': 'Loving-Kindness for Baby',
        'desc': 'Connect with your little one',
        'duration': '8 min',
        'emoji': '💕',
      },
      {
        'title': 'Sleep Meditation',
        'desc': 'Drift into restorative sleep',
        'duration': '15 min',
        'emoji': '🌙',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: guides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final guide = guides[i];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: i.isEven ? MaaColors.cardGradient : const LinearGradient(
              colors: [Color(0xFFF0E6FF), Color(0xFFE8D5F5)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(guide['emoji']!, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guide['title']!,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(guide['desc']!,
                        style: const TextStyle(
                            fontSize: 12, color: MaaColors.textGrey)),
                    const SizedBox(height: 8),
                    Text('⏱ ${guide['duration']!}',
                        style: const TextStyle(
                            fontSize: 12, color: MaaColors.deepPink)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(60, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '"${guide['title']!}" starting 🌸 Take a deep breath...')),
                  );
                },
                child: const Text('Start', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
//  Self Care Screen – MaaCare
//  Full Prenatal Yoga Guide with Trimester-wise Poses + Videos
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

// ─────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────
class YogaPose {
  final String name;
  final String sanskritName;
  final String emoji;
  final List<String> instructions;
  final String benefits;
  final String evidence;
  final String duration;
  final String calories;
  final List<String> precautions;
  final String videoUrl;

  const YogaPose({
    required this.name,
    required this.sanskritName,
    required this.emoji,
    required this.instructions,
    required this.benefits,
    required this.evidence,
    required this.duration,
    required this.calories,
    required this.precautions,
    required this.videoUrl,
  });
}

class TrimesterSection {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final List<YogaPose> poses;

  const TrimesterSection({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.poses,
  });
}

// ─────────────────────────────────────────────
// YouTube Video Links – Verified Prenatal Yoga
// ─────────────────────────────────────────────
const _trimesterData = [
  TrimesterSection(
    title: '1st Trimester',
    subtitle: 'Weeks 1–12',
    emoji: '🌱',
    color: Color(0xFF4CAF50),
    poses: [
      YogaPose(
        name: 'Cat-Cow Pose',
        sanskritName: 'Marjaryasana-Bitilasana',
        emoji: '🐱',
        instructions: [
          'Start on all fours (tabletop position) with wrists under shoulders and knees under hips.',
          'Inhale as you drop your belly, lift your chest, and look up (Cow Pose).',
          'Exhale as you round your spine, press the mat away, and tuck your chin to your chest (Cat Pose).',
          'Flow between these two poses, following your breath.',
        ],
        benefits:
            'Relieves back pain, improves spinal flexibility, and gently massages abdominal organs.',
        evidence:
            'ACOG recommends gentle stretching like Cat-Cow to alleviate common pregnancy discomforts like backaches.',
        duration: '5–10 minutes daily (10–15 reps)',
        calories: '~20–30 calories per 10 mins',
        precautions: [
          'Move slowly and mindfully with your breath.',
          'Avoid over-arching your back in Cow Pose.',
          'If you have wrist pain, place your fists on the mat instead of flat palms.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=kqnua4rHVVA',
      ),
      YogaPose(
        name: "Child's Pose",
        sanskritName: 'Balasana',
        emoji: '🧸',
        instructions: [
          'Kneel on the mat, touch your big toes together, and sit back on your heels.',
          'Spread your knees wide enough for your belly.',
          'Exhale and lay your torso down between your thighs.',
          'Rest your forehead on the floor and extend your arms forward or rest them alongside your body.',
        ],
        benefits:
            'Gently stretches hips and back, calms the mind, and relieves fatigue and stress.',
        evidence:
            'Restorative poses are known to activate the parasympathetic nervous system, reducing stress and anxiety.',
        duration: 'Hold for 30–60 seconds, repeat as needed',
        calories: 'Minimal',
        precautions: [
          'Use a pillow under your hips or forehead for extra support.',
          'Avoid if you have knee injuries.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=qZ_KBMj3MeA',
      ),
      YogaPose(
        name: 'Deep Belly Breathing',
        sanskritName: 'Diaphragmatic Breathing',
        emoji: '🌬️',
        instructions: [
          'Sit comfortably with a straight spine or lie on your side.',
          'Place one hand on your chest and the other on your belly.',
          'Inhale slowly through your nose for a count of four, feeling your belly expand.',
          'Exhale slowly through your mouth for a count of six, feeling your belly fall.',
          'Keep your chest relatively still.',
        ],
        benefits:
            'Reduces stress, improves oxygen delivery to the baby, and prepares for labor breathing.',
        evidence:
            'Studies show that deep breathing exercises can lower heart rate and blood pressure, promoting relaxation.',
        duration: '5–10 minutes, once or twice daily',
        calories: 'Minimal',
        precautions: [
          'Never hold your breath.',
          'If you feel dizzy, stop and return to normal breathing.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=YFdwHU3W69M',
      ),
      YogaPose(
        name: 'Legs-Up-the-Wall Pose (Modified)',
        sanskritName: 'Viparita Karani',
        emoji: '🦵',
        instructions: [
          'Sit sideways next to a wall.',
          'Gently swing your legs up the wall and lie back on a stack of pillows or a bolster.',
          'Your body should form a gentle angle, not a sharp 90-degree angle.',
          'Rest with your arms out to the sides, palms up.',
        ],
        benefits:
            'Reduces leg swelling, relieves tired legs and feet, and calms the nervous system.',
        evidence:
            'Inversions like this (modified safely) can improve circulation and reduce edema in the lower extremities.',
        duration: '5–10 minutes daily',
        calories: 'Minimal',
        precautions: [
          'Avoid this pose if you have high blood pressure or glaucoma.',
          'Do not lie flat on your back; use pillows to stay elevated.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=OAYToiIJFj8',
      ),
      YogaPose(
        name: 'Warrior II Pose',
        sanskritName: 'Virabhadrasana II',
        emoji: '⚔️',
        instructions: [
          'Stand with your feet wide apart.',
          'Turn your right foot out 90 degrees and your left foot in slightly.',
          'Bend your right knee over your right ankle, keeping your shin vertical.',
          'Extend your arms parallel to the floor, gazing over your right fingertips.',
          'Keep your torso centered and your hips open.',
        ],
        benefits:
            'Strengthens legs and ankles, opens hips and chest, and builds stamina and confidence.',
        evidence:
            'Standing poses build strength in the lower body, essential for supporting the extra weight of pregnancy.',
        duration: 'Hold for 30 seconds per side, 2–3 reps',
        calories: '~30–40 calories per 5 mins',
        precautions: [
          "Don't bend your front knee past your ankle.",
          'If you feel off-balance, practice near a wall for support.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=QKdfSzX_kGw',
      ),
    ],
  ),
  TrimesterSection(
    title: '2nd Trimester',
    subtitle: 'Weeks 13–26',
    emoji: '🌻',
    color: Color(0xFFFF9800),
    poses: [
      YogaPose(
        name: 'Prenatal Sun Salutation (Modified)',
        sanskritName: 'Surya Namaskar',
        emoji: '☀️',
        instructions: [
          'Start in Mountain Pose (Tadasana).',
          'Inhale and circle your arms up.',
          'Exhale and fold forward with a flat back, bending your knees as much as needed.',
          'Inhale to a halfway lift.',
          'Exhale and step back to Cat-Cow flow instead of Plank/Chaturanga.',
          'Flow through a few rounds of Cat-Cow, then return to standing.',
        ],
        benefits:
            'Warms up the entire body, improves circulation, and connects breath with movement.',
        evidence:
            'Modified Vinyasa flows are a safe way to maintain cardiovascular health during pregnancy, as per ACOG.',
        duration: '5–8 rounds, 3–4 times a week',
        calories: '~50–70 calories per 10 mins',
        precautions: [
          'Avoid jumping back or forward.',
          'Move slowly and deliberately, taking wide stances for stability.',
          'After 20 weeks, avoid lying flat on your back.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=EAguMpjhiDo',
      ),
      YogaPose(
        name: 'Goddess Pose',
        sanskritName: 'Utkata Konasana',
        emoji: '👑',
        instructions: [
          'Stand with your feet wide, toes pointing out.',
          'Exhale and bend your knees, lowering your hips into a squat.',
          'Keep your knees tracking in the same direction as your toes.',
          'Bring your hands to your heart center or extend arms out at 90 degrees.',
        ],
        benefits:
            'Strengthens the pelvic floor, inner thighs, and quadriceps. Opens the hips.',
        evidence:
            'Strengthening the pelvic floor is crucial for labor preparation and postpartum recovery.',
        duration: 'Hold for 30–60 seconds, 3–5 reps',
        calories: '~40–50 calories per 5 mins',
        precautions: [
          'Only go as deep into the squat as is comfortable.',
          'Avoid if you have pubic symphysis pain.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=cFGNPSNSmk0',
      ),
      YogaPose(
        name: 'Triangle Pose',
        sanskritName: 'Trikonasana',
        emoji: '🔺',
        instructions: [
          'Start with feet wide apart, right foot forward.',
          'Extend arms parallel to the floor.',
          'Reach forward over your right leg, then hinge at the hip, bringing your right hand to your shin or a block.',
          'Extend your left arm to the ceiling, gazing up if comfortable for your neck.',
        ],
        benefits:
            'Stretches hamstrings, hips, and spine. Relieves backache and improves balance.',
        evidence:
            'Side-body stretches create space for the growing baby and can relieve rib cage discomfort.',
        duration: 'Hold for 30 seconds per side',
        calories: '~25–35 calories per 5 mins',
        precautions: [
          'Use a yoga block for support to avoid straining.',
          'Keep your stance wide to maintain balance.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=S0PmAzSFpLY',
      ),
      YogaPose(
        name: 'Pigeon Pose (Modified)',
        sanskritName: 'Eka Pada Rajakapotasana',
        emoji: '🕊️',
        instructions: [
          'From a seated position, bring your right shin forward, parallel to the front of the mat.',
          'Extend your left leg straight behind you.',
          'Place pillows or a bolster under your right hip for support.',
          'Stay upright or fold forward over your front leg to deepen the stretch.',
        ],
        benefits:
            'Excellent for opening the hips and relieving sciatic pain, a common pregnancy complaint.',
        evidence:
            'Hip-opening poses can help prepare the pelvis for childbirth.',
        duration: '1–2 minutes per side',
        calories: 'Minimal',
        precautions: [
          'Protect your front knee by keeping your foot flexed.',
          'Support your hip to avoid pressure and ensure the stretch is in the muscle, not the joint.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=HwKa-GStBh8',
      ),
      YogaPose(
        name: 'Guided Meditation for Bonding',
        sanskritName: 'Mindfulness Practice',
        emoji: '💕',
        instructions: [
          'Sit comfortably in a quiet space.',
          'Close your eyes and focus on your breath.',
          'Bring your awareness to your belly. Picture your baby inside.',
          'Send loving thoughts and peaceful energy to your baby.',
          'You can talk to your baby silently, sharing your hopes and love.',
        ],
        benefits:
            'Reduces anxiety, strengthens the maternal-fetal bond, and promotes emotional well-being.',
        evidence:
            'Mindfulness practices are proven to reduce cortisol (stress hormone) levels in pregnant women.',
        duration: '10–15 minutes daily',
        calories: 'Minimal',
        precautions: [
          'There is no right or wrong way to do this. Simply be present.',
          'If your mind wanders, gently guide it back to your baby and your breath.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=j4XFrMTFjzM',
      ),
    ],
  ),
  TrimesterSection(
    title: '3rd Trimester',
    subtitle: 'Weeks 27–40',
    emoji: '🌺',
    color: Color(0xFFE91E8C),
    poses: [
      YogaPose(
        name: 'Supported Squat',
        sanskritName: 'Malasana',
        emoji: '🏋️',
        instructions: [
          'Stand with your feet slightly wider than your hips, toes turned out.',
          'Hold onto a sturdy chair or countertop for support.',
          'Slowly lower your hips into a deep squat, going only as low as is comfortable.',
          'Keep your heels on the floor if possible (or place a rolled towel under them).',
        ],
        benefits:
            'Prepares the pelvic floor for birth, increases circulation to the pelvis, and can help the baby descend.',
        evidence:
            'Squatting is a traditional birthing position that can help open the pelvic outlet.',
        duration: 'Hold for 30–60 seconds, rest, and repeat 3–5 times',
        calories: '~20–30 calories per 5 mins',
        precautions: [
          'Avoid if your baby is in a breech position after 34 weeks.',
          'Always use support to maintain balance and avoid falling.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=1jC5a4CLMUE',
      ),
      YogaPose(
        name: 'Side-Lying Savasana',
        sanskritName: 'Modified Savasana',
        emoji: '😴',
        instructions: [
          'Lie on your left side, which maximizes blood flow to the baby.',
          'Place a pillow between your knees and another under your head.',
          'You can also hug a bolster or large pillow in front of you for belly support.',
          'Close your eyes and focus on deep, relaxing breaths.',
        ],
        benefits:
            'The ultimate restorative pose for late pregnancy. Relieves pressure on the vena cava and allows for deep rest.',
        evidence:
            'ACOG recommends avoiding lying flat on the back in the third trimester. Side-lying is the safest resting position.',
        duration: '10–20 minutes daily',
        calories: 'Minimal',
        precautions: [
          'Ensure you are fully supported with pillows for maximum comfort.',
          'Listen to your body; if any position is uncomfortable, adjust.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=6GFvCnOF0Vs',
      ),
      YogaPose(
        name: 'Pelvic Tilts',
        sanskritName: 'Kati Chakrasana (Modified)',
        emoji: '🔄',
        instructions: [
          'Can be done standing against a wall, or on all fours (Cat-Cow).',
          'While standing, press your lower back into the wall as you exhale (tilting pelvis up).',
          'Inhale and create a small arch in your lower back (tilting pelvis back).',
          'The movement should be small and controlled.',
        ],
        benefits: 'Alleviates lower back pain and strengthens abdominal muscles.',
        evidence:
            'This exercise helps to mobilize the sacroiliac joints, which can become stiff during pregnancy.',
        duration: '10–15 reps, several times a day',
        calories: 'Minimal',
        precautions: [
          'Avoid forceful movements. This should be a gentle rocking motion.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=0mh51xuKJMs',
      ),
      YogaPose(
        name: 'Bound Angle Pose',
        sanskritName: 'Baddha Konasana',
        emoji: '🦋',
        instructions: [
          'Sit on the floor or on the edge of a folded blanket.',
          'Bring the soles of your feet together and let your knees fall out to the sides.',
          'Hold onto your ankles, lengthen your spine, and gently fold forward if comfortable.',
          'Use pillows under your knees for support.',
        ],
        benefits:
            'Stretches the inner thighs and groin, opens the hips, and can improve posture.',
        evidence:
            'Hip-opening poses are beneficial for creating flexibility and space in the pelvis for delivery.',
        duration: 'Hold for 1–2 minutes',
        calories: 'Minimal',
        precautions: [
          'Do not push your knees down. Let gravity do the work.',
          'If you have pelvic pain, keep your feet further away from your body.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=LQdl9Rm2KKo',
      ),
      YogaPose(
        name: 'Labor Breathing Practice',
        sanskritName: 'Golden Thread Breath',
        emoji: '🧵',
        instructions: [
          'Inhale slowly and deeply through your nose.',
          'Purse your lips as if you are going to blow through a straw.',
          'Exhale very slowly and steadily through your pursed lips, making the exhale twice as long as the inhale.',
          'Continue for several rounds, staying focused on the slow, steady exhale.',
        ],
        benefits:
            'Provides a powerful tool for managing pain and staying calm during labor contractions.',
        evidence:
            'Controlled breathing techniques are a cornerstone of natural childbirth methods like Lamaze and HypnoBirthing.',
        duration: '5–10 minutes, practice daily',
        calories: 'Minimal',
        precautions: [
          'Practice this regularly so it becomes second nature during labor.',
          'If you feel dizzy, return to normal breathing.',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=acUZdGd_3Gk',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJournal(),
          _buildYoga(),
          _buildMeditation(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // JOURNAL TAB
  // ──────────────────────────────────────
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
                    border:
                        Border.all(color: MaaColors.pink.withAlpha(80)),
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

  // ──────────────────────────────────────
  // YOGA TAB
  // ──────────────────────────────────────
  Widget _buildYoga() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: MaaColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🧘 Prenatal Yoga Guide',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 4),
              Text(
                '15 safe poses across all 3 trimesters. Tap any pose to see details & watch the video.',
                style: TextStyle(
                    fontSize: 12, color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),

        // Trimester Sections
        for (final section in _trimesterData) ...[
          _TrimesterHeader(section: section),
          const SizedBox(height: 12),
          for (final pose in section.poses)
            _YogaPoseCard(pose: pose, accentColor: section.color),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  // ──────────────────────────────────────
  // MEDITATION TAB
  // ──────────────────────────────────────
  Widget _buildMeditation() {
    final guides = [
      {
        'title': 'Body Scan Relaxation',
        'desc': 'Release tension from head to toe',
        'duration': '10 min',
        'emoji': '🌊',
        'videoUrl': 'https://www.youtube.com/watch?v=QS2yDmWk0vs',
      },
      {
        'title': '4-7-8 Breathing',
        'desc': 'Calm anxiety instantly',
        'duration': '5 min',
        'emoji': '🌬️',
        'videoUrl': 'https://www.youtube.com/watch?v=PmBYdfv5RSk',
      },
      {
        'title': 'Loving-Kindness for Baby',
        'desc': 'Connect with your little one',
        'duration': '8 min',
        'emoji': '💕',
        'videoUrl': 'https://www.youtube.com/watch?v=OHGK5AJXM5M',
      },
      {
        'title': 'Sleep Meditation',
        'desc': 'Drift into restorative sleep',
        'duration': '15 min',
        'emoji': '🌙',
        'videoUrl': 'https://www.youtube.com/watch?v=1vx8iUvfyCY',
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
            gradient: i.isEven
                ? MaaColors.cardGradient
                : const LinearGradient(
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
              Column(
                children: [
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
                    child:
                        const Text('Start', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _launchUrl(guide['videoUrl']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFFF0000).withAlpha(60)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill_rounded,
                              color: Color(0xFFFF0000), size: 14),
                          SizedBox(width: 4),
                          Text('YouTube',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFF0000),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────
// Trimester Header Widget
// ─────────────────────────────────────────────
class _TrimesterHeader extends StatelessWidget {
  final TrimesterSection section;
  const _TrimesterHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: section.color.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: section.color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: section.color.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(section.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: section.color)),
              Text(section.subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: MaaColors.textGrey)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: section.color.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${section.poses.length} poses',
                style: TextStyle(
                    fontSize: 11,
                    color: section.color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Yoga Pose Card (Expandable + Video Button)
// ─────────────────────────────────────────────
class _YogaPoseCard extends StatefulWidget {
  final YogaPose pose;
  final Color accentColor;

  const _YogaPoseCard({required this.pose, required this.accentColor});

  @override
  State<_YogaPoseCard> createState() => _YogaPoseCardState();
}

class _YogaPoseCardState extends State<_YogaPoseCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _openVideo() async {
    final uri = Uri.parse(widget.pose.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pose = widget.pose;
    final color = widget.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Header Row (always visible) ──
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Emoji icon box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(pose.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pose.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(pose.sanskritName,
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 12, color: MaaColors.textGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pose.duration,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: MaaColors.textGrey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand arrow
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: color,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable Details ──
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: color.withAlpha(60), thickness: 1),
                  const SizedBox(height: 10),

                  // 🎬 Watch Video Button
                  GestureDetector(
                    onTap: _openVideo,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0000).withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_filled_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Watch Video on YouTube',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Instructions
                  _SectionTitle(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'Instructions',
                      color: color),
                  const SizedBox(height: 8),
                  ...pose.instructions.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin:
                                  const EdgeInsets.only(top: 1, right: 10),
                              decoration: BoxDecoration(
                                color: color.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${e.key + 1}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: color)),
                              ),
                            ),
                            Expanded(
                              child: Text(e.value,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: MaaColors.textGrey,
                                      height: 1.5)),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 12),

                  // Benefits
                  _SectionTitle(
                      icon: Icons.favorite_rounded,
                      label: 'Target Benefits',
                      color: color),
                  const SizedBox(height: 6),
                  _InfoBox(text: pose.benefits, color: color),

                  const SizedBox(height: 10),

                  // Evidence
                  _SectionTitle(
                      icon: Icons.science_rounded,
                      label: 'Evidence',
                      color: color),
                  const SizedBox(height: 6),
                  _InfoBox(text: pose.evidence, color: color),

                  const SizedBox(height: 10),

                  // Calorie chip
                  _StatChip(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Calorie Burn',
                    value: pose.calories,
                    color: color,
                  ),

                  const SizedBox(height: 10),

                  // Precautions
                  const _SectionTitle(
                      icon: Icons.warning_amber_rounded,
                      label: 'Precautions & Modifications',
                      color: Color(0xFFFF9800)),
                  const SizedBox(height: 8),
                  ...pose.precautions.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(p,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: MaaColors.textGrey,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: MaaColors.textGrey, height: 1.5)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 11, color: MaaColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

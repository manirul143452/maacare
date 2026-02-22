// ============================================================
//  FamilyPlanningScreen – MaaCare
//  Fertility tips, contraception guide, and AI quiz
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

class FamilyPlanningScreen extends StatefulWidget {
  const FamilyPlanningScreen({super.key});

  @override
  State<FamilyPlanningScreen> createState() => _FamilyPlanningScreenState();
}

class _FamilyPlanningScreenState extends State<FamilyPlanningScreen> {
  int _quizStep = 0;
  final Map<int, String> _answers = {};

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'What is your primary goal?',
      'options': ['Planning for next baby', 'Preventing pregnancy', 'General knowledge'],
    },
    {
      'question': 'How old are you?',
      'options': ['Under 25', '25-35', 'Over 35'],
    },
    {
      'question': 'Any existing health conditions?',
      'options': ['None', 'Migraines/BP', 'Others'],
    }
  ];

  String _getRecommendation() {
    // Simple high-class decision algorithm
    final goal = _answers[0];
    final health = _answers[2];

    if (goal == 'Planning for next baby') {
      return '🌸 Based on your goal, we recommend tracking your ovulation and focusing on prenatal vitamins. Consult our AI for a detailed cycle map!';
    } else if (health == 'Migraines/BP') {
      return '🛡️ Safety first! Since you have certain conditions, non-hormonal methods like IUD or Barrier methods are often 85% more suitable. Please consult your doctor for a final decision.';
    } else {
      return '✨ You have several great options! A combined pill or hormonal IUD is 99% effective for most Mamas in your age group. Tap below to chat with Maa AI for details.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Planning 👨‍👩‍👧')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildQuizSection(),
            const SizedBox(height: 32),
            _buildContraceptionGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection() {
    if (_quizStep >= _quizQuestions.length) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: MaaColors.softPurple.withAlpha(50),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: MaaColors.deepPink.withAlpha(50)),
        ),
        child: Column(
          children: [
            const Text('🎯 AI Recommendation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(_getRecommendation(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 20),
            MaaButton(
              label: 'Reset Quiz',
              outlined: true,
              onPressed: () => setState(() {
                _quizStep = 0;
                _answers.clear();
              }),
            ),
          ],
        ),
      ).animate().fadeIn().scale();
    }

    final q = _quizQuestions[_quizStep];
    return Column(
      children: [
        const Text('Let\'s find what\'s best for you! ✨', style: TextStyle(fontSize: 14, color: MaaColors.textGrey)),
        const SizedBox(height: 20),
        Text(q['question'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ... (q['options'] as List<String>).map((opt) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MaaButton(
            label: opt,
            outlined: true,
            onPressed: () => setState(() {
              _answers[_quizStep] = opt;
              _quizStep++;
            }),
          ),
        )),
      ],
    ).animate().fadeIn().moveY(begin: 10, end: 0);
  }

  Widget _buildContraceptionGuide() {
    final methods = [
      {'name': 'IUD (Intrauterine Device)', 'pro': 'Highly effective (99%)', 'con': 'Needs medical procedure'},
      {'name': 'Condoms (Barrier)', 'pro': 'No hormones, prevents STIs', 'con': 'Higher failure rate if misused'},
      {'name': 'The Pill', 'pro': 'Easy to use, predictable', 'con': 'Must remember daily'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Guide 📖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...methods.map((m) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: MaaColors.deepPink)),
                const SizedBox(height: 8),
                Text('✅ Pro: ${m['pro']}', style: const TextStyle(fontSize: 12, color: MaaColors.textGrey)),
                Text('❌ Con: ${m['con']}', style: const TextStyle(fontSize: 12, color: MaaColors.textGrey)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

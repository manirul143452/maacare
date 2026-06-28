// ============================================================
//  BMI & Calorie Calculator Widget – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BmiCalorieCalculatorScreen extends StatefulWidget {
  const BmiCalorieCalculatorScreen({super.key});

  @override
  State<BmiCalorieCalculatorScreen> createState() =>
      _BmiCalorieCalculatorScreenState();
}

class _BmiCalorieCalculatorScreenState
    extends State<BmiCalorieCalculatorScreen> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  double? _bmi;
  String _bmiCategory = '';
  Color _bmiColor = Colors.green;

  double? _bmr;
  double? _tdee;
  double? _totalCal;
  int _activityIndex = 1;
  int _trimesterIndex = 0;

  final _activityLevels = [
    {'label': 'Sedentary', 'desc': 'Little or no exercise', 'factor': 1.2, 'emoji': '🛋️'},
    {'label': 'Light', 'desc': 'Walking 1–3 days/week', 'factor': 1.375, 'emoji': '🚶'},
    {'label': 'Moderate', 'desc': 'Exercise 3–5 days/week', 'factor': 1.55, 'emoji': '🏃'},
    {'label': 'Active', 'desc': 'Hard exercise 6–7 days', 'factor': 1.725, 'emoji': '💪'},
    {'label': 'Very Active', 'desc': 'Athlete / physical job', 'factor': 1.9, 'emoji': '🏋️'},
  ];

  final _trimesterOptions = [
    {'label': 'Not Pregnant', 'extra': 0, 'emoji': '👩'},
    {'label': '1st Trimester', 'extra': 0, 'emoji': '🌱'},
    {'label': '2nd Trimester', 'extra': 340, 'emoji': '🌻'},
    {'label': '3rd Trimester', 'extra': 452, 'emoji': '🌺'},
  ];

  void _calculateAll() {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    final a = double.tryParse(_ageCtrl.text);

    if (w == null || h == null || a == null || h == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all fields correctly')),
      );
      return;
    }

    final heightM = h / 100;
    final bmi = w / (heightM * heightM);

    String cat;
    Color col;
    if (bmi < 18.5) {
      cat = 'Underweight';
      col = const Color(0xFF42A5F5);
    } else if (bmi < 25) {
      cat = 'Normal Weight ✅';
      col = const Color(0xFF4CAF50);
    } else if (bmi < 30) {
      cat = 'Overweight';
      col = const Color(0xFFFF9800);
    } else {
      cat = 'Obese';
      col = const Color(0xFFEF5350);
    }

    // Harris-Benedict equation (women)
    final bmr = 655.1 + (9.563 * w) + (1.850 * h) - (4.676 * a);
    final factor = _activityLevels[_activityIndex]['factor'] as double;
    final tdee = bmr * factor;

    // Time-based Sync: Auto calculate trimester based on current pregnancyWeek
    final user = context.read<UserProvider>().user;
    int week = user?.pregnancyWeek ?? 0;
    
    if (week > 0) {
      if (week <= 13) {
        _trimesterIndex = 1;
      } else if (week <= 26) {
        _trimesterIndex = 2;
      } else {
        _trimesterIndex = 3;
      }
    } else {
      _trimesterIndex = 0; // Not Pregnant
    }

    final extra = _trimesterOptions[_trimesterIndex]['extra'] as int;

    setState(() {
      _bmi = bmi;
      _bmiCategory = cat;
      _bmiColor = col;
      _bmr = bmr;
      _tdee = tdee;
      _totalCal = tdee + extra;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header
            GlassContainer(
              padding: const EdgeInsets.all(16),
              backgroundColor: MaaColors.pink.withAlpha(20),
              borderColor: MaaColors.pink.withAlpha(50),
              child: Row(
                children: [
                  const Text('⚖️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).bmiTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(
                          AppLocalizations.of(context).bmiSubtitle,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Fields
            _SectionTitle(title: '📋 ${AppLocalizations.of(context).yourDetails}'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _weightCtrl,
                    label: AppLocalizations.of(context).weight,
                    hint: '60',
                    suffix: 'kg',
                    emoji: '⚖️',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _heightCtrl,
                    label: AppLocalizations.of(context).height,
                    hint: '162',
                    suffix: 'cm',
                    emoji: '📏',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputField(
                    controller: _ageCtrl,
                    label: AppLocalizations.of(context).age,
                    hint: '28',
                    suffix: 'yrs',
                    emoji: '🎂',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Activity Level
            _SectionTitle(title: '🏃 ${AppLocalizations.of(context).activityLevel}'),
            const SizedBox(height: 10),
            ...List.generate(_activityLevels.length, (i) {
              final a = _activityLevels[i];
              final selected = _activityIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _activityIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? MaaColors.deepPink.withAlpha(25)
                        : MaaColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? MaaColors.deepPink
                          : MaaColors.textGrey.withAlpha(60),
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: MaaColors.deepPink.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(a['emoji'] as String,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['label'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? MaaColors.deepPink
                                        : Colors.black87)),
                            Text(a['desc'] as String,
                                style: const TextStyle(
                                    fontSize: 11, color: MaaColors.textGrey)),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded,
                            color: MaaColors.deepPink, size: 20),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: MaaColors.deepPink.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _calculateAll,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calculate_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).calculateNow,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),

            // ── RESULTS ──
            if (_bmi != null) ...[
              const SizedBox(height: 28),

              // BMI Result
              const _SectionTitle(title: '⚖️ Your BMI Result'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MaaColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _bmiColor.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _bmi!.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: _bmiColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 4),
                          child: Text('kg/m²',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: _bmiColor.withAlpha(180))),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: _bmiColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(_bmiCategory,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _bmiColor)),
                    ),
                    const SizedBox(height: 20),

                    // BMI Gauge
                    _BmiGauge(bmi: _bmi!),
                    const SizedBox(height: 16),

                    // BMI reference
                    _bmiRow('< 18.5', 'Underweight', const Color(0xFF42A5F5)),
                    _bmiRow('18.5 – 24.9', 'Normal Weight', const Color(0xFF4CAF50)),
                    _bmiRow('25.0 – 29.9', 'Overweight', const Color(0xFFFF9800)),
                    _bmiRow('≥ 30.0', 'Obese', const Color(0xFFEF5350)),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⚠️', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'BMI is not accurate during pregnancy. Always consult your doctor for pregnancy weight guidance.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF795548),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Calorie Results
              const _SectionTitle(title: '🔥 Daily Calorie Breakdown'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ResultCard(
                      title: 'BMR',
                      subtitle: 'Calories at complete rest',
                      value: _bmr!,
                      emoji: '😴',
                      color: const Color(0xFF42A5F5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultCard(
                      title: 'TDEE',
                      subtitle: 'With daily activity',
                      value: _tdee!,
                      emoji: '🏃',
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: MaaColors.deepPink.withAlpha(70),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('✨ Recommended Daily Intake',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${_totalCal!.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      _trimesterIndex == 0
                          ? 'Based on ${_activityLevels[_activityIndex]['label']} activity level'
                          : 'Includes +${_trimesterOptions[_trimesterIndex]['extra']} kcal for ${_trimesterOptions[_trimesterIndex]['label']} 👶',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Meal Split
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 Suggested Meal Split',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B1FA2))),
                    const SizedBox(height: 10),
                    _mealRow('🌅', 'Breakfast', 0.25),
                    _mealRow('☀️', 'Lunch', 0.35),
                    _mealRow('🌆', 'Dinner', 0.30),
                    _mealRow('🍎', 'Snacks', 0.10),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      );
  }

  Widget _bmiRow(String range, String cat, Color color) {
    final isCurrent = _bmiCategory.contains(cat.split(' ').first);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? color.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(range,
              style: const TextStyle(
                  fontSize: 12, color: MaaColors.textGrey)),
          const Spacer(),
          Text(cat,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
          if (isCurrent) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('You',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealRow(String emoji, String meal, double pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(meal,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%  •  ${(_totalCal! * pct).toStringAsFixed(0)} kcal',
            style:
                const TextStyle(fontSize: 12, color: MaaColors.textGrey),
          ),
        ],
      ),
    );
  }
}

// ── BMI Gradient Gauge ──
class _BmiGauge extends StatelessWidget {
  final double bmi;
  const _BmiGauge({required this.bmi});

  @override
  Widget build(BuildContext context) {
    final clamped = bmi.clamp(15.0, 40.0);
    final pct = (clamped - 15) / (40 - 15);
    final screenW = MediaQuery.of(context).size.width - 80;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF42A5F5),
                    Color(0xFF4CAF50),
                    Color(0xFFFF9800),
                    Color(0xFFEF5350),
                  ],
                  stops: [0.0, 0.28, 0.56, 1.0],
                ),
              ),
            ),
            Positioned(
              left: (screenW * pct).clamp(0, screenW - 22),
              top: -3,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(50), blurRadius: 6)
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('15', style: TextStyle(fontSize: 9, color: MaaColors.textGrey)),
            Text('18.5', style: TextStyle(fontSize: 9, color: MaaColors.textGrey)),
            Text('25', style: TextStyle(fontSize: 9, color: MaaColors.textGrey)),
            Text('30', style: TextStyle(fontSize: 9, color: MaaColors.textGrey)),
            Text('40+', style: TextStyle(fontSize: 9, color: MaaColors.textGrey)),
          ],
        ),
      ],
    );
  }
}

// ── Result Card ──
class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final String emoji;
  final Color color;

  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text('${value.toStringAsFixed(0)} kcal',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 10, color: MaaColors.textGrey)),
        ],
      ),
    );
  }
}

// ── Input Field ──
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final String emoji;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$emoji $label',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MaaColors.textGrey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Section Title ──
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87));
  }
}

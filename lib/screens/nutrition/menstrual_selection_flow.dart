// ============================================================
//  MenstrualSelectionFlow – MaaCare
//  Phase-aligned nutrition entry for Unmarried Girl role
//  Reads live phase from MenstrualProvider → routes to plan
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../providers/menstrual_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../widgets/premium_paywall_sheet.dart';
import 'menstrual_plan_view.dart';

// ── Phase data model ────────────────────────────────────────────────────────
class PhaseInfo {
  final String key;          // matches MenstrualProvider.cyclePhase
  final String name;
  final String emoji;
  final String subtitle;
  final String focus;
  final String seedCycle;    // seed cycling recommendation
  final String primaryColor;
  final List<Color> gradient;
  final List<String> keyNutrients;
  final List<String> avoidFoods;

  const PhaseInfo({
    required this.key,
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.focus,
    required this.seedCycle,
    required this.primaryColor,
    required this.gradient,
    required this.keyNutrients,
    required this.avoidFoods,
  });
}

const List<PhaseInfo> _phases = [
  PhaseInfo(
    key: 'Menstrual',
    name: 'Menstrual Phase',
    emoji: '🩸',
    subtitle: 'Days 1–5 • Shedding',
    focus: 'Iron Replenishment & Cramp Mitigation',
    seedCycle: 'Flax Seeds + Pumpkin Seeds',
    primaryColor: '#E53935',
    gradient: [Color(0xFFE53935), Color(0xFFC62828)],
    keyNutrients: ['Iron 🩸', 'Magnesium 💊', 'Omega-3 🐟', 'Vitamin C 🍊', 'Zinc ⚡'],
    avoidFoods: ['Caffeine', 'Alcohol', 'Salty snacks', 'Refined sugar'],
  ),
  PhaseInfo(
    key: 'Follicular',
    name: 'Follicular Phase',
    emoji: '🌱',
    subtitle: 'Days 6–13 • Rising energy',
    focus: 'Estrogen Balance & Stamina Building',
    seedCycle: 'Flax Seeds + Pumpkin Seeds',
    primaryColor: '#43A047',
    gradient: [Color(0xFF43A047), Color(0xFF2E7D32)],
    keyNutrients: ['B Vitamins 🌿', 'Probiotics 🥛', 'Zinc ⚡', 'Fiber 🥦', 'Lean Protein 🍗'],
    avoidFoods: ['Processed foods', 'Trans fats', 'Excess dairy'],
  ),
  PhaseInfo(
    key: 'Ovulatory',
    name: 'Ovulatory Phase',
    emoji: '🌸',
    subtitle: 'Days 14–16 • Peak fertility',
    focus: 'Peak Fertility Awareness & Anti-Inflammation',
    seedCycle: 'Sesame Seeds + Sunflower Seeds',
    primaryColor: '#F06292',
    gradient: [Color(0xFFF06292), Color(0xFFE91E63)],
    keyNutrients: ['Antioxidants 🫐', 'Glutathione 🥑', 'Fiber 🥦', 'Vitamin E 🌻', 'B6 🍌'],
    avoidFoods: ['Fried foods', 'Gluten excess', 'Sugar spikes'],
  ),
  PhaseInfo(
    key: 'Luteal',
    name: 'Luteal Phase',
    emoji: '🌙',
    subtitle: 'Days 17–28 • PMS window',
    focus: 'Progesterone Support & PMS Bloat Control',
    seedCycle: 'Sesame Seeds + Sunflower Seeds',
    primaryColor: '#7B1FA2',
    gradient: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
    keyNutrients: ['Magnesium 💜', 'Calcium 🥛', 'B6 🍌', 'Complex Carbs 🍠', 'Dark Choc 🍫'],
    avoidFoods: ['Caffeine', 'Sodium excess', 'Alcohol', 'Refined carbs'],
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────
class MenstrualSelectionFlow extends StatefulWidget {
  const MenstrualSelectionFlow({super.key});

  @override
  State<MenstrualSelectionFlow> createState() => _MenstrualSelectionFlowState();
}

class _MenstrualSelectionFlowState extends State<MenstrualSelectionFlow> {
  String? _selectedPhaseKey;

  @override
  void initState() {
    super.initState();
    // Auto-select current phase from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phase = context.read<MenstrualProvider>().cyclePhase;
      setState(() => _selectedPhaseKey = phase);

      final userId = context.read<UserProvider>().user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<NutritionProvider>().loadCounts(userId);
      }
    });
  }

  void _proceed() {
    final userProvider = context.read<UserProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;

    if (!isPremium && nutritionProvider.freeCycleGenerationCount >= 6) {
      PremiumPaywallSheet.show(context);
      return;
    }

    if (_selectedPhaseKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your current cycle phase.')),
      );
      return;
    }

    final phase = _phases.firstWhere((p) => p.key == _selectedPhaseKey);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenstrualPlanView(phase: phase),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menstrualProvider = context.watch<MenstrualProvider>();
    final autoPhase = menstrualProvider.cyclePhase;
    final userProvider = context.watch<UserProvider>();
    final nutritionProvider = context.watch<NutritionProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final remainingUses = 6 - nutritionProvider.freeCycleGenerationCount;

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cycle Nutrition Planner',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header Banner ──────────────────────────────────────────
              _buildHeaderBanner(autoPhase).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 28),

              // ── Section label ──────────────────────────────────────────
              Text(
                'Select Your Current Phase',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Auto-detected from your cycle logs. Tap to override.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
              ),
              const SizedBox(height: 16),

              // ── Phase Cards Grid ───────────────────────────────────────
              ...List.generate(_phases.length, (i) {
                final phase = _phases[i];
                final isSelected = _selectedPhaseKey == phase.key;
                final isAuto = autoPhase == phase.key;

                return _buildPhaseCard(
                  phase: phase,
                  isSelected: isSelected,
                  isAuto: isAuto,
                  index: i,
                  onTap: () => setState(() => _selectedPhaseKey = phase.key),
                );
              }),

              const SizedBox(height: 12),

              // ── Trial counter ──────────────────────────────────────────
              if (!isPremium && remainingUses > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '🎁 Free Trial: $remainingUses uses left',
                    style: GoogleFonts.poppins(
                      color: MaaColors.pink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── CTA ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPhaseKey != null ? _proceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaaColors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 8,
                    shadowColor: MaaColors.pink.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🥗', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(
                        'Generate My Phase Plan ✨',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(String autoPhase) {
    final currentPhase = _phases.firstWhere(
      (p) => p.key == autoPhase,
      orElse: () => _phases[0],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            currentPhase.gradient[0].withValues(alpha: 0.3),
            currentPhase.gradient[1].withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentPhase.gradient[0].withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: currentPhase.gradient[0].withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(currentPhase.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are in ${currentPhase.name}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  currentPhase.subtitle,
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentPhase.gradient[0].withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Focus: ${currentPhase.focus}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard({
    required PhaseInfo phase,
    required bool isSelected,
    required bool isAuto,
    required int index,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    phase.gradient[0].withValues(alpha: 0.25),
                    phase.gradient[1].withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : MaaColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? phase.gradient[0].withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: phase.gradient[0].withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Phase icon circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: phase.gradient[0].withValues(alpha: isSelected ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(phase.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            phase.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isAuto) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: phase.gradient[0].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Current',
                                style: GoogleFonts.poppins(
                                  color: phase.gradient[0],
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        phase.subtitle,
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? phase.gradient[0] : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? phase.gradient[0] : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),

            if (isSelected) ...[
              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),

              // Focus label
              Text(
                '🎯 Focus: ${phase.focus}',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Seed cycling
              Row(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Seed Cycle: ${phase.seedCycle}',
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Key Nutrients
              Text(
                'Key Nutrients',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: phase.keyNutrients.map((n) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: phase.gradient[0].withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: phase.gradient[0].withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    n,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 10),

              // Avoid foods
              Text(
                'Limit / Avoid',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: phase.avoidFoods.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '🚫 $f',
                    style: GoogleFonts.poppins(color: Colors.redAccent.shade100, fontSize: 10),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.05, end: 0),
    );
  }
}

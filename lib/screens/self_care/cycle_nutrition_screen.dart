// ============================================================
//  CycleNutritionScreen – MaaCare
//  Personalized AI nutrition plan generation based on cycle phase
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'dart:ui';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../widgets/premium_paywall_sheet.dart';
import '../../app_theme.dart';
import '../../providers/menstrual_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../widgets/maa_button.dart';

class CycleNutritionScreen extends StatefulWidget {
  const CycleNutritionScreen({super.key});

  @override
  State<CycleNutritionScreen> createState() => _CycleNutritionScreenState();
}

class _CycleNutritionScreenState extends State<CycleNutritionScreen> {
  bool _isGenerating = false;
  String? _nutritionPlan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserProvider>().user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<NutritionProvider>().loadCounts(userId);
      }
    });
  }

  // Typical requirements overview per phase
  final Map<String, Map<String, String>> _phaseDetails = {
    'menstrual': {
      'focus': 'Iron Replenishment & Uterine Support 🩸',
      'desc': 'During menstruation, focus on replenishing iron loss, soothing muscle contractions, and boosting hydration.',
      'foods': 'Spinach, beetroot, lentils, chia seeds, ginger tea, warm vegetable soups, wild fish.',
    },
    'follicular': {
      'focus': 'Estrogen Building & Energy Metabolism 🌱',
      'desc': 'As estrogen levels rise, support metabolic activity, energy replenishment, and balanced glucose levels.',
      'foods': 'Fermented foods (kimchi, kefir), broccoli, sprouts, avocados, light quinoa, nuts, green tea.',
    },
    'ovulatory': {
      'focus': 'Anti-inflammatory & Estrogen Clearance 🌸',
      'desc': 'Clear estrogen surges through fiber-dense items and antioxidants, keeping energy stable and reducing inflammation.',
      'foods': 'Berries, almonds, pumpkin seeds, fresh smoothies, kale, raw vegetables, healthy fats.',
    },
    'luteal': {
      'focus': 'Magnesium Boost & PMS Control 🌙',
      'desc': 'Support progesterone production, curb sweet cravings, and reduce water retention and mood swings.',
      'foods': 'Sweet potatoes, dark chocolate (70%+), bananas, brown rice, seeds, chamomile tea.',
    },
  };

  Future<void> _generateNutritionPlan(String phase) async {
    final userProvider = context.read<UserProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final userId = userProvider.user?.id ?? '';

    if (!isPremium && nutritionProvider.freeCycleGenerationCount >= 6) {
      PremiumPaywallSheet.show(context);
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _nutritionPlan = null;
    });

    final prompt = 'You are an expert gynecologist and reproductive nutritionist. '
        'Generate a detailed, hormone-balancing meal and nutrition plan in markdown format for a user currently in the "$phase" phase of their menstrual cycle. '
        'Provide a concrete daily meal matrix (Breakfast, Lunch, Snacks, Dinner), explain the metabolic role of key nutrients needed (e.g., iron, magnesium, fiber, healthy fats), and share actionable tips to manage cravings or cramps.';

    try {
      final messages = [
        {
          'role': 'user',
          'content': 'Please generate my personalized $phase phase nutrition plan.'
        }
      ];

      final result = await MaaCareBackendService.instance.invokeAiChat(messages, systemPrompt: prompt);
      
      if (result != null && result['data'] != null && result['data']['choices'] != null) {
        final content = result['data']['choices'][0]['message']['content'] as String?;
        setState(() {
          _nutritionPlan = content ?? 'Error: Empty plan generated.';
        });
        
        if (!isPremium) {
          await nutritionProvider.incrementCycleCount(userId);
        }
      } else {
        setState(() {
          _errorMessage = 'API error: Could not retrieve a valid AI response. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection Exception: $e. Please verify internet access and try again.';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final nutritionProvider = context.watch<NutritionProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final remainingUses = 6 - nutritionProvider.freeCycleGenerationCount;
    final isUnlocked = isPremium || remainingUses > 0;
    final menstrualProvider = context.watch<MenstrualProvider>();
    final rawPhase = menstrualProvider.cyclePhase.toLowerCase();
    
    // Normalize phase
    String currentPhase = 'menstrual';
    if (rawPhase.contains('follicular')) currentPhase = 'follicular';
    if (rawPhase.contains('ovulatory')) currentPhase = 'ovulatory';
    if (rawPhase.contains('luteal')) currentPhase = 'luteal';

    final details = _phaseDetails[currentPhase] ?? _phaseDetails['menstrual']!;

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: Text(
          'AI Menstrual Nutrition Planner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase info Card
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, color: MaaColors.pink, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Current Cycle Phase: ${menstrualProvider.cyclePhase}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        details['focus']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: MaaColors.pink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details['desc']!,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      Text(
                        'Recommended Foods:',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        details['foods']!,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI Action Button
                MaaButton(
                  label: _isGenerating ? 'Analyzing Hormonal Ratios...' : 'Generate Personalized AI Plan 🥗',
                  isLoading: _isGenerating,
                  onPressed: _isGenerating ? null : () => _generateNutritionPlan(menstrualProvider.cyclePhase),
                ),
                if (!isPremium && remainingUses > 0) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '🎁 Free Trial: $remainingUses uses left',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Result viewport
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                    ),
                  )
                else if (_nutritionPlan != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Hormone-Balancing Plan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Markdown(
                          data: _nutritionPlan!,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.6),
                            h1: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            h2: GoogleFonts.poppins(color: MaaColors.pink, fontSize: 15, fontWeight: FontWeight.bold),
                            h3: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            listBullet: const TextStyle(color: MaaColors.pink),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn().moveY(begin: 15, end: 0)
                else if (!_isGenerating)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white24, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Tap above to compile a phase-specific hormonal meal matrix custom generated by AI.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (!isUnlocked)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, color: Colors.pinkAccent, size: 50)
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 2.seconds),
                            const SizedBox(height: 16),
                            Text(
                              'Premium Feature',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unlock personalized AI-generated hormone-balancing nutrition plans with MaaCare Elite Pass.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => PremiumPaywallSheet.show(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: Colors.pinkAccent.withValues(alpha: 0.4),
                              ),
                              child: Text(
                                'Unlock Elite Pass',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

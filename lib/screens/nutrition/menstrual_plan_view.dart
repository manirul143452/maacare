// ============================================================
//  MenstrualPlanView – MaaCare
//  Time-based hormone-aligned nutrition plan for Unmarried Girls
//  Integrates inline soundscape audio triggers per meal slot
// ============================================================

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../theme/menstrual_medical_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../widgets/premium_paywall_sheet.dart';
import 'menstrual_selection_flow.dart';

// ── Phase-specific meal matrix ───────────────────────────────────────────────
class _MealSlot {
  final String time;
  final String icon;
  final String label;
  final String soundLabel;
  final String soundUrl;
  final IconData soundIcon;
  final Color soundColor;

  const _MealSlot({
    required this.time,
    required this.icon,
    required this.label,
    required this.soundLabel,
    required this.soundUrl,
    required this.soundIcon,
    required this.soundColor,
  });
}

// CORS-safe Pixabay tracks
const String _morningTrack  = 'https://cdn.pixabay.com/audio/2022/03/15/audio_c8c8a73467.mp3';
const String _focusTrack    = 'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3';
const String _eveningTrack  = 'https://cdn.pixabay.com/audio/2022/03/15/audio_c8c8a73467.mp3';
const String _sleepTrack    = 'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3';

const List<_MealSlot> _mealSlots = [
  _MealSlot(
    time: '08:00 AM',
    icon: '🌅',
    label: 'Breakfast',
    soundLabel: '▶ Morning Soundscape',
    soundUrl: _morningTrack,
    soundIcon: Icons.wb_sunny_rounded,
    soundColor: Color(0xFFFFB300),
  ),
  _MealSlot(
    time: '01:30 PM',
    icon: '☀️',
    label: 'Lunch',
    soundLabel: '▶ Focus Acoustic Track',
    soundUrl: _focusTrack,
    soundIcon: Icons.self_improvement_rounded,
    soundColor: Color(0xFF29B6F6),
  ),
  _MealSlot(
    time: '05:30 PM',
    icon: '🌆',
    label: 'Evening Snack',
    soundLabel: '▶ Calm Evening Loop',
    soundUrl: _eveningTrack,
    soundIcon: Icons.spa_rounded,
    soundColor: Color(0xFFA5D6A7),
  ),
  _MealSlot(
    time: '08:30 PM',
    icon: '🌌',
    label: 'Dinner',
    soundLabel: '🎵 Sleep Binaural Beats',
    soundUrl: _sleepTrack,
    soundIcon: Icons.nights_stay_rounded,
    soundColor: Color(0xFF9C27B0),
  ),
];

// ── Phase-specific default meal content ─────────────────────────────────────
Map<String, String> _defaultMealContent(PhaseInfo phase) {
  switch (phase.key) {
    case 'Menstrual':
      return {
        'Breakfast':     'Warm oatmeal with flax seeds, chia pudding, beetroot juice, iron-fortified cereal with almond milk.',
        'Lunch':         'Lentil soup (dal) + spinach sabzi + brown rice + lemon squeezed on top for Vitamin C to boost iron absorption.',
        'Evening Snack': 'Dates + almonds + warm ginger-turmeric latte. Dark chocolate (70%+) for magnesium cramp relief.',
        'Dinner':        'Grilled fish or tofu + sautéed leafy greens + warm vegetable broth + chamomile tea before sleep.',
      };
    case 'Follicular':
      return {
        'Breakfast':     'Vegetable smoothie bowl (kale, spinach, banana) + sprout salad + flax seed-enriched yogurt.',
        'Lunch':         'Quinoa + stir-fried broccoli + fermented kimchi/curd + lean chicken/paneer for protein boost.',
        'Evening Snack': 'Avocado on whole-grain toast + green tea + pumpkin seeds.',
        'Dinner':        'Light dal tadka + sautéed zucchini + brown rice. Warm turmeric milk for anti-inflammation.',
      };
    case 'Ovulatory':
      return {
        'Breakfast':     'Berry smoothie (blueberry, strawberry) + sunflower seeds + whole grain toast with peanut butter.',
        'Lunch':         'High-fiber salad (kale, chickpeas, quinoa) + olive oil dressing + grilled salmon or paneer.',
        'Evening Snack': 'Fresh fruit bowl (papaya, kiwi, orange) — antioxidant-dense to support estrogen clearance.',
        'Dinner':        'Stir-fried veggies + sesame seeds + light tofu curry. Chamomile or peppermint herbal tea.',
      };
    case 'Luteal':
    default:
      return {
        'Breakfast':     'Sweet potato hash + sesame seeds + banana smoothie with almond butter. Complex carbs for serotonin.',
        'Lunch':         'Brown rice + high-magnesium dal (black beans) + sautéed mushrooms + calcium-rich curd.',
        'Evening Snack': 'Dark chocolate (70%+) + handful of walnuts + warm chamomile tea for PMS craving control.',
        'Dinner':        'Anti-inflammatory turmeric chicken/chickpea curry + quinoa + warm milk with nutmeg for sleep.',
      };
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────
class MenstrualPlanView extends StatefulWidget {
  final PhaseInfo phase;

  const MenstrualPlanView({super.key, required this.phase});

  @override
  State<MenstrualPlanView> createState() => _MenstrualPlanViewState();
}

class _MenstrualPlanViewState extends State<MenstrualPlanView> {
  late AudioPlayer _audioPlayer;
  String? _playingTrackUrl;
  bool _isAudioPlaying = false;

  // AI plan state
  bool _isGenerating = false;
  String? _aiPlan;
  String? _aiError;

  late Map<String, String> _mealContent;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _mealContent = _defaultMealContent(widget.phase);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isAudioPlaying = state == PlayerState.playing);
        if (state == PlayerState.completed) {
          setState(() => _playingTrackUrl = null);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserProvider>().user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<NutritionProvider>().loadCounts(userId);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url) async {
    if (_playingTrackUrl == url && _isAudioPlaying) {
      await _audioPlayer.pause();
      setState(() => _isAudioPlaying = false);
    } else {
      await _audioPlayer.stop();
      setState(() {
        _playingTrackUrl = url;
        _isAudioPlaying = false;
      });
      await _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _generateAIPlan() async {
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
      _aiError = null;
      _aiPlan = null;
    });

    final prompt =
        'You are an expert gynecologist and reproductive nutritionist specialized in menstrual health. '
        'Generate a detailed, hormone-balancing meal and nutrition plan in clean Markdown format '
        'for a young woman currently in the "${widget.phase.name}" phase of her menstrual cycle. '
        'Phase focus: ${widget.phase.focus}. '
        'Provide: '
        '1) A concrete daily meal matrix (Breakfast 8AM, Lunch 1:30PM, Evening Snack 5:30PM, Dinner 8:30PM), '
        '2) Phase-specific seed cycling recommendations (${widget.phase.seedCycle}), '
        '3) Key nutrients to prioritize: ${widget.phase.keyNutrients.join(", ")}, '
        '4) Foods to avoid: ${widget.phase.avoidFoods.join(", ")}, '
        '5) Hydration and herbal tea recommendations, '
        '6) 3 actionable lifestyle tips to manage ${widget.phase.key == "Menstrual" ? "cramps and fatigue" : widget.phase.key == "Luteal" ? "PMS symptoms and bloating" : "energy and mood"}. '
        'Keep all recommendations specific to Indian/South Asian regional foods where possible.';

    try {
      final result = await MaaCareBackendService.instance.invokeAiChat(
        [{'role': 'user', 'content': 'Generate my ${widget.phase.name} nutrition plan.'}],
        systemPrompt: prompt,
      );

      if (result != null &&
          result['data'] != null &&
          result['data']['choices'] != null) {
        final content = result['data']['choices'][0]['message']['content'] as String?;
        setState(() => _aiPlan = content ?? 'Error: Empty response.');
        if (!isPremium) {
          await nutritionProvider.incrementCycleCount(userId);
        }
      } else {
        setState(() => _aiError = 'Could not retrieve AI response. Please try again.');
      }
    } catch (e) {
      setState(() => _aiError = 'Connection error: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final nutritionProvider = context.watch<NutritionProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final phase = widget.phase;
    final isUnmarried = userProvider.user?.userRole == 'unmarried_girl';

    return Theme(
      data: isUnmarried ? MenstrualMedicalTheme.themeData : Theme.of(context),
      child: Scaffold(
        backgroundColor: isUnmarried ? MenstrualMedicalTheme.obsidianBlack : MaaColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '${phase.emoji} ${phase.name}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
  
              // ── Phase Hero Banner ────────────────────────────────────────
              _buildPhaseBanner(phase, isUnmarried).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
  
              // ── Seed Cycling Card ────────────────────────────────────────
              _buildSeedCyclingCard(phase, isUnmarried).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 24),
  
              // ── Time-Based Nutrition Timeline ────────────────────────────
              Text(
                '🕐 Daily Nutrition Timeline',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hormone-aligned meal timings with soundscape support',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 16),
  
              // ── Meal Cards with Audio ────────────────────────────────────
              ...List.generate(_mealSlots.length, (i) {
                final slot = _mealSlots[i];
                final mealContent = _mealContent[slot.label] ?? '';
                return _buildMealCard(
                  slot: slot,
                  content: mealContent,
                  phase: phase,
                  index: i,
                  isUnmarried: isUnmarried,
                );
              }),
  
              const SizedBox(height: 24),
  
              // ── Nutrient Focus Pills ─────────────────────────────────────
              _buildNutrientSection(phase, isUnmarried).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
  
              // ── AI Enhanced Plan CTA ─────────────────────────────────────
              _buildAICta(isPremium, 6 - nutritionProvider.freeCycleGenerationCount, isUnmarried),
              const SizedBox(height: 16),
  
              // ── AI Plan Result ───────────────────────────────────────────
              if (_aiError != null) _buildErrorCard(),
              if (_aiPlan != null) _buildAIPlanResult(isUnmarried),
  
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Phase Banner ─────────────────────────────────────────────────────────
  Widget _buildPhaseBanner(PhaseInfo phase, bool isUnmarried) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(phase.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    phase.subtitle,
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: phase.gradient[0].withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.track_changes_rounded, color: phase.gradient[0], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Focus: ${phase.focus}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isUnmarried) {
      return GlassmorphicCard(
        borderColor: Colors.white10,
        backgroundColor: phase.gradient[0].withValues(alpha: 0.12),
        child: cardContent,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            phase.gradient[0].withValues(alpha: 0.3),
            phase.gradient[1].withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phase.gradient[0].withValues(alpha: 0.35)),
      ),
      child: cardContent,
    );
  }

  // ── Seed Cycling Card ────────────────────────────────────────────────────
  Widget _buildSeedCyclingCard(PhaseInfo phase, bool isUnmarried) {
    final cardContent = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Text('🌱', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seed Cycling Protocol',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '1–2 tbsp daily: ${phase.seedCycle}',
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
              ),
              Text(
                'Add to smoothies, oatmeal, or yogurt',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );

    if (isUnmarried) {
      return GlassmorphicCard(
        borderColor: Colors.white10,
        backgroundColor: Colors.green.withValues(alpha: 0.05),
        child: cardContent,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: cardContent,
    );
  }

  // ── Meal Card with Audio ─────────────────────────────────────────────────
  Widget _buildMealCard({
    required _MealSlot slot,
    required String content,
    required PhaseInfo phase,
    required int index,
    required bool isUnmarried,
  }) {
    final isThisPlaying = _playingTrackUrl == slot.soundUrl && _isAudioPlaying;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Meal header ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                phase.gradient[0].withValues(alpha: 0.15),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Row(
            children: [
              Text(slot.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      slot.time,
                      style: GoogleFonts.poppins(
                        color: isUnmarried ? MenstrualMedicalTheme.electricOrchid : phase.gradient[0],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Meal content ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            content,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),

        // ── Soundscape button ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GestureDetector(
            onTap: () => _toggleAudio(slot.soundUrl),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isThisPlaying
                    ? slot.soundColor.withValues(alpha: 0.2)
                    : (isUnmarried ? Colors.black26 : MaaColors.background),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isThisPlaying
                      ? slot.soundColor.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isThisPlaying ? Icons.pause_circle_filled_rounded : slot.soundIcon,
                      key: ValueKey(isThisPlaying),
                      color: isThisPlaying ? slot.soundColor : Colors.white54,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isThisPlaying ? 'Pause' : slot.soundLabel,
                    style: GoogleFonts.poppins(
                      color: isThisPlaying ? slot.soundColor : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isThisPlaying) ...[
                    const SizedBox(width: 8),
                    _buildPulseIndicator(slot.soundColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (isUnmarried) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: GlassmorphicCard(
          padding: EdgeInsets.zero,
          borderRadius: 18.0,
          borderColor: Colors.white10,
          child: cardContent,
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 120 * index)).slideX(begin: 0.05, end: 0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: cardContent,
    ).animate().fadeIn(delay: Duration(milliseconds: 120 * index)).slideX(begin: 0.05, end: 0);
  }

  Widget _buildPulseIndicator(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: 8 + (i * 4.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleY(begin: 0.4, end: 1.0, delay: Duration(milliseconds: 100 * i)),
      ),
    );
  }

  // ── Nutrient Section ─────────────────────────────────────────────────────
  Widget _buildNutrientSection(PhaseInfo phase, bool isUnmarried) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💊 Priority Nutrients',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: phase.keyNutrients.map((n) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: phase.gradient[0].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: phase.gradient[0].withValues(alpha: 0.35)),
            ),
            child: Text(
              n,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 14),
        Text(
          '🚫 Limit / Avoid',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: phase.avoidFoods.map((f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              f,
              style: GoogleFonts.poppins(color: Colors.redAccent.shade100, fontSize: 12),
            ),
          )).toList(),
        ),
      ],
    );

    if (isUnmarried) {
      return GlassmorphicCard(
        borderColor: Colors.white10,
        backgroundColor: phase.gradient[0].withValues(alpha: 0.08),
        child: cardContent,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: phase.gradient[0].withValues(alpha: 0.2)),
      ),
      child: cardContent,
    );
  }

  // ── AI CTA ───────────────────────────────────────────────────────────────
  Widget _buildAICta(bool isPremium, int trialUsesLeft, bool isUnmarried) {
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : widget.phase.gradient[0];
    final secondaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.6) : widget.phase.gradient[1];
    final progressColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _isGenerating ? null : _generateAIPlan,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isGenerating
                    ? [Colors.grey.shade800, Colors.grey.shade700]
                    : [primaryColor, secondaryColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGenerating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                else
                  const Text('✨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  _isGenerating
                      ? 'Analyzing Your Hormonal Profile...'
                      : 'Generate AI Deep-Dive Plan ✨',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isPremium && trialUsesLeft > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '🎁 Free Trial: $trialUsesLeft uses left',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        _aiError!,
        style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }

  Widget _buildAIPlanResult(bool isUnmarried) {
    final headerColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : widget.phase.gradient[0];
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.phase.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'AI-Generated ${widget.phase.name} Plan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Markdown(
          data: _aiPlan!,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.6),
            h1: GoogleFonts.poppins(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            h2: GoogleFonts.poppins(
                color: headerColor,
                fontSize: 14,
                fontWeight: FontWeight.bold),
            h3: GoogleFonts.poppins(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            listBullet: TextStyle(color: headerColor),
            blockquoteDecoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: headerColor, width: 4),
              ),
            ),
            code: GoogleFonts.sourceCodePro(
                color: Colors.greenAccent, fontSize: 12),
          ),
        ),
      ],
    );

    if (isUnmarried) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        child: GlassmorphicCard(
          borderColor: Colors.white10,
          child: cardContent,
        ),
      ).animate().fadeIn().moveY(begin: 15, end: 0);
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.phase.gradient[0].withValues(alpha: 0.2)),
      ),
      child: cardContent,
    ).animate().fadeIn().moveY(begin: 15, end: 0);
  }
}

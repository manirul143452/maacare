// ============================================================
//  PeriodSymptomsGrid – Menstrual Symptoms & Severity Triage
//  Premium, dark-themed, glassmorphic UI adapted for Unmarried Girls
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app_theme.dart';
import '../../../theme/menstrual_medical_theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/menstrual_provider.dart';
import '../../../services/maacare_backend_service.dart';

class PeriodSymptomData {
  final String id;
  final String title;
  final String emoji;
  final String description;

  const PeriodSymptomData({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
  });
}

class PeriodSymptomsGrid extends StatefulWidget {
  final UserModel? user;
  final MenstrualProvider provider;
  final VoidCallback? onEmergencyTriggered;

  const PeriodSymptomsGrid({
    super.key,
    required this.user,
    required this.provider,
    this.onEmergencyTriggered,
  });

  @override
  State<PeriodSymptomsGrid> createState() => _PeriodSymptomsGridState();
}

class _PeriodSymptomsGridState extends State<PeriodSymptomsGrid> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final List<PeriodSymptomData> _symptoms = const [
    PeriodSymptomData(
      id: 'heavy_flow_spotting',
      title: 'Heavy Flow / Spotting',
      emoji: '🩸',
      description: 'Heavy flow or unexpected bleeding/spotting',
    ),
    PeriodSymptomData(
      id: 'dysmenorrhea_severe_cramps',
      title: 'Dysmenorrhea / Severe Cramps',
      emoji: '⚡',
      description: 'Painful lower abdominal cramps or pelvic pain',
    ),
    PeriodSymptomData(
      id: 'hormonal_acne_breakouts',
      title: 'Hormonal Acne Breakouts',
      emoji: '🌸',
      description: 'Skin breakouts on jawline, chin, and cheeks',
    ),
    PeriodSymptomData(
      id: 'fatigue_bloating',
      title: 'Fatigue & Bloating',
      emoji: '🥱',
      description: 'Extreme tiredness, lack of energy, or swelling',
    ),
    PeriodSymptomData(
      id: 'brain_fog_headaches',
      title: 'Brain Fog / Headaches',
      emoji: '🧠',
      description: 'Difficulty concentrating, headaches, or migraines',
    ),
    PeriodSymptomData(
      id: 'mood_swings_pms_anxiety',
      title: 'Mood Swings / PMS Anxiety',
      emoji: '🎭',
      description: 'Emotional shifts, anxiety, or mood changes',
    ),
  ];

  Map<String, dynamic>? _getSymptomDetail(String title) {
    try {
      return widget.provider.loggedSymptomDetails.firstWhere(
        (element) => element['symptom_name'] == title,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleSymptom(PeriodSymptomData symptom) async {
    if (widget.user == null) return;
    final userId = widget.user!.id;

    final updated = List<Map<String, dynamic>>.from(widget.provider.loggedSymptomDetails);
    final index = updated.indexWhere((element) => element['symptom_name'] == symptom.title);

    if (index == -1) {
      // Toggle ON: Add with default 'mild' severity
      updated.add({
        'symptom_name': symptom.title,
        'severity_level': 'mild',
        'logged_at': DateTime.now().toIso8601String(),
        'cycle_phase': widget.provider.cyclePhase,
      });
      await widget.provider.saveDetailedSymptoms(userId, updated);
      
      // Auto-trigger severity triage modal on selection to let them refine if needed
      _showSeverityTriageModal(symptom);
    } else {
      // Toggle OFF: Remove
      updated.removeAt(index);
      await widget.provider.saveDetailedSymptoms(userId, updated);
    }
  }

  void _showSeverityTriageModal(PeriodSymptomData symptom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _buildSeverityTriageSheet(symptom);
      },
    );
  }

  Widget _buildSeverityTriageSheet(PeriodSymptomData symptom) {
    final currentDetail = _getSymptomDetail(symptom.title);
    final currentSeverity = currentDetail?['severity_level'] ?? 'mild';
    final isUnmarried = widget.user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return Container(
      decoration: BoxDecoration(
        color: isUnmarried ? MenstrualMedicalTheme.darkSlate : MaaColors.cardDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                symptom.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symptom.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      symptom.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: MaaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Select Severity Level:',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: 16),
          _buildSeverityOption(
            level: 'mild',
            title: 'Mild (🟢 Halka)',
            description: 'Barely noticeable, does not interfere with daily routine.',
            color: Colors.greenAccent,
            isSelected: currentSeverity == 'mild',
            symptom: symptom,
          ),
          const SizedBox(height: 12),
          _buildSeverityOption(
            level: 'moderate',
            title: 'Moderate (🟡 Madhyam)',
            description: 'Noticeable discomfort, manageable with minor adjustments.',
            color: Colors.amberAccent,
            isSelected: currentSeverity == 'moderate',
            symptom: symptom,
          ),
          const SizedBox(height: 12),
          _buildSeverityOption(
            level: 'severe',
            title: 'Severe (🔴 Gambhir)',
            description: 'Intense pain or distress, requires clinical monitoring or intervention.',
            color: Colors.redAccent,
            isSelected: currentSeverity == 'severe',
            symptom: symptom,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () async {
                  if (widget.user == null) return;
                  final navigator = Navigator.of(context);
                  final updated = List<Map<String, dynamic>>.from(widget.provider.loggedSymptomDetails);
                  updated.removeWhere((element) => element['symptom_name'] == symptom.title);
                  await widget.provider.saveDetailedSymptoms(widget.user!.id, updated);
                  navigator.pop();
                },
                child: Text(
                  'Remove Symptom',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityOption({
    required String level,
    required String title,
    required String description,
    required Color color,
    required bool isSelected,
    required PeriodSymptomData symptom,
  }) {
    return GestureDetector(
      onTap: () => _updateSeverity(symptom, level),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withAlpha(15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.white54,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.black,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isSelected ? Colors.white.withAlpha(204) : MaaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSeverity(PeriodSymptomData symptom, String level) async {
    if (widget.user == null) return;
    final userId = widget.user!.id;

    final updated = List<Map<String, dynamic>>.from(widget.provider.loggedSymptomDetails);
    final index = updated.indexWhere((element) => element['symptom_name'] == symptom.title);

    if (index != -1) {
      updated[index]['severity_level'] = level;
      updated[index]['logged_at'] = DateTime.now().toIso8601String();
      updated[index]['cycle_phase'] = widget.provider.cyclePhase;
      await widget.provider.saveDetailedSymptoms(userId, updated);
    }

    if (level == 'severe') {
      final titleLower = symptom.title.toLowerCase();
      if (titleLower.contains('cramps') || titleLower.contains('flow')) {
        // 1. SharedPreferences Counter setup for Sakhi AI
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('severe_symptom_chat_count', 5);
        await prefs.setBool('show_emergency_support_banner', true);

        // 2. Invoke Webhook
        await MaaCareBackendService.instance.invokeSymptomWebhook(
          userId: userId,
          symptom: symptom.title,
          severity: 'severe',
        );

        // 3. Callback to trigger Emergency Support context layout immediately
        if (widget.onEmergencyTriggered != null) {
          widget.onEmergencyTriggered!();
        }

        // Show direct dialog alert
        if (mounted) {
          _showTriageWarningDialog(symptom);
        }
      }
    }

    setState(() {});
  }

  void _showTriageWarningDialog(PeriodSymptomData symptom) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaaColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'Urgent Health Notice',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Severe symptoms logged: ${symptom.title}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Log kiya gaya severe symptom extreme levels ka pain ya distress darshata hai. Gynaecologist se checkup karana ya emergency medical care lena highly recommended hai.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gynecare_consultation');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Consult Expert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnmarried = widget.user?.userRole == 'unmarried_girl';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemCount: _symptoms.length,
          itemBuilder: (context, index) {
            final symptom = _symptoms[index];
            final detail = _getSymptomDetail(symptom.title);
            final isActive = detail != null;
            final severity = detail?['severity_level'] ?? 'mild';

            Color severityColor = isUnmarried ? MenstrualMedicalTheme.greenZoneMint : Colors.greenAccent;
            if (severity == 'moderate') {
              severityColor = isUnmarried ? MenstrualMedicalTheme.yellowZoneAmber : Colors.amberAccent;
            }
            if (severity == 'severe') {
              severityColor = isUnmarried ? MenstrualMedicalTheme.redZoneCrimson : Colors.redAccent;
            }

            final cardContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      symptom.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    if (isActive)
                      GestureDetector(
                        onTap: () => _showSeverityTriageModal(symptom),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: severityColor.withAlpha(120)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: severityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                severity[0].toUpperCase() + severity.substring(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: severityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symptom.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      symptom.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: isUnmarried ? Colors.white70 : MaaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            );

            if (isUnmarried) {
              final borderGlow = isActive ? MenstrualMedicalTheme.electricOrchid : Colors.white10;
              final borderThickness = isActive ? 1.5 : 1.0;

              Widget animatedCard = AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderGlow,
                    width: borderThickness,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: cardContent,
              );

              Widget glassCard = GestureDetector(
                onTap: () => _toggleSymptom(symptom),
                onLongPress: () {
                  if (isActive) {
                    _showSeverityTriageModal(symptom);
                  } else {
                    _toggleSymptom(symptom);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: animatedCard,
                  ),
                ),
              );

              if (isActive && severity == 'severe') {
                return ScaleTransition(
                  scale: _pulseAnimation,
                  child: glassCard,
                );
              }
              return glassCard;
            }

            return GestureDetector(
              onTap: () => _toggleSymptom(symptom),
              onLongPress: () {
                if (isActive) {
                  _showSeverityTriageModal(symptom);
                } else {
                  _toggleSymptom(symptom);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? MaaColors.pink.withAlpha(20) : MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? MaaColors.pink.withAlpha(180) : Colors.white.withAlpha(13),
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: MaaColors.pink.withAlpha(30),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: cardContent,
              ),
            ).animate(target: isActive ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                  duration: 200.ms,
                );
          },
        ),
      ],
    );
  }
}

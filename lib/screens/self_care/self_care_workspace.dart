// ============================================================
//  self_care_workspace.dart – 5-Min Period Yoga Stretch
//  Premium clinical UI for Unmarried Girls with visual viewports
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../theme/menstrual_medical_theme.dart';

class PeriodYogaPose {
  final String name;
  final String time;
  final String desc;
  final String emoji;
  final String imageUrl;
  final List<String> breathingGuide;

  const PeriodYogaPose({
    required this.name,
    required this.time,
    required this.desc,
    required this.emoji,
    required this.imageUrl,
    required this.breathingGuide,
  });
}

class PeriodYogaWorkspace extends StatefulWidget {
  final bool isUnmarried;

  const PeriodYogaWorkspace({
    super.key,
    required this.isUnmarried,
  });

  @override
  State<PeriodYogaWorkspace> createState() => _PeriodYogaWorkspaceState();
}

class _PeriodYogaWorkspaceState extends State<PeriodYogaWorkspace> {
  final List<PeriodYogaPose> _poses = const [
    PeriodYogaPose(
      name: "Child's Pose",
      time: '2 min',
      desc: 'Balasana: Gently stretches hips, thighs, and ankles. Calms the mind and relieves pelvic tension.',
      emoji: '🧘‍♀️',
      imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&auto=format&fit=crop&q=60',
      breathingGuide: [
        'Inhale deeply through your nose, expanding your ribcage and lower back.',
        'Exhale slowly through your mouth, letting your chest and hips melt towards the floor.',
        'Focus on sending warm breath to any areas of abdominal tightness.'
      ],
    ),
    PeriodYogaPose(
      name: 'Cat-Cow Stretch',
      time: '2 min',
      desc: 'Marjaryasana: Warms the body and brings flexibility to the entire spine, relieving back pain.',
      emoji: '🐈',
      imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&auto=format&fit=crop&q=60',
      breathingGuide: [
        'Inhale as you arch your back into Cow Pose, lifting your heart and head gently.',
        'Exhale completely as you round your spine into Cat Pose, drawing your navel up.',
        'Synchronize each movement with the natural rise and fall of your breath.'
      ],
    ),
    PeriodYogaPose(
      name: 'Bound Angle Pose',
      time: '1 min',
      desc: 'Supta Baddha Konasana: Opens groin and hips, stimulates abdominal organs and pelvic blood flow.',
      emoji: '🦋',
      imageUrl: 'https://images.unsplash.com/photo-1599447421416-3414500d18a5?w=400&auto=format&fit=crop&q=60',
      breathingGuide: [
        'Inhale to find length in your spine, sitting tall and relaxing your shoulders.',
        'Exhale as you allow your knees to sink outwards toward the sides under gravity\'s weight.',
        'Keep your breathing slow, steady, and focused on pelvic relaxation.'
      ],
    ),
  ];

  int? _expandedIndex;

  void _toggleExpand(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fitness_center_rounded, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              '5-Min Period Yoga Stretch',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_poses.length, (index) {
          final pose = _poses[index];
          final isExpanded = _expandedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _toggleExpand(index),
              child: GlassmorphicCard(
                borderRadius: 16.0,
                padding: const EdgeInsets.all(12),
                borderColor: isExpanded ? primaryColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
                backgroundColor: MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Pose Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Visual Posture Viewport
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 85,
                            height: 85,
                            color: Colors.white.withValues(alpha: 0.04),
                            child: Image.network(
                              pose.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: Text(
                                    pose.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    pose.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Text Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pose.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Time Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pose.time,
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pose.desc,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Expanded Breathing Guide (Smooth Expand Transition)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: isExpanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Divider(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  height: 1,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.air_rounded,
                                      size: 14,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'BREATHING GUIDELINE',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...pose.breathingGuide.map((stepText) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            stepText,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: Colors.white60,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            )
                          : const SizedBox.shrink(),
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
}

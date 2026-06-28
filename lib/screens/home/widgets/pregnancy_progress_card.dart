// ============================================================
//  PregnancyProgressCard – Dynamic Gestational Progress Card
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../app_theme.dart';
import '../../../data/pregnancy_data.dart';
import '../../../models/user_model.dart';
import '../../../constants.dart';

class PregnancyProgressCard extends StatelessWidget {
  final int week;
  final String timeRemainingStr;

  const PregnancyProgressCard({
    super.key,
    required this.week,
    required this.timeRemainingStr,
  });

  String _getBabyImageUrl(int week) {
    // Map weeks to dynamic baby growth images hosted in InsForge Storage weeks bucket
    int displayWeek = week.clamp(4, 41);
    return '${AppConstants.backendUrl}/api/storage/buckets/weeks/objects/week_$displayWeek.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final fruitData = getBabyFruitForWeek(week);
    final pregnancyInfo = getPregnancyInfoForWeek(week);
    final title = pregnancyInfo?['title'] ?? 'Growing Miracle';

    int displayWeek = week;
    if (displayWeek < 4) displayWeek = 4;
    if (displayWeek > 41) displayWeek = 41;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: MaaColors.pink.withAlpha(40),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Weekly Background Image
            Image.asset(
              'assets/images/weeks/week_$displayWeek.jpg',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, error, ___) {
                debugPrint('Background image load error: $error');
                return Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: MaaColors.primaryGradient,
                  ),
                );
              },
            ),

            // Glassmorphism Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(40),
                      MaaColors.background.withAlpha(140),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: MaaColors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: MaaColors.white.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          '${AppLocalizations.of(context).week} $week',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      // Real-time Countdown Badge
                      if (timeRemainingStr.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: MaaColors.pink.withAlpha(200),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: MaaColors.pinkGlow,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            timeRemainingStr,
                            style: GoogleFonts.poppins(
                              color: MaaColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 3000.ms),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Text cluster & dynamic baby development image aligned in a row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                color: MaaColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  const Shadow(
                                    color: Colors.black,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${AppLocalizations.of(context).sizeOfA} ${fruitData['fruit']} ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withAlpha(220),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  fruitData['emoji'] ?? '👶',
                                  style: const TextStyle(fontSize: 18),
                                ).animate(onPlay: (c) => c.repeat()).scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.3, 1.3),
                                      duration: 1000.ms,
                                      curve: Curves.easeInOut,
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Gestational Baby Growth Image Asset Component
                      _buildBabyGrowthImage(week),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Shimmering Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: MaaColors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: (week / 40).clamp(0.0, 1.0),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                MaaColors.gold,
                                MaaColors.pink,
                                MaaColors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: MaaColors.gold.withAlpha(150),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(
                              duration: 5000.ms,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${40 - week} ${AppLocalizations.of(context).weeksToMeet}',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/tracker'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${AppLocalizations.of(context).guide} ',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: MaaColors.white,
                                size: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildBabyGrowthImage(int week) {
    final imageUrl = _getBabyImageUrl(week);

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withAlpha(64),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.white.withAlpha(13),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            debugPrint('Baby growth image load error: $error');
            return Container(
              color: Colors.white.withAlpha(13),
              child: const Center(
                child: Text(
                  '👶',
                  style: TextStyle(fontSize: 32),
                ),
              ),
            );
          },
        ),
      ),
    )
        .animate(key: ValueKey(week)) // Trigger 300ms fade-in transition when week changes
        .fadeIn(duration: 300.ms, curve: Curves.easeIn);
  }
}

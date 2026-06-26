import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/pregnancy_data.dart';

class WeeklyDetailScreen extends StatelessWidget {
  final int week;

  const WeeklyDetailScreen({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final info = getPregnancyInfoForWeek(week);
    if (info == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Week Detail')),
        body: const Center(child: Text('Information not available.')),
      );
    }

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: Text('Week $week',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: MaaColors.cardDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Placeholder Header
            _buildImageHeader(context, info),

            // Detailed Info Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${info['title']}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: MaaColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: MaaColors.pink.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Size: ${info['size'] ?? 'Growing'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: MaaColors.deepPink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Baby's Development
                  _buildSectionHeader('👶', "Baby's Development"),
                  const SizedBox(height: 16),
                  Text(
                    info['development'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: MaaColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Advice for You
                  _buildSectionHeader('💡', "Advice for You"),
                  const SizedBox(height: 16),
                  Text(
                    info['advice'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  
                  // WHO Clinical Guideline Card
                  if (info['who_guideline'] != null) ...[
                    const SizedBox(height: 40),
                    _buildSectionHeader('🩺', "WHO Clinical Guideline"),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MaaColors.success.withAlpha(20),
                            MaaColors.softPurple.withAlpha(10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: MaaColors.success.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: MaaColors.success,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'WHO Recommendation',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.verified_user_rounded,
                                color: MaaColors.success,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            info['who_guideline']!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: MaaColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String emoji, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MaaColors.softPurple.withAlpha(50),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MaaColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildImageHeader(BuildContext context, Map<String, String> info) {
    return Stack(
      children: [
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: MaaColors.cardDark,
            boxShadow: [
              BoxShadow(
                  color: MaaColors.cardShadow,
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          // We load the realistic image dynamically.
          // Since it might not exist yet, we add an error builder placeholder.
          child: Image.asset(
            'assets/images/weeks/week_$week.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        ),
        // Gradient overlay for seamless transition into the dark background
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  MaaColors.background,
                  MaaColors.background.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MaaColors.cardDark,
            MaaColors.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_rounded,
                size: 80, color: MaaColors.pink.withAlpha(100)),
            const SizedBox(height: 24),
            Text(
              week == 1 ? 'Pre-conception' : 'Getting Ready',
              style: TextStyle(
                color: MaaColors.white.withAlpha(200),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              week == 1
                  ? 'Your body is preparing for the miracle.'
                  : 'Growing little by little...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaaColors.pink.withAlpha(150),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

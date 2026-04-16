// ============================================================
//  Child Care Guide – MaaCare Premium
//  Comprehensive parenting guide from breastfeeding to milestones
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';

class ChildCareGuideScreen extends StatefulWidget {
  const ChildCareGuideScreen({super.key});

  @override
  State<ChildCareGuideScreen> createState() => _ChildCareGuideScreenState();
}

class _ChildCareGuideScreenState extends State<ChildCareGuideScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<GuideSection> _sections = [
    GuideSection(
      title: 'Exclusive Breastfeeding',
      icon: Icons.child_care_rounded,
      color: MaaColors.pink,
      imageEmoji: '🤱',
      content: _BreastfeedingContent(),
    ),
    GuideSection(
      title: 'Latching & Positions',
      icon: Icons.pregnant_woman_rounded,
      color: MaaColors.softPurple,
      imageEmoji: '💜',
      content: _LatchingContent(),
    ),
    GuideSection(
      title: 'Kangaroo Care',
      icon: Icons.favorite_rounded,
      color: MaaColors.warning,
      imageEmoji: '🦘',
      content: _KMCContent(),
    ),
    GuideSection(
      title: 'Complementary Feeding',
      icon: Icons.restaurant_rounded,
      color: MaaColors.success,
      imageEmoji: '🥄',
      content: _FeedingContent(),
    ),
    GuideSection(
      title: 'Toilet Training',
      icon: Icons.baby_changing_station_rounded,
      color: MaaColors.lightBlue,
      imageEmoji: '🚽',
      content: _ToiletTrainingContent(),
    ),
    GuideSection(
      title: 'Play & Development',
      icon: Icons.toys_rounded,
      color: MaaColors.softGreen,
      imageEmoji: '🧸',
      content: _PlayDevelopmentContent(),
    ),
    GuideSection(
      title: 'Milestones',
      icon: Icons.trending_up_rounded,
      color: MaaColors.peach,
      imageEmoji: '📈',
      content: _MilestonesContent(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: MaaColors.cardDark,
              title: Text(
                'Child Care Guide',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: MaaColors.textPrimary,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MaaColors.pink.withAlpha(80),
                        MaaColors.softPurple.withAlpha(60),
                        MaaColors.cardDark,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MaaColors.pink.withAlpha(30),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: -40,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MaaColors.softPurple.withAlpha(25),
                          ),
                        ),
                      ),
                      // Center content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: MaaColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: MaaColors.pink.withAlpha(60),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MaaColors.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: MaaColors.textPrimary, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: MaaColors.pink,
                indicatorWeight: 3,
                labelColor: MaaColors.pink,
                unselectedLabelColor: MaaColors.textSecondary,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                tabs: _sections
                    .map((s) => Tab(
                          icon: Icon(s.icon, size: 20),
                          text: s.title,
                        ))
                    .toList(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _sections.map((s) => s.content).toList(),
        ),
      ),
    );
  }
}

// ============================================================
//  Guide Section Model
// ============================================================

class GuideSection {
  final String title;
  final IconData icon;
  final Color color;
  final String imageEmoji;
  final Widget content;

  GuideSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.imageEmoji,
    required this.content,
  });
}

// ============================================================
//  Content Widgets
// ============================================================

class _BreastfeedingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Exclusive Breastfeeding (First 6 Months)',
            Icons.child_care_rounded,
            MaaColors.pink,
            imageEmoji: '🤱',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            'WHO Recommendation',
            'The WHO recommends exclusive breastfeeding for the first 6 months of life for optimal growth, development and health.',
            MaaColors.softPurple,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            'Breast milk provides all the nutrients and hydration your baby needs.',
          ),
          _buildBulletPoint(
            'Feed on demand, which may be 8-12 times in 24 hours.',
          ),
          _buildBulletPoint(
            'Look for hunger cues: rooting, hand-to-mouth movements, and fussing.',
          ),
          _buildBulletPoint(
            'Strengthens the baby\'s immune system, providing protection against many illnesses.',
          ),
          _buildBulletPoint(
            'Creates a strong emotional bond between mother and child.',
          ),
          const SizedBox(height: 20),
          _buildHighlightCard(
            '💡 Tip',
            'Breast milk composition changes throughout the day to match your baby\'s needs!',
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _LatchingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Proper Latching Technique',
            Icons.pregnant_woman_rounded,
            MaaColors.softPurple,
            imageEmoji: '💜',
          ),
          const SizedBox(height: 20),
          _buildStepCard(
            '1',
            'Position',
            'Hold your baby close to you, skin-to-skin if possible.',
            MaaColors.pink,
          ),
          _buildStepCard(
            '2',
            'Encourage Opening',
            'Tickle your baby\'s lips with your nipple to encourage them to open their mouth wide, like a yawn.',
            MaaColors.softPurple,
          ),
          _buildStepCard(
            '3',
            'Latch On',
            'When their mouth is wide open, bring the baby to your breast, aiming the nipple toward the roof of their mouth.',
            MaaColors.warning,
          ),
          _buildStepCard(
            '4',
            'Check Position',
            'Your baby should have a large part of the areola in their mouth. Their lips should be flanged outward (like a fish).',
            MaaColors.success,
          ),
          _buildStepCard(
            '5',
            'Comfort Check',
            'A good latch should not be painful. If it hurts, gently break the suction with your finger and try again.',
            MaaColors.lightBlue,
          ),
          const SizedBox(height: 24),
          _buildSubHeader('Comfortable Positions'),
          const SizedBox(height: 16),
          _buildPositionCard(
            'Cradle Hold',
            'The most common position. Hold your baby across your lap, with their head resting in the crook of your elbow.',
            Icons.chair_rounded,
          ),
          _buildPositionCard(
            'Cross-Cradle Hold',
            'Great for newborns. Hold your baby with the arm opposite the nursing breast, supporting their head and neck.',
            Icons.swap_horiz_rounded,
          ),
          _buildPositionCard(
            'Football Hold',
            'Useful after a C-section. Tuck your baby under your arm on the same side as the nursing breast.',
            Icons.sports_rounded,
          ),
          _buildPositionCard(
            'Side-Lying',
            'Perfect for nighttime feedings. Lie on your side with your baby facing you, and draw them close to latch on.',
            Icons.bed_rounded,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _KMCContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Kangaroo Mother Care (KMC)',
            Icons.favorite_rounded,
            MaaColors.warning,
            imageEmoji: '🦘',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            'What is KMC?',
            'KMC involves continuous skin-to-skin contact between a mother (or father) and their newborn, particularly for preterm or low-birth-weight infants.',
            MaaColors.warning,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.pink.withAlpha(30),
                  MaaColors.softPurple.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.pink.withAlpha(40)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.wc_rounded,
                  size: 48,
                  color: MaaColors.pink,
                ),
                const SizedBox(height: 12),
                Text(
                  'How to Practice KMC',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MaaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The baby, wearing only a diaper and a cap, is placed in an upright position against the parent\'s bare chest.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSubHeader('Benefits of KMC'),
          const SizedBox(height: 16),
          _buildBenefitCard('Improved temperature regulation', Icons.thermostat_rounded),
          _buildBenefitCard('Stabilized heart and breathing rates', Icons.favorite_rounded),
          _buildBenefitCard('Increased weight gain', Icons.trending_up_rounded),
          _buildBenefitCard('Enhanced bonding', Icons.favorite_border_rounded),
          _buildBenefitCard('Promotes breastfeeding', Icons.child_care_rounded),
          _buildBenefitCard('Reduces risk of infection', Icons.shield_rounded),
          const SizedBox(height: 20),
          _buildHighlightCard(
            '🌟 Remember',
            'KMC is a powerful, easy-to-do method to help your baby thrive!',
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FeedingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Complementary Feeding (After 6 Months)',
            Icons.restaurant_rounded,
            MaaColors.success,
            imageEmoji: '🥄',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            'When to Start',
            'Introduce solid foods around 6 months, alongside continued breastfeeding.',
            MaaColors.success,
          ),
          const SizedBox(height: 20),
          _buildSubHeader('First Foods to Try'),
          const SizedBox(height: 16),
          _buildFoodCard('Iron-fortified cereals', Icons.grain_rounded, Colors.brown),
          _buildFoodCard('Mashed bananas', Icons.emoji_food_beverage_rounded, Colors.yellow.shade700),
          _buildFoodCard('Avocados', Icons.spa_rounded, Colors.green),
          _buildFoodCard('Sweet potatoes', Icons.local_dining_rounded, Colors.orange),
          const SizedBox(height: 20),
          _buildBulletPoint(
            'Start with single-ingredient purees.',
          ),
          _buildBulletPoint(
            'Introduce one new food every 3-5 days to watch for any allergic reactions.',
          ),
          _buildBulletPoint(
            'As the baby gets older, introduce thicker purees, mashed foods, and soft finger foods.',
          ),
          _buildBulletPoint(
            'Continue breastfeeding on demand - it remains a primary source of nutrition through the first year.',
          ),
          const SizedBox(height: 20),
          _buildHighlightCard(
            '⚠️ Allergy Watch',
            'Watch for signs of allergies: rash, vomiting, diarrhea, or breathing difficulties when introducing new foods.',
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ToiletTrainingContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Toilet Training',
            Icons.baby_changing_station_rounded,
            MaaColors.lightBlue,
            imageEmoji: '🚽',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            'Best Age to Start',
            'Most children are ready for toilet training between 18 months and 3 years.',
            MaaColors.lightBlue,
          ),
          const SizedBox(height: 20),
          _buildSubHeader('Signs of Readiness'),
          const SizedBox(height: 16),
          _buildCheckItem('Staying dry for longer periods'),
          _buildCheckItem('Showing interest in the toilet'),
          _buildCheckItem('Being able to pull pants up and down'),
          _buildCheckItem('Recognizing the urge to go'),
          _buildCheckItem('Disliking dirty diapers'),
          const SizedBox(height: 20),
          _buildSubHeader('Getting Started'),
          const SizedBox(height: 16),
          _buildStepCard(
            '1',
            'Get Equipment',
            'Get a child-friendly potty chair and place it in a convenient location.',
            MaaColors.pink,
          ),
          _buildStepCard(
            '2',
            'Establish Routine',
            'Sit on the potty after waking up, after meals, and before bedtime.',
            MaaColors.softPurple,
          ),
          _buildStepCard(
            '3',
            'Use Praise',
            'Use praise and encouragement. Never punish a child for accidents.',
            MaaColors.success,
          ),
          _buildStepCard(
            '4',
            'Be Patient',
            'Accidents are normal. Stay positive and consistent.',
            MaaColors.warning,
          ),
          const SizedBox(height: 20),
          _buildHighlightCard(
            '💡 Tip',
            'Let your child pick their own potty chair or seat - it builds excitement!',
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _PlayDevelopmentContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Age-Appropriate Playing Materials',
            Icons.toys_rounded,
            MaaColors.softGreen,
            imageEmoji: '🧸',
          ),
          const SizedBox(height: 20),
          _buildAgeCard(
            '0-6 Months',
            [
              'High-contrast cards',
              'Soft rattles',
              'Unbreakable mirrors',
              'Activity mats',
            ],
            Icons.crib_rounded,
            MaaColors.pink,
          ),
          _buildAgeCard(
            '6-12 Months',
            [
              'Stacking rings',
              'Soft blocks',
              'Board books',
              'Cause-and-effect toys',
            ],
            Icons.eco_rounded,
    MaaColors.softPurple,
          ),
          _buildAgeCard(
            '1-2 Years',
    [
              'Shape sorters',
              'Large puzzles',
              'Balls',
   'Push-pull toys',
     ],
            Icons.child_care_rounded,
            MaaColors.warning,
          ),
          _buildAgeCard(
            '2-3 Years',
            [
    'Crayons & paper',
        'Simple building blocks',
  'Dress-up clothes',
    'Toy kitchens',
  ],
            Icons.face_rounded,
            MaaColors.success,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
   'Why Play Matters',
 'Play is crucial for cognitive, motor, and social-emotional development. Through play, children learn about the world around them.',
       MaaColors.softGreen,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _MilestonesContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Growth & Development Milestones',
            Icons.trending_up_rounded,
            MaaColors.peach,
            imageEmoji: '📈',
          ),
          const SizedBox(height: 20),
          _buildMilestoneCard(
            'By 3 Months',
            [
              'Can raise head and chest when lying on stomach',
              'Smiles at the sound of your voice',
              'Tracks moving objects with eyes',
              'Makes cooing sounds',
            ],
            MaaColors.pink,
          ),
          _buildMilestoneCard(
            'By 6 Months',
            [
              'Rolls over in both directions',
              'Begins to sit without support',
              'Babbles with expression',
              'Recognizes familiar faces',
            ],
            MaaColors.softPurple,
          ),
          _buildMilestoneCard(
            'By 9 Months',
            [
              'May start to crawl',
              'Pulls to stand',
              'Understands "no"',
              'Plays peek-a-boo',
            ],
            MaaColors.warning,
          ),
          _buildMilestoneCard(
            'By 1 Year',
            [
              'May take a few steps',
              'Uses simple gestures like waving',
              'Says "mama" and "dada"',
              'Explores objects in different ways',
            ],
            MaaColors.success,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.peach.withAlpha(30),
                  MaaColors.pink.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.peach.withAlpha(40)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_rounded, color: MaaColors.peach, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Remember: Every child develops at their own pace. Consult a pediatrician if you have concerns.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: MaaColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ============================================================
//  Helper Widgets
// ============================================================

Widget _buildHeader(String title, IconData icon, Color color, {String? imageEmoji}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Main Image Emoji Display
      if (imageEmoji != null)
        Container(
          width: 120,
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha(60),
                color.withAlpha(30),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(40),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              imageEmoji,
              style: const TextStyle(fontSize: 64),
            ),
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
      // Title Row
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(150), color.withAlpha(80)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MaaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildSubHeader(String text) {
  return Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: MaaColors.textPrimary,
    ),
  );
}

Widget _buildInfoCard(String title, String content, Color color) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withAlpha(30), color.withAlpha(15)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: MaaColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    ),
  ).animate().fadeIn().slideY(begin: 0.1, end: 0);
}

Widget _buildBulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: MaaColors.pink,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStepCard(String number, String title, String content, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: MaaColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(150), color.withAlpha(80)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: MaaColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ).animate().fadeIn().slideX(begin: 0.1, end: 0);
}

Widget _buildPositionCard(String title, String content, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: MaaColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MaaColors.softPurple.withAlpha(40)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MaaColors.softPurple.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: MaaColors.softPurple, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: MaaColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ).animate().fadeIn();
}

Widget _buildBenefitCard(String text, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: MaaColors.glassBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: MaaColors.warning.withAlpha(30)),
    ),
    child: Row(
      children: [
        Icon(icon, color: MaaColors.warning, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: MaaColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFoodCard(String food, IconData icon, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: MaaColors.cardDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withAlpha(50)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          food,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: MaaColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget _buildCheckItem(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: MaaColors.success, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAgeCard(String age, List<String> items, IconData icon, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withAlpha(25), color.withAlpha(10)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withAlpha(150), color.withAlpha(80)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              age,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: color, fontSize: 16)),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  ).animate().fadeIn();
}

Widget _buildMilestoneCard(String age, List<String> milestones, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: MaaColors.cardDark,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(40)),
      boxShadow: [
        BoxShadow(
          color: color.withAlpha(20),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(150), color.withAlpha(80)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            age,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...milestones.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_rounded, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  m,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  ).animate().fadeIn();
}

Widget _buildHighlightCard(String emoji, String text) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          MaaColors.gold.withAlpha(30),
          MaaColors.pink.withAlpha(20),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MaaColors.gold.withAlpha(50)),
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: MaaColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

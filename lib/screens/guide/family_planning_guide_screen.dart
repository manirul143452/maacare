// ============================================================
//  Family Planning Guide – MaaCare Premium
//  WHO-guided tools and resources for reproductive health
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';

class FamilyPlanningGuideScreen extends StatefulWidget {
  const FamilyPlanningGuideScreen({super.key});

  @override
  State<FamilyPlanningGuideScreen> createState() => _FamilyPlanningGuideScreenState();
}

class _FamilyPlanningGuideScreenState extends State<FamilyPlanningGuideScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<PlanningSection> _sections = [
    PlanningSection(
      title: 'Overview',
      icon: Icons.family_restroom_rounded,
      color: MaaColors.pink,
      imageEmoji: '👨‍👩‍👧‍👦',
      content: _OverviewContent(),
    ),
    PlanningSection(
      title: 'Why Important',
      icon: Icons.favorite_rounded,
      color: MaaColors.softPurple,
      imageEmoji: '❤️',
      content: _WhyImportantContent(),
    ),
    PlanningSection(
      title: 'Fertility Awareness',
      icon: Icons.calendar_today_rounded,
      color: MaaColors.success,
      imageEmoji: '📊',
      content: _FertilityAwarenessContent(),
    ),
    PlanningSection(
      title: 'Modern Methods',
      icon: Icons.medical_services_rounded,
      color: MaaColors.lightBlue,
      imageEmoji: '💊',
      content: _ModernMethodsContent(),
    ),
    PlanningSection(
      title: 'Infertility Support',
      icon: Icons.support_rounded,
      color: MaaColors.peach,
      imageEmoji: '🤝',
      content: _InfertilitySupportContent(),
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
              expandedHeight: 220,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: MaaColors.cardDark,
              title: Text(
                'Family Planning',
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
                      // Decorative elements
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
                        bottom: 30,
                        left: -30,
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
                            const SizedBox(height: 50),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    MaaColors.pink.withAlpha(150),
                                    MaaColors.softPurple.withAlpha(100),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: MaaColors.pink.withAlpha(50),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '🌍',
                                  style: TextStyle(fontSize: 50),
                                ),
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
//  Data Model
// ============================================================

class PlanningSection {
  final String title;
  final IconData icon;
  final Color color;
  final String imageEmoji;
  final Widget content;

  PlanningSection({
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

class _OverviewContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'WHO-Guided Family Planning',
            Icons.family_restroom_rounded,
            MaaColors.pink,
            imageEmoji: '👨‍👩‍👧‍👦',
          ),
          const SizedBox(height: 24),
          
          // WHO Badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.success.withAlpha(30),
                  MaaColors.softGreen.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.success.withAlpha(50)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MaaColors.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🌍', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Guided by the World Health Organization',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MaaColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'All information in this section is based on the evidence-based principles and guidelines of the WHO, ensuring you receive safe, accurate, and trustworthy information about your reproductive health.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          
          const SizedBox(height: 24),
          
          // Key Features
          _buildSubHeader('What You\'ll Find Here'),
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            'Health Benefits',
            'Learn how family planning improves maternal and child health outcomes.',
            Icons.health_and_safety_rounded,
            MaaColors.pink,
          ),
          _buildFeatureCard(
            'Fertility Tracking',
            'Discover natural methods to understand your fertility cycle.',
            Icons.calendar_month_rounded,
            MaaColors.success,
          ),
          _buildFeatureCard(
            'Modern Options',
            'Explore WHO-recommended contraceptive methods.',
            Icons.medical_services_rounded,
            MaaColors.lightBlue,
          ),
          _buildFeatureCard(
            'Support Resources',
            'Get help and guidance for family planning challenges.',
            Icons.support_agent_rounded,
            MaaColors.peach,
          ),
          
          const SizedBox(height: 24),
          
          // Human Rights Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.gold.withAlpha(30),
                  MaaColors.pink.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.gold.withAlpha(50)),
            ),
            child: Column(
              children: [
                const Text('✨', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  'A Fundamental Human Right',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Family planning is a fundamental human right. It empowers individuals to make informed decisions about their health and future.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _WhyImportantContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Why Family Planning is Important',
            Icons.favorite_rounded,
            MaaColors.softPurple,
            imageEmoji: '❤️',
          ),
          const SizedBox(height: 24),
          
          Text(
            'Understand the health and societal benefits of planning your family.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          
          // Benefits Cards
          _buildBenefitCard(
            'Reduces Health Risks',
            'Reduces health risks for mothers and leads to healthier babies. Proper spacing between pregnancies allows the mother\'s body to recover.',
            Icons.pregnant_woman_rounded,
            MaaColors.pink,
          ),
          _buildBenefitCard(
            'Better Investment',
            'Allows parents to invest more in each child\'s nutrition and education, leading to better outcomes for the entire family.',
            Icons.school_rounded,
            MaaColors.softPurple,
          ),
          _buildBenefitCard(
            'Financial Stability',
            'Reduces financial strain on the family by allowing parents to plan and prepare for each child\'s needs.',
            Icons.account_balance_wallet_rounded,
            MaaColors.success,
          ),
          _buildBenefitCard(
            'Gender Equality',
            'Contributes to gender equality by giving women control over their reproductive health and allowing them to pursue education and careers.',
            Icons.people_rounded,
            MaaColors.lightBlue,
          ),
          _buildBenefitCard(
            'Community Well-being',
            'Leads to healthier, more prosperous communities by ensuring every child is wanted and can be properly cared for.',
            Icons.location_city_rounded,
            MaaColors.peach,
          ),
          
          const SizedBox(height: 24),
          
          // Stats Card
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
                Text(
                  '📊 Impact Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.pink,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('44%', 'Reduction in maternal deaths'),
                _buildStatRow('33%', 'Reduction in infant mortality'),
                _buildStatRow('50%', 'More likely to send children to school'),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FertilityAwarenessContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Fertility Awareness-Based Methods',
            Icons.calendar_today_rounded,
            MaaColors.success,
            imageEmoji: '📊',
          ),
          const SizedBox(height: 24),
          
          Text(
            'Track your body\'s natural signs to identify fertile days. These methods help you understand your cycle for planning or preventing pregnancy.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          
          // Methods
          _buildSubHeader('Tracking Methods'),
          const SizedBox(height: 16),
          
          _buildMethodDetailCard(
            'Calendar Method',
            'Track your menstrual cycle on a calendar to predict fertile days. Requires consistent tracking over several months.',
            Icons.calendar_month_rounded,
            MaaColors.pink,
          ),
          _buildMethodDetailCard(
            'Basal Body Temperature (BBT)',
            'Measure your temperature every morning before getting out of bed. A slight rise indicates ovulation has occurred.',
            Icons.thermostat_rounded,
            MaaColors.softPurple,
          ),
          _buildMethodDetailCard(
            'Cervical Mucus Monitoring',
            'Observe changes in cervical mucus throughout your cycle. Fertile mucus is clear, slippery, and stretchy like egg whites.',
            Icons.water_drop_rounded,
            MaaColors.lightBlue,
          ),
          _buildMethodDetailCard(
            'Symptothermal Method',
            'Combines BBT, cervical mucus, and other fertility signs for more accurate tracking.',
            Icons.analytics_rounded,
            MaaColors.success,
          ),
          
          const SizedBox(height: 24),
          
          // Pros & Cons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.success.withAlpha(25),
                  MaaColors.softGreen.withAlpha(15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.success.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Advantages',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.success,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Free and has no side effects'),
                _buildBulletPoint('No hormones or devices needed'),
                _buildBulletPoint('Can be used to achieve or avoid pregnancy'),
                _buildBulletPoint('Helps you understand your body better'),
                const SizedBox(height: 16),
                Text(
                  '⚠️ Considerations',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.warning,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Generally less reliable than modern contraceptives'),
                _buildBulletPoint('Requires daily tracking and commitment'),
                _buildBulletPoint('Effectiveness varies with cycle regularity'),
                _buildBulletPoint('Not suitable for those with irregular periods'),
              ],
            ),
          ).animate().fadeIn(),
          
          const SizedBox(height: 24),
          
          // Guidance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MaaColors.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MaaColors.gold.withAlpha(50)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Effectiveness depends heavily on correct and consistent use. Consult a health provider to learn these methods properly.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: MaaColors.textPrimary,
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

class _ModernMethodsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Modern Contraceptive Methods',
            Icons.medical_services_rounded,
            MaaColors.lightBlue,
            imageEmoji: '💊',
          ),
          const SizedBox(height: 24),
          
          Text(
            'Explore a wide range of safe and effective options recommended by the WHO. Modern contraceptives offer high effectiveness and variety to fit your lifestyle.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          
          // Categories
          _buildSubHeader('Method Categories'),
          const SizedBox(height: 16),
          
          _buildCategoryGrid(),
          
          const SizedBox(height: 24),
          
          // Link to Contraception Guide
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/contraception'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MaaColors.pink.withAlpha(40),
                    MaaColors.softPurple.withAlpha(25),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MaaColors.pink.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: MaaColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore Full Contraception Guide',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MaaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detailed info on 16+ contraceptive methods including effectiveness, pros, and cons.',
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
            ),
          ).animate().fadeIn(),
          
          const SizedBox(height: 24),
          
          // Quick Reference Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MaaColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Quick Effectiveness Reference',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEffectivenessRow('Implant, IUD, Sterilization', '99%', MaaColors.success),
                _buildEffectivenessRow('Pill, Patch, Ring', '93%', MaaColors.warning),
                _buildEffectivenessRow('Condoms', '87%', MaaColors.warning),
                _buildEffectivenessRow('Fertility Awareness', '76-88%', MaaColors.peach),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _InfertilitySupportContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            'Infertility Support',
            Icons.support_rounded,
            MaaColors.peach,
            imageEmoji: '🤝',
          ),
          const SizedBox(height: 24),
          
          // Support Message
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
                const Text('💕', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  'You Are Not Alone',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.pink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Infertility is a common issue affecting millions of couples worldwide. It is a medical condition, not a personal failure. Help and support are available.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(),
          
          const SizedBox(height: 24),
          
          // When to Seek Help
          _buildSubHeader('When to Consult a Healthcare Provider'),
          const SizedBox(height: 16),
          
          _buildTimelineCard(
            'Under 35',
            'Try for 1 year without success before seeking help',
            '12',
            MaaColors.success,
          ),
          _buildTimelineCard(
            '35 or Older',
            'Try for 6 months without success before seeking help',
            '6',
            MaaColors.warning,
          ),
          _buildTimelineCard(
            'Irregular Periods',
            'Seek help earlier if you have irregular or painful periods',
            '!',
            MaaColors.pink,
          ),
          
          const SizedBox(height: 24),
          
          // Common Causes
          _buildSubHeader('Common Causes'),
          const SizedBox(height: 16),
          
          _buildCauseCard(
            'Female Factors',
            [
              'Ovulation disorders (PCOS)',
              'Blocked fallopian tubes',
              'Endometriosis',
              'Age-related factors',
              'Uterine abnormalities',
            ],
            Icons.female_rounded,
            MaaColors.pink,
          ),
          _buildCauseCard(
            'Male Factors',
            [
              'Low sperm count',
              'Poor sperm motility',
              'Abnormal sperm shape',
              'Varicocele',
              'Hormonal imbalances',
            ],
            Icons.male_rounded,
            MaaColors.lightBlue,
          ),
          
          const SizedBox(height: 24),
          
          // Treatment Options
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.peach.withAlpha(30),
                  MaaColors.gold.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.peach.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏥 Treatment Options',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.peach,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTreatmentItem('Lifestyle Changes', 'Weight, diet, exercise, stress reduction'),
                _buildTreatmentItem('Medications', 'Ovulation induction, hormone therapy'),
                _buildTreatmentItem('Surgical Procedures', 'Laparoscopy, hysteroscopy, varicocele repair'),
                _buildTreatmentItem('Assisted Reproductive Technology', 'IUI, IVF, ICSI'),
                _buildTreatmentItem('Alternative Options', 'Adoption, surrogacy, donor programs'),
              ],
            ),
          ).animate().fadeIn(),
          
          const SizedBox(height: 24),
          
          // Emotional Support
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MaaColors.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MaaColors.glassBorder),
            ),
            child: Column(
              children: [
                const Text('🫂', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  'Emotional Support is Important',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consider joining support groups, talking to a counselor, or connecting with others going through similar experiences. Your mental health matters.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
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
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: MaaColors.textPrimary,
    ),
  );
}

Widget _buildBulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
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
              fontSize: 13,
              color: MaaColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: MaaColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(100), color.withAlpha(50)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
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
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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

Widget _buildBenefitCard(String title, String description, IconData icon, Color color) {
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(150), color.withAlpha(80)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: MaaColors.textPrimary,
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

Widget _buildStatRow(String percentage, String description) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: MaaColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            percentage,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
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

Widget _buildMethodDetailCard(String title, String description, IconData icon, Color color) {
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(100), color.withAlpha(50)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
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
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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

Widget _buildCategoryGrid() {
  final categories = [
    {'name': 'Hormonal', 'emoji': '💊', 'color': MaaColors.pink},
    {'name': 'Barrier', 'emoji': '🛡️', 'color': MaaColors.lightBlue},
    {'name': 'IUD', 'emoji': '⭕', 'color': MaaColors.softPurple},
    {'name': 'Permanent', 'emoji': '🔒', 'color': MaaColors.warning},
    {'name': 'Emergency', 'emoji': '🚨', 'color': MaaColors.peach},
    {'name': 'Natural', 'emoji': '🌿', 'color': MaaColors.success},
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: categories.length,
    itemBuilder: (context, index) {
      final cat = categories[index];
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (cat['color'] as Color).withAlpha(40),
              (cat['color'] as Color).withAlpha(20),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (cat['color'] as Color).withAlpha(40)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cat['emoji'] as String,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              cat['name'] as String,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MaaColors.textPrimary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (50 * index).ms);
    },
  );
}

Widget _buildEffectivenessRow(String method, String effectiveness, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            method,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: MaaColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            effectiveness,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTimelineCard(String age, String description, String time, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: MaaColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(150), color.withAlpha(80)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: time == '!' ? 24 : 18,
                fontWeight: FontWeight.w800,
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
                age,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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

Widget _buildCauseCard(String title, List<String> items, IconData icon, Color color) {
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
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              title,
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

Widget _buildTreatmentItem(String title, String description) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: MaaColors.peach.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_rounded, color: MaaColors.peach, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.textPrimary,
                ),
              ),
              Text(
                description,
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
  );
}

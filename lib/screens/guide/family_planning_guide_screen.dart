// ============================================================
//  Family Planning Guide – MaaCare Premium
//  WHO-guided tools and resources for reproductive health
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../app_theme.dart';
import 'data/guide_localizations.dart';

class FamilyPlanningGuideScreen extends StatefulWidget {
  const FamilyPlanningGuideScreen({super.key});

  @override
  State<FamilyPlanningGuideScreen> createState() =>
      _FamilyPlanningGuideScreenState();
}

class _FamilyPlanningGuideScreenState extends State<FamilyPlanningGuideScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  List<PlanningSection> _getSections(Map<String, dynamic> data) {
    return [
      PlanningSection(
        title: data['tabs'][0],
        icon: Icons.family_restroom_rounded,
        color: MaaColors.pink,
        imageEmoji: '👨‍👩‍👧‍👦',
        content: _OverviewContent(data: data),
      ),
      PlanningSection(
        title: data['tabs'][1],
        icon: Icons.favorite_rounded,
        color: MaaColors.softPurple,
        imageEmoji: '❤️',
        content: _WhyImportantContent(data: data['important']),
      ),
      PlanningSection(
        title: data['tabs'][2],
        icon: Icons.calendar_today_rounded,
        color: MaaColors.success,
        imageEmoji: '📊',
        content: _FertilityAwarenessContent(data: data['fertility']),
      ),
      PlanningSection(
        title: data['tabs'][3],
        icon: Icons.medical_services_rounded,
        color: MaaColors.lightBlue,
        imageEmoji: '💊',
        content: _ModernMethodsContent(data: data['modern']),
      ),
      PlanningSection(
        title: data['tabs'][4],
        icon: Icons.support_rounded,
        color: MaaColors.peach,
        imageEmoji: '🤝',
        content: _InfertilitySupportContent(data: data['support']),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = GuideLocalizations.getFamilyPlanningData(context);
    final sections = _getSections(data);

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
                AppLocalizations.of(context).familyPlanning,
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
                tabs: sections
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
          children: sections.map((s) => s.content).toList(),
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
  final Map<String, dynamic> data;
  const _OverviewContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['overview']['header'],
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
                        data['overview']['whoBadgeTitle'],
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
                  data['overview']['whoBadgeDesc'],
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
          _buildSubHeader(data['overview']['subHeader']),
          const SizedBox(height: 16),

          ...(data['overview']['features'] as List)
              .asMap()
              .entries
              .map((e) => _buildFeatureCard(
                    e.value['title'],
                    e.value['desc'],
                    [
                      Icons.health_and_safety_rounded,
                      Icons.calendar_month_rounded,
                      Icons.medical_services_rounded,
                      Icons.support_agent_rounded
                    ][e.key % 4],
                    [
                      MaaColors.pink,
                      MaaColors.success,
                      MaaColors.lightBlue,
                      MaaColors.peach
                    ][e.key % 4],
                  )),

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
                  data['overview']['rightsTitle'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  data['overview']['rightsDesc'],
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
  final Map<String, dynamic> data;
  const _WhyImportantContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.favorite_rounded,
            MaaColors.softPurple,
            imageEmoji: '❤️',
          ),
          const SizedBox(height: 24),

          Text(
            data['intro'],
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Benefits Cards
          ...(data['benefits'] as List)
              .asMap()
              .entries
              .map((e) => _buildBenefitCard(
                    e.value['title'],
                    e.value['desc'],
                    [
                      Icons.pregnant_woman_rounded,
                      Icons.school_rounded,
                      Icons.account_balance_wallet_rounded,
                      Icons.people_rounded,
                      Icons.location_city_rounded
                    ][e.key % 5],
                    [
                      MaaColors.pink,
                      MaaColors.softPurple,
                      MaaColors.success,
                      MaaColors.lightBlue,
                      MaaColors.peach
                    ][e.key % 5],
                  )),

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
                  data['statsTitle'],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.pink,
                  ),
                ),
                const SizedBox(height: 16),
                ...(data['stats'] as List)
                    .map((s) => _buildStatRow(s['val'], s['desc'])),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FertilityAwarenessContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FertilityAwarenessContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.calendar_today_rounded,
            MaaColors.success,
            imageEmoji: '📊',
          ),
          const SizedBox(height: 24),

          Text(
            data['intro'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Methods
          _buildSubHeader(data['subHeader']),
          const SizedBox(height: 16),

          ...(data['methods'] as List)
              .asMap()
              .entries
              .map((e) => _buildMethodDetailCard(
                    e.value['title'],
                    e.value['desc'],
                    [
                      Icons.calendar_month_rounded,
                      Icons.thermostat_rounded,
                      Icons.water_drop_rounded,
                      Icons.analytics_rounded
                    ][e.key % 4],
                    [
                      MaaColors.pink,
                      MaaColors.softPurple,
                      MaaColors.lightBlue,
                      MaaColors.success
                    ][e.key % 4],
                  )),

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
                  "✅ ${data['prosTitle']}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.success,
                  ),
                ),
                const SizedBox(height: 12),
                ...(data['pros'] as List)
                    .map((a) => _buildBulletPoint(a.toString())),
                const SizedBox(height: 16),
                Text(
                  "⚠️ ${data['consTitle']}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.warning,
                  ),
                ),
                const SizedBox(height: 12),
                ...(data['cons'] as List)
                    .map((c) => _buildBulletPoint(c.toString())),
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
                    data['tipDesc'],
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
  final Map<String, dynamic> data;
  const _ModernMethodsContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.medical_services_rounded,
            MaaColors.lightBlue,
            imageEmoji: '💊',
          ),
          const SizedBox(height: 24),

          Text(
            data['intro'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
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
                          data['exploreTitle'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: MaaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['exploreDesc'],
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
                  "📋 ${data['quickTitle']}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ...(data['quickStats'] as List).asMap().entries.map((e) =>
                    _buildEffectivenessRow(
                        e.value['name'],
                        e.value['val'],
                        [
                          MaaColors.success,
                          MaaColors.warning,
                          MaaColors.warning,
                          MaaColors.peach
                        ][e.key % 4])),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _InfertilitySupportContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InfertilitySupportContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
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
                  data['notAloneTitle'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MaaColors.pink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  data['notAloneDesc'],
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

          // Sub 1
          _buildSubHeader(data['sub1']),
          const SizedBox(height: 16),

          ...(data['sub1Items'] as List)
              .asMap()
              .entries
              .map((e) => _buildTimelineCard(
                    e.value['title'],
                    e.value['desc'],
                    ['1', '2', '3'][e.key % 3],
                    [
                      MaaColors.success,
                      MaaColors.warning,
                      MaaColors.pink
                    ][e.key % 3],
                  )),

          const SizedBox(height: 24),

          // Sub 2
          _buildSubHeader(data['sub2']),
          const SizedBox(height: 16),

          ...(data['sub2Items'] as List)
              .asMap()
              .entries
              .map((e) => _buildMethodDetailCard(
                    e.value['title'],
                    e.value['desc'],
                    [
                      Icons.medical_services_rounded,
                      Icons.healing_rounded,
                      Icons.science_rounded,
                      Icons.favorite_rounded
                    ][e.key % 4],
                    [
                      MaaColors.pink,
                      MaaColors.lightBlue,
                      MaaColors.softPurple,
                      MaaColors.success
                    ][e.key % 4],
                  )),

          const SizedBox(height: 24),

          // Sub 3
          _buildSubHeader(data['sub3']),
          const SizedBox(height: 16),

          ...(data['sub3Items'] as List)
              .asMap()
              .entries
              .map((e) => _buildMethodDetailCard(
                    e.value['title'],
                    e.value['desc'],
                    [
                      Icons.psychology_rounded,
                      Icons.people_rounded,
                      Icons.self_improvement_rounded
                    ][e.key % 3],
                    [
                      MaaColors.peach,
                      MaaColors.success,
                      MaaColors.pink
                    ][e.key % 3],
                  )),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ============================================================
//  Helper Widgets
// ============================================================

Widget _buildHeader(String title, IconData icon, Color color,
    {String? imageEmoji}) {
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

Widget _buildFeatureCard(
    String title, String description, IconData icon, Color color) {
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

Widget _buildBenefitCard(
    String title, String description, IconData icon, Color color) {
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

Widget _buildMethodDetailCard(
    String title, String description, IconData icon, Color color) {
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



Widget _buildEffectivenessRow(
    String method, String effectiveness, Color color) {
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

Widget _buildTimelineCard(
    String age, String description, String time, Color color) {
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





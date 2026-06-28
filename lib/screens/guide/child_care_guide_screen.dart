// ============================================================
//  Child Care Guide – MaaCare Premium
//  Comprehensive parenting guide from breastfeeding to milestones
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../app_theme.dart';
import 'data/guide_localizations.dart';

class ChildCareGuideScreen extends StatefulWidget {
  const ChildCareGuideScreen({super.key});

  @override
  State<ChildCareGuideScreen> createState() => _ChildCareGuideScreenState();
}

class _ChildCareGuideScreenState extends State<ChildCareGuideScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  List<GuideSection> _getSections(Map<String, dynamic> data) {
    return [
      GuideSection(
        title: data['tabs'][0],
        icon: Icons.child_care_rounded,
        color: MaaColors.pink,
        imageEmoji: '🤱',
        content: _BreastfeedingContent(data: data['breastfeeding']),
      ),
      GuideSection(
        title: data['tabs'][1],
        icon: Icons.pregnant_woman_rounded,
        color: MaaColors.softPurple,
        imageEmoji: '💜',
        content: _LatchingContent(data: data['latching']),
      ),
      GuideSection(
        title: data['tabs'][2],
        icon: Icons.favorite_rounded,
        color: MaaColors.warning,
        imageEmoji: '🦘',
        content: _KMCContent(data: data['kmc']),
      ),
      GuideSection(
        title: data['tabs'][3],
        icon: Icons.restaurant_rounded,
        color: MaaColors.success,
        imageEmoji: '🥄',
        content: _FeedingContent(data: data['feeding']),
      ),
      GuideSection(
        title: data['tabs'][4],
        icon: Icons.baby_changing_station_rounded,
        color: MaaColors.lightBlue,
        imageEmoji: '🚽',
        content: _ToiletTrainingContent(data: data['toiletTraining']),
      ),
      GuideSection(
        title: data['tabs'][5],
        icon: Icons.toys_rounded,
        color: MaaColors.softGreen,
        imageEmoji: '🧸',
        content: _PlayDevelopmentContent(data: data['play']),
      ),
      GuideSection(
        title: data['tabs'][6],
        icon: Icons.auto_graph_rounded,
        color: MaaColors.peach,
        imageEmoji: '📈',
        content: _MilestonesContent(data: data['milestones']),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = GuideLocalizations.getChildCareData(context);
    final sections = _getSections(data);

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
                AppLocalizations.of(context).childCareGuide,
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
  final Map<String, dynamic> data;
  const _BreastfeedingContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.child_care_rounded,
            MaaColors.pink,
            imageEmoji: '🤱',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['infoTitle'],
            data['infoDesc'],
            MaaColors.softPurple,
          ),
          const SizedBox(height: 16),
          ...(data['bullets'] as List)
              .map((b) => _buildBulletPoint(b.toString())),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['tipTitle'],
            data['tipDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _LatchingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LatchingContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.pregnant_woman_rounded,
            MaaColors.softPurple,
            imageEmoji: '💜',
          ),
          const SizedBox(height: 20),
          ...(data['steps'] as List).asMap().entries.map((e) => _buildStepCard(
                '\${e.key + 1}',
                e.value['title'],
                e.value['desc'],
                [
                  MaaColors.pink,
                  MaaColors.softPurple,
                  MaaColors.warning,
                  MaaColors.success,
                  MaaColors.lightBlue
                ][e.key % 5],
              )),
          const SizedBox(height: 24),
          _buildSubHeader(data['subHeader']),
          const SizedBox(height: 16),
          ...(data['positions'] as List)
              .asMap()
              .entries
              .map((e) => _buildPositionCard(
                    e.value['title'],
                    e.value['desc'],
                    [
                      Icons.chair_rounded,
                      Icons.swap_horiz_rounded,
                      Icons.sports_rounded,
                      Icons.bed_rounded
                    ][e.key % 4],
                  )),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _KMCContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KMCContent({required this.data});

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
            MaaColors.warning,
            imageEmoji: '🦘',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['infoTitle'],
            data['infoDesc'],
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
                  data['howToTitle'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MaaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['howToDesc'],
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
          _buildSubHeader(data['benefitsTitle']),
          const SizedBox(height: 16),
          ...(data['benefits'] as List)
              .asMap()
              .entries
              .map((e) => _buildBenefitCard(
                  e.value.toString(),
                  [
                    Icons.thermostat_rounded,
                    Icons.favorite_rounded,
                    Icons.trending_up_rounded,
                    Icons.favorite_border_rounded,
                    Icons.child_care_rounded,
                    Icons.shield_rounded
                  ][e.key % 6])),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['rememberTitle'],
            data['rememberDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FeedingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FeedingContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.restaurant_rounded,
            MaaColors.success,
            imageEmoji: '🥄',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['infoTitle'],
            data['infoDesc'],
            MaaColors.peach,
          ),
          const SizedBox(height: 20),
          _buildSubHeader(data['subHeader']),
          const SizedBox(height: 16),
          ...(data['foods'] as List).asMap().entries.map((e) => _buildFoodCard(
                e.value.toString(),
                [
                  Icons.grain_rounded,
                  Icons.emoji_food_beverage_rounded,
                  Icons.spa_rounded,
                  Icons.local_dining_rounded
                ][e.key % 4],
                [
                  Colors.brown,
                  Colors.yellow.shade700,
                  Colors.green,
                  Colors.orange
                ][e.key % 4],
              )),
          const SizedBox(height: 20),
          ...(data['bullets'] as List)
              .map((t) => _buildBulletPoint(t.toString())),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['alertTitle'],
            data['alertDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _ToiletTrainingContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ToiletTrainingContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.baby_changing_station_rounded,
            MaaColors.lightBlue,
            imageEmoji: '🚽',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['infoTitle'],
            data['infoDesc'],
            MaaColors.lightBlue,
          ),
          const SizedBox(height: 20),
          _buildSubHeader(data['signsTitle']),
          const SizedBox(height: 16),
          ...(data['signs'] as List).map((s) => _buildCheckItem(s.toString())),
          const SizedBox(height: 20),
          _buildSubHeader(data['stepsTitle']),
          const SizedBox(height: 16),
          ...(data['steps'] as List).asMap().entries.map((e) => _buildStepCard(
                (e.key + 1).toString(),
                e.value['title'],
                e.value['desc'],
                [
                  MaaColors.pink,
                  MaaColors.softPurple,
                  MaaColors.success,
                  MaaColors.warning
                ][e.key % 4],
              )),
          const SizedBox(height: 20),
          _buildHighlightCard(
            data['tipTitle'],
            data['tipDesc'],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _PlayDevelopmentContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PlayDevelopmentContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.toys_rounded,
            MaaColors.softGreen,
            imageEmoji: '🧸',
          ),
          const SizedBox(height: 20),
          ...(data['ages'] as List).asMap().entries.map((e) => _buildAgeCard(
                e.value['title'],
                List<String>.from(e.value['items']),
                [
                  Icons.crib_rounded,
                  Icons.eco_rounded,
                  Icons.child_care_rounded,
                  Icons.face_rounded
                ][e.key % 4],
                [
                  MaaColors.pink,
                  MaaColors.softPurple,
                  MaaColors.warning,
                  MaaColors.success
                ][e.key % 4],
              )),
          const SizedBox(height: 20),
          _buildInfoCard(
            data['infoTitle'],
            data['infoDesc'],
            MaaColors.softGreen,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _MilestonesContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MilestonesContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            data['header'],
            Icons.trending_up_rounded,
            MaaColors.peach,
            imageEmoji: '📈',
          ),
          const SizedBox(height: 20),
          ...(data['stages'] as List)
              .asMap()
              .entries
              .map((e) => _buildMilestoneCard(
                    e.value['title'],
                    List<String>.from(e.value['items']),
                    [
                      MaaColors.pink,
                      MaaColors.softPurple,
                      MaaColors.warning,
                      MaaColors.success
                    ][e.key % 4],
                  )),
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
                const Icon(Icons.info_rounded,
                    color: MaaColors.peach, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    data['disclaimer'],
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

Widget _buildHeader(String title, IconData icon, Color color,
    {String? imageEmoji}) {
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

Widget _buildStepCard(
    String number, String title, String content, Color color) {
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
        const Icon(Icons.check_circle_rounded,
            color: MaaColors.success, size: 22),
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

Widget _buildAgeCard(
    String age, List<String> items, IconData icon, Color color) {
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

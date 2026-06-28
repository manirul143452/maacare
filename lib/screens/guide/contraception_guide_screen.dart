// ============================================================
//  Contraception Guide – MaaCare Premium
//  WHO-based birth control methods guide
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../app_theme.dart';
import 'data/guide_localizations.dart';

class ContraceptionGuideScreen extends StatefulWidget {
  const ContraceptionGuideScreen({super.key});

  @override
  State<ContraceptionGuideScreen> createState() => _ContraceptionGuideScreenState();
}

class _ContraceptionGuideScreenState extends State<ContraceptionGuideScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  List<ContraceptionCategory> _getCategories(Map<String, dynamic> data) {
    final m = data['methods'];
    return [
      ContraceptionCategory(
        title: data['tabs'][0],
        icon: Icons.medication_rounded,
        color: MaaColors.pink,
        imageEmoji: '💊',
        methods: [
          _buildMethod(m['implant'], '📍', MaaColors.pink),
          _buildMethod(m['injection'], '💉', MaaColors.pink),
          _buildMethod(m['pills'], '💊', MaaColors.pink),
          _buildMethod(m['iudHormonal'], '⭕', MaaColors.pink),
        ],
      ),
      ContraceptionCategory(
        title: data['tabs'][2], // Barrier
        icon: Icons.shield_rounded,
        color: MaaColors.lightBlue,
        imageEmoji: '🛡️',
        methods: [
          _buildMethod(m['maleCondom'], '🍌', MaaColors.lightBlue),
          _buildMethod(m['femaleCondom'], '🛡️', MaaColors.lightBlue),
          _buildMethod(m['diaphragm'], '🥣', MaaColors.lightBlue),
        ],
      ),
      ContraceptionCategory(
        title: 'IUD', // Static or should use from data, but keeping simple
        icon: Icons.device_hub_rounded,
        color: MaaColors.softPurple,
        imageEmoji: '⭕',
        methods: [
          _buildMethod(m['iudHormonal'], '⭕', MaaColors.softPurple),
          _buildMethod(m['iudCopper'], '🔶', MaaColors.softPurple),
        ],
      ),
      ContraceptionCategory(
        title: data['tabs'][3], // Permanent
        icon: Icons.perm_device_information_rounded,
        color: MaaColors.warning,
        imageEmoji: '🔒',
        methods: [
          _buildMethod(m['vasectomy'], '✂️', MaaColors.warning),
          _buildMethod(m['tubal'], '🔒', MaaColors.warning),
        ],
      ),
      ContraceptionCategory(
        title: data['tabs'][4], // Emergency
        icon: Icons.emergency_rounded,
        color: MaaColors.peach,
        imageEmoji: '🚨',
        methods: [
          _buildMethod(m['emergencyPills'], '🚨', MaaColors.peach),
          _buildMethod(m['emergencyIud'], '⚡', MaaColors.peach),
        ],
      ),
      ContraceptionCategory(
        title: data['tabs'][5], // Natural
        icon: Icons.nature_rounded,
        color: MaaColors.softGreen,
        imageEmoji: '🌿',
        methods: [
          _buildMethod(m['fam'], '📅', MaaColors.softGreen),
          _buildMethod(m['withdrawal'], '🏃', MaaColors.softGreen),
          _buildMethod(m['lam'], '🤱', MaaColors.softGreen),
        ],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = GuideLocalizations.getContraceptionData(context);
    final categories = _getCategories(data);

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
                AppLocalizations.of(context).contraception,
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
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 140,
                          height: 140,
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
                                  '🛡️',
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
                tabs: categories
                    .map((c) => Tab(
                          icon: Icon(c.icon, size: 20),
                          text: c.title,
                        ))
                    .toList(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: categories.map((c) => _buildCategoryContent(c, data)).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryContent(ContraceptionCategory category, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WHO Endorsement Card
          _buildWHOEndorsementCard(data),
          const SizedBox(height: 24),
          
          // Category Header with Image
          _buildCategoryHeader(category, data),
          const SizedBox(height: 20),
          
          // Methods List
          ...category.methods.asMap().entries.map((entry) {
            return _buildMethodCard(entry.value, entry.key, data);
          }),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildWHOEndorsementCard(Map<String, dynamic> data) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MaaColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🌍', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Text(
                data['endorsementTitle'],
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MaaColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['endorsementDesc'],
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: MaaColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildCategoryHeader(ContraceptionCategory category, Map<String, dynamic> data) {
    return Column(
      children: [
        // Main Image
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.color.withAlpha(60),
                category.color.withAlpha(30),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: category.color.withAlpha(40),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              category.imageEmoji,
              style: const TextStyle(fontSize: 70),
            ),
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
        const SizedBox(height: 16),
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    category.color.withAlpha(150),
                    category.color.withAlpha(80),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              '${category.title} Methods',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: MaaColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodCard(ContraceptionMethod method, int index, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: method.color.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: method.color.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  method.color.withAlpha(40),
                  method.color.withAlpha(20),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        method.color.withAlpha(150),
                        method.color.withAlpha(80),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    method.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: MaaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              method.color.withAlpha(100),
                              method.color.withAlpha(50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${data['methodLabels']['effectiveness']}: ${method.effectiveness}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: method.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  method.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                // Pros
                _buildProsConsSection(
                  data['methodLabels']['pros'],
                  method.pros,
                  Icons.check_circle_rounded,
                  MaaColors.success,
                ),
                const SizedBox(height: 16),
                // Cons
                _buildProsConsSection(
                  data['methodLabels']['cons'],
                  method.cons,
                  Icons.cancel_rounded,
                  MaaColors.warning,
                ),
                const SizedBox(height: 16),
                // Best For
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        method.color.withAlpha(25),
                        method.color.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: method.color.withAlpha(40)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: method.color,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['methodLabels']['bestFor'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: method.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              method.bestFor,
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
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildProsConsSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Column(
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
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

// ============================================================
//  Data Models
// ============================================================

class ContraceptionCategory {
  final String title;
  final IconData icon;
  final Color color;
  final String imageEmoji;
  final List<ContraceptionMethod> methods;

  ContraceptionCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.imageEmoji,
    required this.methods,
  });
}

class ContraceptionMethod {
  final String name;
  final String emoji;
  final String effectiveness;
  final String description;
  final List<String> pros;
  final List<String> cons;
  final String bestFor;
  final Color color;

  ContraceptionMethod({
    required this.name,
    required this.emoji,
    required this.effectiveness,
    required this.description,
    required this.pros,
    required this.cons,
    required this.bestFor,
    required this.color,
  });
}

// ============================================================
//  All Contraception Methods Data
// ============================================================

ContraceptionMethod _buildMethod(Map<String, dynamic> methodData, String emoji, Color color) {
  return ContraceptionMethod(
    name: methodData['name'],
    emoji: emoji,
    effectiveness: methodData['effectiveness'],
    description: methodData['description'],
    color: color,
    pros: List<String>.from(methodData['pros']),
    cons: List<String>.from(methodData['cons']),
    bestFor: methodData['bestFor'],
  );
}

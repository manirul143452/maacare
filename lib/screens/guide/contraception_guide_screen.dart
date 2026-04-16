// ============================================================
//  Contraception Guide – MaaCare Premium
//  WHO-based birth control methods guide
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';

class ContraceptionGuideScreen extends StatefulWidget {
  const ContraceptionGuideScreen({super.key});

  @override
  State<ContraceptionGuideScreen> createState() => _ContraceptionGuideScreenState();
}

class _ContraceptionGuideScreenState extends State<ContraceptionGuideScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<ContraceptionCategory> _categories = [
    ContraceptionCategory(
      title: 'Hormonal',
      icon: Icons.medication_rounded,
      color: MaaColors.pink,
      imageEmoji: '💊',
      methods: [
        _buildContraceptiveImplant(),
        _buildContraceptiveInjectable(),
        _buildBirthControlPill(),
        _buildHormonalIUD(),
      ],
    ),
    ContraceptionCategory(
      title: 'Barrier',
      icon: Icons.shield_rounded,
      color: MaaColors.lightBlue,
      imageEmoji: '🛡️',
      methods: [
        _buildMaleCondom(),
        _buildFemaleCondom(),
        _buildDiaphragm(),
      ],
    ),
    ContraceptionCategory(
      title: 'IUD',
      icon: Icons.device_hub_rounded,
      color: MaaColors.softPurple,
      imageEmoji: '⭕',
      methods: [
        _buildHormonalIUDDetail(),
        _buildCopperIUD(),
      ],
    ),
    ContraceptionCategory(
      title: 'Permanent',
      icon: Icons.perm_device_information_rounded,
      color: MaaColors.warning,
      imageEmoji: '🔒',
      methods: [
        _buildVasectomy(),
        _buildTubalLigation(),
      ],
    ),
    ContraceptionCategory(
      title: 'Emergency',
      icon: Icons.emergency_rounded,
      color: MaaColors.peach,
      imageEmoji: '🚨',
      methods: [
        _buildEmergencyContraceptivePills(),
        _buildCopperIUDEmergency(),
      ],
    ),
    ContraceptionCategory(
      title: 'Natural',
      icon: Icons.nature_rounded,
      color: MaaColors.softGreen,
      imageEmoji: '🌿',
      methods: [
        _buildFertilityAwareness(),
        _buildWithdrawal(),
        _buildLactationalAmenorrhea(),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
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
                'Contraception Guide',
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
                tabs: _categories
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
          children: _categories.map((c) => _buildCategoryContent(c)).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryContent(ContraceptionCategory category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WHO Endorsement Card
          _buildWHOEndorsementCard(),
          const SizedBox(height: 24),
          
          // Category Header with Image
          _buildCategoryHeader(category),
          const SizedBox(height: 20),
          
          // Methods List
          ...category.methods.asMap().entries.map((entry) {
            return _buildMethodCard(entry.value, entry.key);
          }),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildWHOEndorsementCard() {
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
                'WHO Endorsement',
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
            'The best method of contraception depends on your health, lifestyle, and personal preferences. This guide provides information based on WHO recommendations to help you make an informed choice. Always discuss options with a healthcare provider.',
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

  Widget _buildCategoryHeader(ContraceptionCategory category) {
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

  Widget _buildMethodCard(ContraceptionMethod method, int index) {
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
                          'Effectiveness: ${method.effectiveness}',
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
                  'Pros',
                  method.pros,
                  Icons.check_circle_rounded,
                  MaaColors.success,
                ),
                const SizedBox(height: 16),
                // Cons
                _buildProsConsSection(
                  'Cons',
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
                              'Best For',
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

ContraceptionMethod _buildContraceptiveImplant() {
  return ContraceptionMethod(
    name: 'Contraceptive Implant',
    emoji: '📍',
    effectiveness: '99%',
    description: 'A thin, flexible rod inserted under the skin of the upper arm, releasing hormones to prevent pregnancy.',
    color: MaaColors.pink,
    pros: [
      'Long-lasting (up to 3 years) and highly effective',
      'Low maintenance; "set it and forget it"',
      'Fertility returns quickly after removal',
      'Can reduce menstrual cramps and acne',
    ],
    cons: [
      'Requires a trained provider for insertion and removal',
      'Can cause irregular bleeding, especially in the first year',
      'Does not protect against STIs',
      'May cause mood changes or weight gain',
    ],
    bestFor: 'Those looking for long-term, low-maintenance, and highly effective contraception.',
  );
}

ContraceptionMethod _buildContraceptiveInjectable() {
  return ContraceptionMethod(
    name: 'Contraceptive Injectable',
    emoji: '💉',
    effectiveness: '96%',
    description: 'A hormone injection given by a healthcare provider every 1 to 3 months to prevent pregnancy.',
    color: MaaColors.pink,
    pros: [
      'Highly effective and discreet',
      'Requires only periodic visits to a provider',
      'Can reduce menstrual cramps and heavy bleeding',
      'No daily pills to remember',
    ],
    cons: [
      'Return to fertility can be delayed after stopping',
      'Can cause changes in menstrual bleeding',
      'Possible bone density changes with long-term use',
      'Does not protect against STIs',
    ],
    bestFor: 'Individuals who want a highly effective, low-maintenance method and don\'t plan to get pregnant soon.',
  );
}

ContraceptionMethod _buildBirthControlPill() {
  return ContraceptionMethod(
    name: 'Birth Control Pill',
    emoji: '💊',
    effectiveness: '93%',
    description: 'A daily pill that contains hormones to prevent pregnancy by stopping ovulation.',
    color: MaaColors.pink,
    pros: [
      'Highly effective when taken correctly',
      'Can make periods lighter and more regular',
      'May reduce acne and menstrual cramps',
      'Fertility returns quickly after stopping',
    ],
    cons: [
      'Must be taken at the same time every day',
      'Does not protect against STIs',
      'Can have side effects like mood changes or nausea',
      'Requires prescription',
    ],
    bestFor: 'Individuals who can remember to take a pill daily and want lighter, regular periods.',
  );
}

ContraceptionMethod _buildHormonalIUD() {
  return ContraceptionMethod(
    name: 'Hormonal IUD',
    emoji: '⭕',
    effectiveness: '99%',
    description: 'A T-shaped device placed in the uterus that releases a small amount of progestin to prevent pregnancy.',
    color: MaaColors.pink,
    pros: [
      'Long-lasting (3-10 years) and highly effective',
      'Often makes periods lighter and less painful',
      'Fertility returns quickly after removal',
      'Low maintenance once inserted',
    ],
    cons: [
      'Insertion can be uncomfortable or painful',
      'Can cause irregular bleeding initially',
      'Small risk of expulsion or perforation',
      'Does not protect against STIs',
    ],
    bestFor: 'Those looking for long-term, low-maintenance, and highly effective hormonal contraception.',
  );
}

ContraceptionMethod _buildHormonalIUDDetail() {
  return _buildHormonalIUD();
}

ContraceptionMethod _buildCopperIUD() {
  return ContraceptionMethod(
    name: 'Copper IUD',
    emoji: '🔶',
    effectiveness: '99%',
    description: 'A hormone-free, T-shaped device wrapped in copper, placed in the uterus to prevent pregnancy.',
    color: MaaColors.softPurple,
    pros: [
      'Long-lasting (3-10 years) and highly effective',
      'Hormone-free, so no hormonal side effects',
      'Fertility returns quickly after removal',
      'Can be used as emergency contraception if inserted within 5 days',
    ],
    cons: [
      'Insertion can be uncomfortable or painful',
      'Can cause irregular bleeding initially',
      'Can make periods heavier and more painful',
      'Does not protect against STIs',
    ],
    bestFor: 'Those who want a long-term, highly effective method without hormones.',
  );
}

ContraceptionMethod _buildMaleCondom() {
  return ContraceptionMethod(
    name: 'Male Condom',
    emoji: '🍌',
    effectiveness: '87%',
    description: 'A thin barrier worn on the penis during sex to prevent sperm from entering the uterus.',
    color: MaaColors.lightBlue,
    pros: [
      'The only method that also protects against STIs, including HIV',
      'Widely available and affordable',
      'Non-hormonal and used only when needed',
      'No prescription required',
    ],
    cons: [
      'Can break or slip off if not used correctly',
      'Requires consistent and correct use every time',
      'May reduce sensitivity',
      'Effectiveness depends on correct use',
    ],
    bestFor: 'Preventing both pregnancy and STIs, and for those who prefer a non-hormonal, on-demand method.',
  );
}

ContraceptionMethod _buildFemaleCondom() {
  return ContraceptionMethod(
    name: 'Female Condom',
    emoji: '🛡️',
    effectiveness: '79%',
    description: 'A soft, loose-fitting pouch inserted into the vagina before sex to prevent pregnancy.',
    color: MaaColors.lightBlue,
    pros: [
      'Protects against STIs including HIV',
      'Can be inserted up to 8 hours before sex',
      'No prescription required',
      'Non-hormonal option',
    ],
    cons: [
      'Less effective than male condoms',
      'Can be noisy during sex',
      'Requires proper insertion technique',
      'More expensive than male condoms',
    ],
    bestFor: 'Women who want STI protection and control over their contraception.',
  );
}

ContraceptionMethod _buildDiaphragm() {
  return ContraceptionMethod(
    name: 'Diaphragm',
    emoji: '🥣',
    effectiveness: '83%',
    description: 'A shallow, dome-shaped cup inserted into the vagina to cover the cervix and block sperm.',
    color: MaaColors.lightBlue,
    pros: [
      'Reusable and lasts for several years',
      'Non-hormonal option',
      'Can be inserted up to 6 hours before sex',
      'No systemic side effects',
    ],
    cons: [
      'Requires fitting by healthcare provider',
      'Must be used with spermicide',
      'Can increase risk of UTI',
      'Does not protect against STIs',
    ],
    bestFor: 'Women who want a reusable, non-hormonal barrier method.',
  );
}

ContraceptionMethod _buildVasectomy() {
  return ContraceptionMethod(
    name: 'Vasectomy (Male Sterilization)',
    emoji: '✂️',
    effectiveness: '99%',
    description: 'A minor surgical procedure to cut or block the tubes that carry sperm, preventing them from leaving the body.',
    color: MaaColors.warning,
    pros: [
      'Permanent and one of the most effective forms of birth control',
      'A one-time procedure with quick recovery',
      'No lasting effect on sex drive or performance',
      'No ongoing costs after procedure',
    ],
    cons: [
      'Permanent - reversal is difficult and not always successful',
      'Does not become effective immediately (takes about 3 months)',
      'Does not protect against STIs',
      'Requires surgical procedure',
    ],
    bestFor: 'Men or couples who are certain they do not want any more children.',
  );
}

ContraceptionMethod _buildTubalLigation() {
  return ContraceptionMethod(
    name: 'Tubal Ligation (Female Sterilization)',
    emoji: '🔒',
    effectiveness: '99%',
    description: 'A surgical procedure to permanently block or remove the fallopian tubes.',
    color: MaaColors.warning,
    pros: [
      'Permanent and one of the most effective forms of birth control',
      'Effective immediately and requires no ongoing user action',
      'No hormonal side effects',
      'No effect on sexual function or menopause',
    ],
    cons: [
      'Is a surgical procedure with associated risks',
      'Permanent - reversal is a major, often unsuccessful surgery',
      'Does not protect against STIs',
      'Requires anesthesia',
    ],
    bestFor: 'Women or couples who are certain they do not want any more children.',
  );
}

ContraceptionMethod _buildEmergencyContraceptivePills() {
  return ContraceptionMethod(
    name: 'Emergency Contraceptive Pills (ECPs)',
    emoji: '🚨',
    effectiveness: '95%',
    description: 'Pills that can be taken up to 5 days after unprotected sex to prevent pregnancy.',
    color: MaaColors.peach,
    pros: [
      'A safe option to prevent pregnancy after unprotected sex',
      'Available over-the-counter in many places',
      'No prescription required in most countries',
      'Safe for most women',
    ],
    cons: [
      'Not as effective as regular contraception',
      'Should not be used as a primary method',
      'Can cause temporary side effects like nausea',
      'May change timing of next period',
    ],
    bestFor: 'Emergency situations only - not for regular use.',
  );
}

ContraceptionMethod _buildCopperIUDEmergency() {
  return ContraceptionMethod(
    name: 'Copper IUD (Emergency Use)',
    emoji: '⚡',
    effectiveness: '99%',
    description: 'A copper IUD inserted within 5 days of unprotected sex as emergency contraception.',
    color: MaaColors.peach,
    pros: [
      'Most effective form of emergency contraception',
      'Can then be left in for ongoing contraception (10 years)',
      'Hormone-free option',
      'Works immediately',
    ],
    cons: [
      'Requires insertion by healthcare provider',
      'May cause cramping during insertion',
      'Higher upfront cost',
      'Does not protect against STIs',
    ],
    bestFor: 'Those who want the most effective emergency contraception and may want ongoing protection.',
  );
}

ContraceptionMethod _buildFertilityAwareness() {
  return ContraceptionMethod(
    name: 'Fertility Awareness Methods (FAM)',
    emoji: '📅',
    effectiveness: '76-88%',
    description: 'Tracking menstrual cycle to identify fertile days and avoid sex or use barrier methods during those times.',
    color: MaaColors.softGreen,
    pros: [
      'No physical side effects',
      'No cost after learning the method',
      'Helps understand your body and cycle better',
      'Useful for planning pregnancy too',
    ],
    cons: [
      'Requires consistent tracking and abstinence or barriers during fertile days',
      'Less effective than other methods',
      'Can be difficult with irregular cycles',
      'Does not protect against STIs',
    ],
    bestFor: 'Those with regular cycles who want a natural, hormone-free method and are willing to track carefully.',
  );
}

ContraceptionMethod _buildWithdrawal() {
  return ContraceptionMethod(
    name: 'Withdrawal (Pull-Out Method)',
    emoji: '🏃',
    effectiveness: '78%',
    description: 'The man withdraws his penis from the vagina before ejaculation to prevent sperm from entering.',
    color: MaaColors.softGreen,
    pros: [
      'No cost',
      'No devices or hormones needed',
      'Always available',
      'No side effects',
    ],
    cons: [
      'High failure rate with typical use',
      'Requires self-control and timing',
      'Pre-ejaculate may contain sperm',
      'Does not protect against STIs',
    ],
    bestFor: 'Couples who understand the risks and are comfortable with higher failure rates.',
  );
}

ContraceptionMethod _buildLactationalAmenorrhea() {
  return ContraceptionMethod(
    name: 'Lactational Amenorrhea Method (LAM)',
    emoji: '🤱',
    effectiveness: '98%',
    description: 'Temporary contraception after childbirth based on exclusive breastfeeding that suppresses ovulation.',
    color: MaaColors.softGreen,
    pros: [
      'Natural and no cost',
      'Provides optimal nutrition for baby',
      'Promotes bonding between mother and baby',
      'No side effects',
    ],
    cons: [
      'Only effective for up to 6 months postpartum',
      'Requires exclusive breastfeeding day and night',
      'Effectiveness decreases when periods return',
      'Does not protect against STIs',
    ],
    bestFor: 'New mothers who are exclusively breastfeeding and whose period has not yet returned.',
  );
}

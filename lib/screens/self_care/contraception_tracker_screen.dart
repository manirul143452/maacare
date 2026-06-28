// ============================================================
//  ContraceptionTrackerScreen – MaaCare
//  Specialized educational guide for contraception and safe planning
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app_theme.dart';
import '../guide/data/guide_localizations.dart';

class ContraceptionTrackerScreen extends StatefulWidget {
  const ContraceptionTrackerScreen({super.key});

  @override
  State<ContraceptionTrackerScreen> createState() => _ContraceptionTrackerScreenState();
}

class _ContraceptionTrackerScreenState extends State<ContraceptionTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  // Localized safety warnings and safe sex guidelines
  final Map<String, Map<String, String>> _safetyGuideLocalizations = {
    'en': {
      'warningTitle': '⚠️ CRITICAL HEALTH WARNING',
      'warningSub': 'Avoid Self-Medication',
      'warningDesc': 'Over-the-counter self-medication with hormonal methods (like daily pills, injections) or LARC (IUDs, implants) carries severe risks. These methods MUST ONLY be initiated after a professional medical screening to check for contraindications such as high blood pressure, clotting disorders, liver disease, or breast cancer.',
      'safeSexTitle': '🛡️ Safe Sex & Dual Protection',
      'safeSexDesc': 'Hormonal and LARC methods prevent pregnancy but offer 0% protection against Sexually Transmitted Infections (STIs) such as HIV, Syphilis, and Hepatitis B. For comprehensive protection, practice "Dual Protection" by using male or female condoms along with your primary contraceptive method.',
      'whoTitle': '🌍 WHO Medical Guidelines',
      'whoDesc': 'According to the World Health Organization (WHO), contraceptive efficacy is highly dependent on correct and consistent use. Understanding the difference between barrier methods (physically blocking sperm) and hormonal methods (preventing ovulation) helps in choosing the safest method for your body.',
      'tabGuidelines': 'WHO Guidelines',
      'tabDirectory': 'Methods Directory',
    },
    'hi': {
      'warningTitle': '⚠️ महत्वपूर्ण स्वास्थ्य चेतावनी',
      'warningSub': 'बिना डॉक्टर की सलाह के दवा न लें',
      'warningDesc': 'हार्मोनल तरीकों (जैसे दैनिक गोलियां, इंजेक्शन) या एलएआरसी (आईयूडी, इम्प्लांट) के साथ खुद से दवा लेने से गंभीर जोखिम हो सकते हैं। इन तरीकों को केवल एक पेशेवर चिकित्सा जांच के बाद ही शुरू किया जाना चाहिए ताकि उच्च रक्तचाप, रक्त के थक्के जमने के विकार, यकृत रोग, या स्तन कैंसर जैसे मतभेदों की जांच की जा सके।',
      'safeSexTitle': '🛡️ सुरक्षित यौन संबंध और दोहरा संरक्षण',
      'safeSexDesc': 'हॉर्मोनल और एलएआरसी तरीके गर्भावस्था को रोकते हैं लेकिन यौन संचारित संक्रमणों (एसटीआई) जैसे कि एचआईवी, सिफलिस और हेपेटाइटिस बी से 0% सुरक्षा प्रदान करते हैं। व्यापक सुरक्षा के लिए, अपने प्राथमिक गर्भनिरोधक तरीके के साथ पुरुष या महिला कंडोम का उपयोग करके "दोहरा संरक्षण" अपनाएं।',
      'whoTitle': '🌍 डब्ल्यूएचओ चिकित्सा दिशानिर्देश',
      'whoDesc': 'विश्व स्वास्थ्य संगठन (WHO) के अनुसार, गर्भनिरोधक प्रभावशीलता सही और लगातार उपयोग पर अत्यधिक निर्भर है। बैरियर विधियों (शारीरिक रूप से शुक्राणु को रोकना) और हार्मोनल विधियों (ओव्यूलेशन को रोकना) के बीच के अंतर को समझना आपके शरीर के लिए सबसे सुरक्षित तरीका चुनने में मदद करता है।',
      'tabGuidelines': 'डब्ल्यूएचओ दिशानिर्देश',
      'tabDirectory': 'गर्भनिरोधक तरीके',
    },
    'bn': {
      'warningTitle': '⚠️ গুরুত্বপূর্ণ স্বাস্থ্য সতর্কতা',
      'warningSub': 'নিজে নিজে ওষুধ খাওয়া এড়িয়ে চলুন',
      'warningDesc': 'হরমোনাল পদ্ধতি (যেমন দৈনিক পিল, ইনজেকশন) বা LARC (IUD, ইমপ্লান্ট) এর সাথে নিজে নিজে ওষুধ নেওয়া গুরুতর ঝুঁকি বহন করে। উচ্চ রক্তচাপ, রক্ত জমাট বাঁধার ব্যাধি, লিভারের রোগ বা স্তন ক্যান্সারের মতো জটিলতা পরীক্ষা করার জন্য এই পদ্ধতিগুলি অবশ্যই শুধুমাত্র একজন পেশাদার চিকিৎসকের পরামর্শের পরে শুরু করতে হবে।',
      'safeSexTitle': '🛡️ নিরাপদ মিলন এবং দ্বৈত সুরক্ষা',
      'safeSexDesc': 'হরমোনাল এবং LARC পদ্ধতি গর্ভাবস্থা প্রতিরোধ করে কিন্তু যৌনবাহিত সংক্রমণ (STIs) যেমন HIV, সিফিলিস এবং হেপাটাইটিস B এর বিরুদ্ধে ০% সুরক্ষা প্রদান করে। ব্যাপক সুরক্ষার জন্য, আপনার প্রাথমিক গর্ভনিরোধক পদ্ধতির সাথে পুরুষ বা মহিলা কনডম ব্যবহার করে "দ্বৈত সুরক্ষা" অনুশীলন করুন।',
      'whoTitle': '🌍 WHO নির্দেশিকা',
      'whoDesc': 'বিশ্ব স্বাস্থ্য সংস্থা (WHO)-এর মতে, গর্ভনিরোধক কার্যকারিতা সঠিক এবং ধারাবাহিক ব্যবহারের ওপর অত্যন্ত নির্ভরশীল। ব্যারিয়ার পদ্ধতি (শারীরিকভাবে শুক্রাণু ব্লক করা) এবং হরমোনাল পদ্ধতি (দ্বিম্বস্ফোটন প্রতিরোধ করা) এর মধ্যে পার্থক্য বোঝা আপনার শরীরের জন্য সবচেয়ে নিরাপদ পদ্ধতি বেছে নিতে সাহায্য করে।',
      'tabGuidelines': 'WHO নির্দেশিকা',
      'tabDirectory': 'পদ্ধতির তালিকা',
    }
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ContraceptionCategory> _getCategories(Map<String, dynamic> data) {
    final m = data['methods'];
    return [
      ContraceptionCategory(
        title: data['tabs'][0], // Hormonal
        icon: Icons.medication_rounded,
        color: MaaColors.pink,
        imageEmoji: '💊',
        methods: [
          _buildMethod(m['pills'], '💊', MaaColors.pink),
          _buildMethod(m['patch'] ?? {'name': 'Contraceptive Patch', 'effectiveness': '91%', 'description': 'A small patch worn on the skin that releases hormones. Changed weekly.', 'pros': ['Easy to use', 'Only needs to be changed once a week'], 'cons': ['Visible on skin', 'Does not protect against STIs'], 'bestFor': 'Women who prefer a weekly routine.'}, '🩹', MaaColors.pink),
          _buildMethod(m['ring'] ?? {'name': 'Vaginal Ring', 'effectiveness': '91%', 'description': 'A flexible ring placed in the vagina that releases hormones.', 'pros': ['Only needs changing once a month'], 'cons': ['Requires insertion comfort'], 'bestFor': 'Women comfortable with vaginal insertion.'}, '⭕', MaaColors.pink),
          _buildMethod(m['injection'], '💉', MaaColors.pink),
        ],
      ),
      ContraceptionCategory(
        title: data['tabs'][1], // LARC
        icon: Icons.device_hub_rounded,
        color: MaaColors.softPurple,
        imageEmoji: '⭕',
        methods: [
          _buildMethod(m['implant'], '📍', MaaColors.softPurple),
          _buildMethod(m['iudHormonal'], '⭕', MaaColors.softPurple),
          _buildMethod(m['iudCopper'], '🔶', MaaColors.softPurple),
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
        title: data['tabs'][3], // Permanent
        icon: Icons.lock_outline_rounded,
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
  Widget build(BuildContext context) {
    final data = GuideLocalizations.getContraceptionData(context);
    final categories = _getCategories(data);
    
    // Resolve safety warnings translation
    final String langCode = Localizations.localeOf(context).languageCode;
    final Map<String, String> safetyTexts = _safetyGuideLocalizations[langCode] ?? _safetyGuideLocalizations['en']!;

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: Text(
          'Contraception & Planning',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MaaColors.pink,
          indicatorWeight: 3,
          labelColor: MaaColors.pink,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: safetyTexts['tabGuidelines']),
            Tab(text: safetyTexts['tabDirectory']),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: WHO Guidelines & Warnings
          _buildGuidelinesTab(safetyTexts),
          
          // TAB 2: Methods Directory
          _buildMethodsTab(categories, data),
        ],
      ),
    );
  }

  Widget _buildGuidelinesTab(Map<String, String> safetyTexts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Critical Warning Card (Red gradient / Glassmorphic)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.error.withValues(alpha: 0.2),
                  MaaColors.errorGlow.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.error.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: MaaColors.error.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: MaaColors.error, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            safetyTexts['warningTitle'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: MaaColors.error,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            safetyTexts['warningSub'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  safetyTexts['warningDesc'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.87),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // Safe Sex & Dual Protection Card (Purple/Gold)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MaaColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.softPurple.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: MaaColors.pink, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        safetyTexts['safeSexTitle'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  safetyTexts['safeSexDesc'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // WHO Core Guidelines Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MaaColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.public_rounded, color: MaaColors.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        safetyTexts['whoTitle'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  safetyTexts['whoDesc'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMethodsTab(List<ContraceptionCategory> categories, Map<String, dynamic> data) {
    final activeCategory = categories[_selectedCategoryIndex];

    return Column(
      children: [
        // Category Filter Chips Row
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategoryIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    children: [
                      Text(cat.imageEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(cat.title),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  selectedColor: cat.color.withValues(alpha: 0.2),
                  checkmarkColor: cat.color,
                  labelStyle: GoogleFonts.poppins(
                    color: isSelected ? cat.color : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.03),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? cat.color.withValues(alpha: 0.5) : Colors.white12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Methods List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            itemCount: activeCategory.methods.length,
            itemBuilder: (context, index) {
              final method = activeCategory.methods[index];
              return _buildMethodCard(method, index, data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard(ContraceptionMethod method, int index, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: method.color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: method.color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  method.color.withValues(alpha: 0.15),
                  method.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    method.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: method.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${data['methodLabels']['effectiveness'] ?? 'Effectiveness'}: ${method.effectiveness}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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
          
          // Card Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pros & Cons
                _buildProsConsSection(
                  data['methodLabels']['pros'] ?? 'Advantages',
                  method.pros,
                  Icons.check_circle_rounded,
                  MaaColors.success,
                ),
                const SizedBox(height: 12),
                _buildProsConsSection(
                  data['methodLabels']['cons'] ?? 'Things to Consider',
                  method.cons,
                  Icons.cancel_rounded,
                  MaaColors.warning,
                ),
                const SizedBox(height: 16),

                // Best For
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: method.color.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.star_rounded, color: method.color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['methodLabels']['bestFor'] ?? 'Best For:',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: method.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method.bestFor,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
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
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.05, end: 0);
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
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
//  Data Models (aligned with contraception_guide_screen.dart)
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

ContraceptionMethod _buildMethod(Map<String, dynamic> methodData, String emoji, Color color) {
  return ContraceptionMethod(
    name: methodData['name'] ?? '',
    emoji: emoji,
    effectiveness: methodData['effectiveness'] ?? '',
    description: methodData['description'] ?? '',
    color: color,
    pros: List<String>.from(methodData['pros'] ?? []),
    cons: List<String>.from(methodData['cons'] ?? []),
    bestFor: methodData['bestFor'] ?? '',
  );
}

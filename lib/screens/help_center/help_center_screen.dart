// ============================================================
//  HelpCenterScreen – MaaCare
//  Searchable FAQ and Support Contact Dashboard
//  Fully localized and matching dark glassmorphism design
// ============================================================

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<int> _expandedIndexes = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Define static/final FAQ items linking to l10n dynamic translation properties
  List<_FAQItem> _buildFAQs(AppLocalizations l10n) {
    return [
      _FAQItem(
        category: 'AI Chat',
        question: l10n.faqQ1,
        answer: l10n.faqA1,
        icon: '💬',
        color: const Color(0xFFFF69B4),
      ),
      _FAQItem(
        category: 'Privacy',
        question: l10n.faqQ2,
        answer: l10n.faqA2,
        icon: '🛡️',
        color: const Color(0xFF4CAF50),
      ),
      _FAQItem(
        category: 'Pregnancy',
        question: l10n.faqQ3,
        answer: l10n.faqA3,
        icon: '👶',
        color: const Color(0xFF2196F3),
      ),
      _FAQItem(
        category: 'Pregnancy',
        question: l10n.faqQ4,
        answer: l10n.faqA4,
        icon: '💎',
        color: const Color(0xFFFFD700),
      ),
      _FAQItem(
        category: 'Payments',
        question: l10n.faqQ5,
        answer: l10n.faqA5,
        icon: '💳',
        color: const Color(0xFFFF9800),
      ),
      _FAQItem(
        category: 'Cycle & PCOS',
        question: l10n.faqQ6,
        answer: l10n.faqA6,
        icon: '🌸',
        color: const Color(0xFF9D4EDD),
      ),
      _FAQItem(
        category: 'Pregnancy',
        question: l10n.faqQ7,
        answer: l10n.faqA7,
        icon: '🩺',
        color: const Color(0xFF00BCD4),
      ),
      _FAQItem(
        category: 'Privacy',
        question: l10n.faqQ8,
        answer: l10n.faqA8,
        icon: '🗑️',
        color: const Color(0xFFEF5350),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Filter list based on category and search query
    final faqs = _buildFAQs(l10n).where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq.category == _selectedCategory;
      final matchesSearch = faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Map user categories to localizations
    final categoriesMap = {
      'All': l10n.helpCategoryAll,
      'AI Chat': l10n.helpCategoryAi,
      'Pregnancy': l10n.helpCategoryPregnancy,
      'Cycle & PCOS': l10n.helpCategoryCycle,
      'Privacy': l10n.helpCategoryPrivacy,
      'Payments': l10n.helpCategoryPayments,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpCenter),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── Background Glowing Blobs ──
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MaaColors.pink.withValues(alpha: 0.08),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms),
          Positioned(
            bottom: 120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MaaColors.softPurple.withValues(alpha: 0.07),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms),

          // ── Content ──
          Column(
            children: [
              // ── Search & Filter Panel ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    // Glassmorphic Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: l10n.helpSearchHint,
                              hintStyle: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: MaaColors.pink),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Category Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: categoriesMap.entries.map((entry) {
                          final isSelected = _selectedCategory == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                entry.value,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = entry.key;
                                    _expandedIndexes.clear();
                                  });
                                }
                              },
                              selectedColor: MaaColors.pink.withValues(alpha: 0.3),
                              backgroundColor: Colors.white.withValues(alpha: 0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? MaaColors.pink : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── FAQ Accordion List ────────────────────────────────────
              Expanded(
                child: faqs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              l10n.helpNoResults,
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: faqs.length,
                        itemBuilder: (ctx, i) {
                          final faq = faqs[i];
                          final isExpanded = _expandedIndexes.contains(i);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isExpanded ? 0.07 : 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isExpanded ? faq.color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isExpanded ? faq.color.withValues(alpha: 0.12) : Colors.transparent,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () => setState(() {
                                        if (isExpanded) {
                                          _expandedIndexes.remove(i);
                                        } else {
                                          _expandedIndexes.add(i);
                                        }
                                      }),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: faq.color.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(faq.icon, style: const TextStyle(fontSize: 18)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                faq.question,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            AnimatedRotation(
                                              turns: isExpanded ? 0.5 : 0,
                                              duration: const Duration(milliseconds: 200),
                                              child: Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                color: faq.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AnimatedCrossFade(
                                      duration: const Duration(milliseconds: 250),
                                      crossFadeState: isExpanded
                                          ? CrossFadeState.showFirst
                                          : CrossFadeState.showSecond,
                                      firstChild: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Divider(height: 1, color: faq.color.withValues(alpha: 0.3)),
                                            const SizedBox(height: 12),
                                            Text(
                                              faq.answer,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                height: 1.6,
                                                color: Colors.white.withValues(alpha: 0.85),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      secondChild: const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 40 * i)).slideX(begin: -0.04);
                        },
                      ),
              ),

              // ── Support Footer & Contact Actions ───────────────────────
              _buildSupportFooter(l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportFooter(AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.helpStillQuestions,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Quick Support Buttons Grid
              Row(
                children: [
                  Expanded(
                    child: _supportCard(
                      title: l10n.helpAskMaaAi,
                      emoji: '💬',
                      gradient: const LinearGradient(
                        colors: [MaaColors.pink, MaaColors.pinkDark],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _supportCard(
                      title: l10n.helpAskSakhiAi,
                      emoji: '🌸',
                      gradient: const LinearGradient(
                        colors: [MaaColors.softPurple, Colors.indigo],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/sakhi_ai'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MaaButton(
                label: l10n.helpContactEmail,
                outlined: true,
                onPressed: () => _showEmailDialog(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _supportCard({
    required String title,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required String emoji,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withValues(alpha: 0.18),
                  gradient.colors.last.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gradient.colors.first.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmailDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        title: Row(
          children: [
            const Text('📧 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                l10n.helpEmailSupportTitle,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.helpEmailSupportDesc,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: MaaColors.pink, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      'maacareapp@gmail.com',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.helpEmailResponseTime,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              l10n.helpClose,
              style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  final String category;
  final String question;
  final String answer;
  final String icon;
  final Color color;

  const _FAQItem({
    required this.category,
    required this.question,
    required this.answer,
    required this.icon,
    required this.color,
  });
}

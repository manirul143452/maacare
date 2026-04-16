// ============================================================
//  PrivacyPolicyScreen – MaaCare
//  Comprehensive DPDP/GDPR-compliant privacy policy
//  Multilingual + Beautiful accordion design
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final bool showAcceptButton;
  final VoidCallback? onAccept;

  const PrivacyPolicyScreen({
    super.key,
    this.showAcceptButton = false,
    this.onAccept,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final Set<int> _expanded = {0}; // First section open by default

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final sections = _buildSections(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Hero Banner ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MaaColors.pink, MaaColors.pinkDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: MaaColors.pink.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🔐', style: TextStyle(fontSize: 48)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.privacyHero,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.privacyIntro,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withAlpha(200),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                const SizedBox(height: 20),

                // ── Compliance Badges ─────────────────────────
                Row(
                  children: [
                    _complianceBadge('🇮🇳 DPDP Act', Colors.orange),
                    const SizedBox(width: 10),
                    _complianceBadge('🇪🇺 GDPR', Colors.blue),
                    const SizedBox(width: 10),
                    _complianceBadge('🔒 AES-256', Colors.green),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),

                // ── Accordion Sections ─────────────────────────
                ...List.generate(sections.length, (i) {
                  final section = sections[i];
                  final isExpanded = _expanded.contains(i);
                  return _PolicySection(
                    index: i,
                    title: section['title']!,
                    body: section['body']!,
                    icon: section['icon']!,
                    color: section['color'] as Color,
                    isExpanded: isExpanded,
                    onToggle: () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(i);
                      } else {
                        _expanded.add(i);
                      }
                    }),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideX(begin: -0.1);
                }),

                const SizedBox(height: 24),

                // ── Footer ─────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        '📅 Last Updated: April 13, 2025',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MaaCare Health Technologies Pvt. Ltd.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Accept Button ─────────────────────────────────
          if (widget.showAcceptButton)
            Padding(
              padding: const EdgeInsets.all(20),
              child: MaaButton(
                label: l10n.agreeAndContinue,
                onPressed: widget.onAccept,
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildSections(AppLocalizations l10n) {
    return [
      {
        'title': l10n.privacySection1Title,
        'body': l10n.privacySection1Body,
        'icon': '📋',
        'color': const Color(0xFFFF69B4),
      },
      {
        'title': l10n.privacySection2Title,
        'body': l10n.privacySection2Body,
        'icon': '🎯',
        'color': const Color(0xFF9D4EDD),
      },
      {
        'title': l10n.privacySection3Title,
        'body': l10n.privacySection3Body,
        'icon': '🔒',
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': l10n.privacySection4Title,
        'body': l10n.privacySection4Body,
        'icon': '🤝',
        'color': const Color(0xFF2196F3),
      },
      {
        'title': l10n.privacySection5Title,
        'body': l10n.privacySection5Body,
        'icon': '⚖️',
        'color': const Color(0xFFFF9800),
      },
      {
        'title': l10n.privacySection6Title,
        'body': l10n.privacySection6Body,
        'icon': '👶',
        'color': const Color(0xFFE91E8C),
      },
      {
        'title': l10n.privacySection7Title,
        'body': l10n.privacySection7Body,
        'icon': '📬',
        'color': const Color(0xFF00BCD4),
      },
    ];
  }

  Widget _complianceBadge(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Policy Accordion Section ──────────────────────────────────
class _PolicySection extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  final String icon;
  final Color color;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _PolicySection({
    required this.index,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? color.withAlpha(150) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? color.withAlpha(40) : Colors.black.withAlpha(15),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(height: 1, color: color.withAlpha(80)),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.7,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  LanguageSwitcherWidget – MaaCare
//  Beautiful bottom-sheet language picker with flags + animations
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../app_theme.dart';
import '../providers/locale_provider.dart';

/// Compact pill button – tap to open full sheet
class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().currentLanguage;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MaaColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              lang.nativeName,
              style: GoogleFonts.poppins(
                color: MaaColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: MaaColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  static void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LanguageSheet(),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    const langs = LocaleProvider.supportedLanguages;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MaaColors.textMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Icon(Icons.language_rounded, color: MaaColors.pink),
                  const SizedBox(width: 10),
                  Text(
                    l10n.chooseLanguage,
                    style: GoogleFonts.poppins(
                      color: MaaColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'अपनी भाषा चुनें • আপোনাৰ ভাষা বাছনি • আপনার ভাষা বেছে নিন',
                style: GoogleFonts.poppins(
                  color: MaaColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),

              // Language grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: langs.length,
                itemBuilder: (_, i) {
                  final lang = langs[i];
                  final isSelected = provider.locale.languageCode == lang.code;
                  return GestureDetector(
                    onTap: () async {
                      await provider.setLocaleByCode(lang.code);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isSelected ? MaaColors.primaryGradient : null,
                        color: isSelected ? null : MaaColors.cardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : MaaColors.glassBorder,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: MaaColors.pink.withAlpha(60),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(lang.flag,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 12),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.nativeName,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  : MaaColors.textPrimary,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 30).ms),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Menstrual Medical Theme – MaaCare
//  Premium design system for Unmarried Girl view layers
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';

class MenstrualMedicalTheme {
  MenstrualMedicalTheme._();

  // Color Tokens
  static const Color obsidianBlack = Color(0xFF12121A);
  static const Color electricOrchid = Color(0xFFFF2E93);
  static const Color darkSlate = Color(0xFF1A1A24);

  // Clinical Triage Colors
  static const Color greenZoneMint = Color(0xFF00E676);
  static const Color yellowZoneAmber = Color(0xFFFFD600);
  static const Color redZoneCrimson = Color(0xFFFF1744);

  // ThemeData override block for Unmarried Girl module
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianBlack,
      primaryColor: electricOrchid,
      cardColor: darkSlate,
      colorScheme: const ColorScheme.dark(
        primary: electricOrchid,
        surface: darkSlate,
        error: redZoneCrimson,
      ),
    );
  }
}

// Frosted Glass container card
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor ?? MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================
//  MaaCare – Premium Dark Theme
//  Dark, mysterious, psychologically attractive design
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MaaColors {
  MaaColors._();

  // ── Dark Base Colors ──
  static const Color background = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF1E1E2E);
  static const Color cardLight = Color(0xFF252538);

  // ── Accent Colors ──
  static const Color pink = Color(0xFFFF69B4);
  static const Color pinkGlow = Color(0xFFFF69B4);
  static const Color pinkDark = Color(0xFFE91E8C);
  static const Color deepPink = Color(0xFFD81B60);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFB347);

  // ── Supporting Colors ──
  static const Color peach = Color(0xFFFFDAB9);
  static const Color lightBlue = Color(0xFFA7D8DE);
  static const Color softPurple = Color(0xFF9D4EDD);
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFFF9FB);

  // ── Text Colors ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6B6B80);
  static const Color textDark = Color(0xFF3D1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);

  // ── Status Colors ──
  static const Color success = Color(0xFF4CAF50);
  static const Color successGlow = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color errorGlow = Color(0xFFFF5252);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pink, softPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, surfaceDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardDark, cardLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGlowGradient = LinearGradient(
    colors: [pink, pinkDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glassmorphism ──
  static Color glassBackground = white.withAlpha(15);
  static Color glassBorder = white.withAlpha(30);
  static Color glassHighlight = white.withAlpha(10);

  // ── Shadows & Glows ──
  static Color pinkShadow = pink.withAlpha(80);
  static Color goldShadow = gold.withAlpha(60);
  static Color purpleShadow = softPurple.withAlpha(60);
  static Color darkShadow = Colors.black.withAlpha(80);
  static Color cardShadow = Colors.black.withAlpha(40);
}

class MaaTheme {
  MaaTheme._();

  // ── DARK THEME (existing) ───────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MaaColors.pink,
        brightness: Brightness.dark,
        primary: MaaColors.pink,
        secondary: MaaColors.softPurple,
        surface: MaaColors.cardDark,
        error: MaaColors.error,
      ),
      scaffoldBackgroundColor: MaaColors.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: MaaColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: MaaColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: MaaColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MaaColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: MaaColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: MaaColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: MaaColors.textSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: MaaColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MaaColors.pink,
          foregroundColor: MaaColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          shadowColor: MaaColors.pinkShadow,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MaaColors.pink,
          side: const BorderSide(color: MaaColors.pink, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MaaColors.cardDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MaaColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: MaaColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MaaColors.pink, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: MaaColors.textMuted,
        ),
      ),
      cardTheme: CardTheme(
        color: MaaColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: MaaColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MaaColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: MaaColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MaaColors.cardDark,
        selectedItemColor: MaaColors.pink,
        unselectedItemColor: MaaColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MaaColors.cardLight,
        contentTextStyle: GoogleFonts.poppins(
          color: MaaColors.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  // ── LIGHT THEME ─────────────────────────────────
  static ThemeData get lightTheme {
    const lightBg = Color(0xFFFFF8FB);
    const lightSurface = Color(0xFFFFEEF5);
    const lightCard = Color(0xFFFFFFFF);
    const lightBorder = Color(0xFFFFD6E8);
    const textDark = Color(0xFF2D1B2E);
    const textMedium = Color(0xFF7A4060);
    const textLight = Color(0xFFB07090);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MaaColors.pink,
        brightness: Brightness.light,
        primary: MaaColors.pink,
        secondary: MaaColors.softPurple,
        surface: lightCard,
        error: MaaColors.error,
      ),
      scaffoldBackgroundColor: lightBg,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: textDark),
        displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: textDark),
        headlineLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: textDark),
        headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, color: textDark),
        bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: textMedium),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: MaaColors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MaaColors.pink,
          foregroundColor: MaaColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 2,
          shadowColor: MaaColors.pinkShadow,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MaaColors.deepPink,
          side: const BorderSide(color: MaaColors.deepPink, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: lightBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: lightBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: MaaColors.pink, width: 1.5)),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: textLight),
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 2,
        shadowColor: MaaColors.pinkShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        iconTheme: const IconThemeData(color: MaaColors.deepPink),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: MaaColors.deepPink,
        unselectedItemColor: textLight,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MaaColors.deepPink,
        contentTextStyle: GoogleFonts.poppins(color: MaaColors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? MaaColors.pink : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? MaaColors.pink.withAlpha(80) : Colors.grey.withAlpha(60)),
      ),
    );
  }

  // ── PINK THEME (bubblegum vibrant) ──────────────
  static ThemeData get pinkTheme {
    const pinkBg = Color(0xFFFF4D9E);       // hot pink background
    const pinkSurface = Color(0xFFFF69B4);  // medium pink
    const pinkCard = Color(0xFFFFB6D9);     // light pink card
    const pinkDeep = Color(0xFFD81B60);     // deep accent
    const textOnPink = Color(0xFFFFFFFF);
    const textSoft = Color(0xFFFFEEF5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFFF4D9E),
        onPrimary: Colors.white,
        secondary: Color(0xFFFF69B4),
        onSecondary: Colors.white,
        error: Color(0xFFEF5350),
        onError: Colors.white,
        surface: Color(0xFFD81B60),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: pinkBg,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: textOnPink),
        displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: textOnPink),
        headlineLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: textOnPink),
        headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textOnPink),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textOnPink),
        bodyLarge: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, color: textSoft),
        bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: textSoft),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textOnPink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pinkDeep,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
          shadowColor: Colors.black38,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pinkSurface.withAlpha(120),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white38)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white38)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 2)),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
      ),
      cardTheme: CardTheme(
        color: pinkCard.withAlpha(200),
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pinkDeep,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pinkDeep,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: pinkDeep,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: pinkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: pinkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white60),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white38 : Colors.white24),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: textOnPink,
        iconColor: Colors.white70,
      ),
      dividerColor: Colors.white24,
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }

  // Helper: get ThemeData by MaaThemeMode string
  static ThemeData themeFor(String mode) {
    switch (mode) {
      case 'light':
        return lightTheme;
      case 'pink':
        return pinkTheme;
      default:
        return darkTheme;
    }
  }
}

// ── Glassmorphism Container ──
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.borderColor,
    this.backgroundColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? MaaColors.glassBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? MaaColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: MaaColors.darkShadow,
            blurRadius: blur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Neon Glow Button ──
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;
  final bool outlined;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 4, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? MaaColors.pink;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: widget.outlined
                    ? null
                    : LinearGradient(
                        colors: [buttonColor, buttonColor.withAlpha(200)],
                      ),
                color: widget.outlined ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(30),
                border: widget.outlined
                    ? Border.all(color: buttonColor, width: 2)
                    : null,
                boxShadow: widget.outlined
                    ? null
                    : [
                        BoxShadow(
                          color: buttonColor.withAlpha(120),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: buttonColor.withAlpha(60),
                          blurRadius: _glowAnimation.value * 2,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.outlined ? buttonColor : MaaColors.white,
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: MaaColors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.outlined ? buttonColor : MaaColors.white,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Animated Heart Button ──
class AnimatedHeart extends StatefulWidget {
  final bool isLiked;
  final int likes;
  final VoidCallback onTap;

  const AnimatedHeart({
    super.key,
    required this.isLiked,
    required this.likes,
    required this.onTap,
  });

  @override
  State<AnimatedHeart> createState() => _AnimatedHeartState();
}

class _AnimatedHeartState extends State<AnimatedHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isLiked
                    ? MaaColors.pink.withAlpha(30)
                    : MaaColors.cardLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isLiked
                      ? MaaColors.pink.withAlpha(100)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.isLiked ? '❤️' : '🤍',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.likes}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isLiked
                          ? MaaColors.pink
                          : MaaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Mood Selector Widget ──
class MoodSelector extends StatefulWidget {
  final String? selectedMood;
  final Function(String) onSelect;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onSelect,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector>
    with TickerProviderStateMixin {
  final List<_MoodItem> _moods = const [
    _MoodItem('😊', 'Happy', MaaColors.gold),
    _MoodItem('😌', 'Calm', MaaColors.softGreen),
    _MoodItem('😔', 'Sad', MaaColors.softPurple),
    _MoodItem('😰', 'Anxious', MaaColors.warning),
    _MoodItem('😴', 'Tired', MaaColors.lightBlue),
    _MoodItem('🤰', 'Grateful', MaaColors.pink),
  ];

  int? _hoveredIndex;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_moods.length, (index) {
            final mood = _moods[index];
            final isSelected = widget.selectedMood == mood.emoji;

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: GestureDetector(
                onTap: () => widget.onSelect(mood.emoji),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..scale(isSelected
                            ? _pulseAnimation.value
                            : (_hoveredIndex == index ? 1.1 : 1.0)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? mood.color.withAlpha(40)
                            : MaaColors.cardLight,
                        border: Border.all(
                          color: isSelected ? mood.color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: mood.color.withAlpha(80),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        mood.emoji,
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
        if (widget.selectedMood != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: MaaColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getMoodMessage(widget.selectedMood!),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: MaaColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn().scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOutBack,
              ),
        ],
      ],
    );
  }

  String _getMoodMessage(String mood) {
    switch (mood) {
      case '😊':
        return 'Your joy is contagious! ✨';
      case '😌':
        return 'Peace looks beautiful on you 🌸';
      case '😔':
        return 'It\'s okay to feel this way. We\'re here 💕';
      case '😰':
        return 'Take a deep breath. You\'re safe here 🤗';
      case '😴':
        return 'Rest is productive too! 💤';
      case '🤰':
        return 'Your gratitude warms our hearts 💖';
      default:
        return 'Thanks for sharing! 💕';
    }
  }
}

class _MoodItem {
  final String emoji;
  final String label;
  final Color color;
  const _MoodItem(this.emoji, this.label, this.color);
}

// ── Particle Background ──
class ParticleBackground extends StatelessWidget {
  final Widget child;
  final int particleCount;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: MaaColors.darkGradient,
          ),
        ),
        // Particles
        ...List.generate(particleCount, (index) {
          final random = index * 37 % 100;
          final size = 2.0 + (index % 4);
          final opacity = 0.1 + (index % 5) * 0.05;

          return Positioned(
            left: (random * 3.6) % MediaQuery.of(context).size.width,
            top: (random * 5.2) % MediaQuery.of(context).size.height,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index % 3 == 0
                    ? MaaColors.pink.withAlpha((opacity * 255).round())
                    : index % 3 == 1
                        ? MaaColors.gold.withAlpha((opacity * 255).round())
                        : MaaColors.softPurple
                            .withAlpha((opacity * 255).round()),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveY(
                  begin: 0,
                  end: -30,
                  duration: Duration(seconds: 3 + (index % 4)),
                  curve: Curves.easeInOut,
                ),
          );
        }),
        child,
      ],
    );
  }
}

// ── Social Proof Badge ──
class SocialProofBadge extends StatelessWidget {
  final String count;
  final String label;

  const SocialProofBadge({
    super.key,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: MaaColors.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MaaColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: MaaColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MaaColors.success.withAlpha(150),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 1000.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 10),
          Text(
            '$count $label',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MaaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Curiosity Teaser ──
class CuriosityTeaser extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const CuriosityTeaser({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MaaColors.pink.withAlpha(20),
              MaaColors.softPurple.withAlpha(20),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MaaColors.pink.withAlpha(50),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🔮',
              style: TextStyle(fontSize: 18),
            ).animate(onPlay: (c) => c.repeat()).shimmer(
                  duration: 2000.ms,
                  color: MaaColors.pink.withAlpha(100),
                ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: MaaColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: MaaColors.pink.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Extension for Animate ──
extension AnimateExtension on Widget {
  Widget get animateFade =>
      animate().fadeIn(duration: 300.ms).moveY(begin: 20, end: 0);
}

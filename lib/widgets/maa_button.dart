// ============================================================
//  Custom Widgets – MaaCare
//  MaaButton, MaaCard, MoodSelector, BottomNav
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';

// ─────────────────── MaaButton ───────────────────

class MaaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;
  final double? width;
  final Color? color;

  const MaaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color ?? MaaColors.pink, width: 1.5),
                foregroundColor: color ?? MaaColors.pink,
              ),
              onPressed: isLoading ? null : onPressed,
              icon: icon != null
                  ? Icon(icon, size: 20)
                  : const SizedBox.shrink(),
              label: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color ?? MaaColors.deepPink),
                    )
                  : Text(label),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: outlined ? null : color,
                gradient: color != null 
                    ? null 
                    : (onPressed == null || isLoading
                        ? const LinearGradient(colors: [MaaColors.pink, MaaColors.pink])
                        : MaaColors.primaryGradient),
                borderRadius: BorderRadius.circular(30),
                boxShadow: onPressed != null && !isLoading
                    ? [
                        BoxShadow(
                          color: (color ?? MaaColors.deepPink).withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: Size(width ?? double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isLoading ? null : onPressed,
                icon: icon != null
                    ? Icon(icon, size: 20, color: MaaColors.white)
                    : const SizedBox.shrink(),
                label: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: MaaColors.white),
                      )
                    : Text(label,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MaaColors.white)),
              ),
            ),
    );
  }
}

// ─────────────────── MaaCard ───────────────────

class MaaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;

  const MaaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? MaaColors.white) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MaaColors.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────── MoodSelector ───────────────────

class MoodSelector extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onSelect;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onSelect,
  });

  static const List<Map<String, String>> moods = [
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😔', 'label': 'Low'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😄', 'label': 'Great'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.asMap().entries.map((entry) {
        final idx = entry.key;
        final mood = entry.value;
        final isSelected = selectedMood == mood['emoji'];
        return GestureDetector(
          onTap: () => onSelect(mood['emoji']!),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MaaColors.deepPink.withAlpha(40)
                      : MaaColors.offWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? MaaColors.deepPink : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: MaaColors.deepPink.withAlpha(30), blurRadius: 10)
                  ] : [],
                ),
                child: Text(
                  mood['emoji']!,
                  style: const TextStyle(fontSize: 32),
                ),
              )
                  .animate(target: isSelected ? 1 : 0)
                  .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), curve: Curves.elasticOut)
                  .shake(hz: 8),
              const SizedBox(height: 6),
              Text(
                mood['label']!,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? MaaColors.deepPink : MaaColors.textGrey,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ).animate(target: isSelected ? 1 : 0).fadeIn().scale(),
            ],
          ),
        ).animate().fadeIn(delay: (idx * 50).ms).moveY(begin: 10, end: 0);
      }).toList(),
    );
  }
}

// ============================================================
//  Custom Widgets – MaaCare
//  MaaButton, MaaCard, MoodSelector, BottomNav
// ============================================================

import 'package:flutter/material.dart';
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



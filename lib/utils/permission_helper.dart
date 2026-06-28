// ============================================================
//  PermissionHelper – MaaCare
//  Validates camera and microphone permissions before room joins.
//  Presents a custom glassmorphic bottom sheet if permissions
//  are missing or denied.
// ============================================================

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_theme.dart';

class PermissionHelper {
  /// Checks camera and microphone permissions.
  /// If not granted, shows a modern bottom sheet rationale.
  /// Returns `true` if permissions are active, `false` otherwise.
  static Future<bool> checkVideoPermissions(BuildContext context) async {
    final cameraGranted = await Permission.camera.isGranted;
    final micGranted = await Permission.microphone.isGranted;

    if (cameraGranted && micGranted) {
      return true;
    }

    if (!context.mounted) return false;

    // Show the custom rationale dialog bottom sheet
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF130829).withValues(alpha: 0.9), // Dark purple glass
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🚨', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Text(
                        'Permissions Required',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To launch or join video consultations, MaaCare requires hardware access to your camera and microphone.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: MaaColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Camera Item
                  _buildRequirementRow(
                    icon: Icons.videocam_rounded,
                    title: 'Camera Permission',
                    description: 'Used to display video stream to the consulting doctor.',
                    isGranted: cameraGranted,
                  ),
                  const SizedBox(height: 14),

                  // Microphone Item
                  _buildRequirementRow(
                    icon: Icons.mic_rounded,
                    title: 'Microphone Permission',
                    description: 'Used to send your voice/audio to the consulting doctor.',
                    isGranted: micGranted,
                  ),
                  const SizedBox(height: 28),

                  // CTA Button
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await openAppSettings();
                    },
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: MaaColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: MaaColors.pink.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Open App Settings',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        color: MaaColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return false;
  }

  static Widget _buildRequirementRow({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? MaaColors.success.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted ? MaaColors.success.withValues(alpha: 0.1) : MaaColors.pink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? MaaColors.success : MaaColors.pink,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: MaaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isGranted ? MaaColors.success : Colors.white24,
            size: 20,
          ),
        ],
      ),
    );
  }
}

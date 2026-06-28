// ============================================================
//  PermissionGateScreen – MaaCare
//  Shown after role selection to secure hardware permissions
//  sequentially before launching dashboard screens.
// ============================================================

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';

class PermissionGateScreen extends StatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  // Track permission status states for visual badges
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _microphoneStatus = PermissionStatus.denied;

  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialPermissions() async {
    final notification = await Permission.notification.status;
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _notificationStatus = notification;
        _cameraStatus = camera;
        _microphoneStatus = mic;
      });
    }
  }

  Future<void> _requestPermissionsSequentially() async {
    setState(() => _isRequesting = true);

    // 1. Notification Permission request
    if (!_notificationStatus.isGranted) {
      final status = await Permission.notification.request();
      if (mounted) setState(() => _notificationStatus = status);
      // Brief delay to prevent dialog overlapping UI stutters
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 2. Camera Permission request
    if (!_cameraStatus.isGranted) {
      final status = await Permission.camera.request();
      if (mounted) setState(() => _cameraStatus = status);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 3. Microphone Permission request
    if (!_microphoneStatus.isGranted) {
      final status = await Permission.microphone.request();
      if (mounted) setState(() => _microphoneStatus = status);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _isRequesting = false);
    _proceedToDashboard();
  }

  void _proceedToDashboard() {
    final targetRoute = ModalRoute.of(context)?.settings.arguments as String? ?? '/home';
    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: MaaColors.background,
        body: Stack(
          children: [
            // ── Animated gradient background ──────────────────────
            AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF130829),
                        const Color(0xFF23124D),
                        _bgController.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF070708),
                        const Color(0xFF130829),
                        _bgController.value,
                      )!,
                    ],
                  ),
                ),
              ),
            ),

            // ── Ambient Glow Blobs ────────────────────────────────
            Positioned(
              top: -60,
              left: -50,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      MaaColors.pink.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              right: -50,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      MaaColors.softPurple.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Content Layout ────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildPermissionCard(
                              title: 'System Notifications',
                              subtitle: 'Cycle updates, nutrition reminders, and incoming consultation rings.',
                              icon: Icons.notifications_active_rounded,
                              status: _notificationStatus,
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionCard(
                              title: 'Camera Access',
                              subtitle: 'Exclusively to connect with verified gynecologists on 100ms video rooms.',
                              icon: Icons.videocam_rounded,
                              status: _cameraStatus,
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionCard(
                              title: 'Microphone Audio',
                              subtitle: 'To speak with your health advisor during active virtual consultations.',
                              icon: Icons.mic_rounded,
                              status: _microphoneStatus,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(
            Icons.security_rounded,
            color: MaaColors.pink,
            size: 40,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 18),
        Text(
          'Hardware Permissions',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 100.ms).moveY(begin: 12, end: 0),
        const SizedBox(height: 8),
        Text(
          'Allow MaaCare access to provide secure telehealth services, notifications, and interactive updates.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: MaaColors.textSecondary,
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required PermissionStatus status,
  }) {
    final isGranted = status.isGranted;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isGranted
                  ? MaaColors.success.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGranted
                      ? MaaColors.success.withValues(alpha: 0.1)
                      : MaaColors.pink.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isGranted ? MaaColors.success : MaaColors.pink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MaaColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusIndicator(status),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildStatusIndicator(PermissionStatus status) {
    if (status.isGranted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: MaaColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Active',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: MaaColors.success,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Pending',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: MaaColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isRequesting ? null : _requestPermissionsSequentially,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: MaaColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: MaaColors.pink.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isRequesting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Grant Permissions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _proceedToDashboard,
          child: Text(
            'Skip for Now',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: MaaColors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

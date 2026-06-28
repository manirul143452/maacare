// ============================================================
//  RoleSelectionScreen – Step 2 Onboarding Sequence
//  Premium Glassmorphic 3-Tier Selector
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show ImageFilter;

import '../../app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRole = 'mother'; // default select mother
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selectedRole == 'doctor') {
      Navigator.pushNamed(context, '/doctor-onboarding');
    } else if (_selectedRole == 'unmarried_girl') {
      Navigator.pushNamed(context, '/menstrual-config');
    } else if (_selectedRole == 'mother') {
      Navigator.pushNamed(context, '/maternal-config');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: MaaColors.background,
        body: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF120824),
                        const Color(0xFF261245),
                        _bgController.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF07040D),
                        const Color(0xFF120824),
                        _bgController.value,
                      )!,
                    ],
                  ),
                ),
              ),
            ),

            // Ambient Glow Blobs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFFFF2E93).withValues(alpha: 0.15),
                    Colors.transparent,
                  ]),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: 30,
                  duration: 4.seconds,
                  curve: Curves.easeInOut,
                ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 40),

                    // Role Cards Stack
                    _buildRoleCard(
                      title: 'Doctor Portal Entry',
                      subtitle: 'Targets healthcare professionals, obstetricians & gynecologists.',
                      icon: Icons.local_hospital_rounded,
                      role: 'doctor',
                    ),
                    _buildRoleCard(
                      title: 'Gynocare & Period Support',
                      subtitle: 'Tailored for unmarried girls tracking cycle regularity & menstrual symptoms.',
                      icon: Icons.spa_rounded,
                      role: 'unmarried_girl',
                    ),
                    _buildRoleCard(
                      title: 'Maternal Journey Track',
                      subtitle: 'Tailored for pregnant and postpartum mothers monitoring gestational timelines.',
                      icon: Icons.pregnant_woman_rounded,
                      role: 'mother',
                    ),

                    const SizedBox(height: 32),
                    _buildConfirmButton(),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: MaaColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF2E93).withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text('🌸', style: TextStyle(fontSize: 36)),
          ),
        ).animate().scale(
              duration: 800.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 20),
        Text(
          'Select Your Purpose',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(
                color: const Color(0xFFFF2E93).withValues(alpha: 0.5),
                blurRadius: 16,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
        const SizedBox(height: 10),
        Text(
          'Choose your role so we can personalize\nyour MaaCare experience.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.white60,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String role,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF2E93).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF2E93)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF2E93).withValues(alpha: 0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF2E93).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? const Color(0xFFFF2E93) : Colors.white70,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFFFF2E93), size: 24)
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _confirm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFF2E93),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2E93).withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Continue',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).moveY(begin: 20, end: 0);
  }
}

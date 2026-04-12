// ============================================================
//  ProfileScreen – MaaCare Premium Dark
//  Dark hero header, golden stars, badges with confetti
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/community_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isEditingName = false;
  bool _isUploadingAvatar = false;
  late TextEditingController _nameController;
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 8, end: 15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final provider = context.read<UserProvider>();
    final user = provider.user;
    if (user == null) return;

    final updatedUser = user.copyWith(name: newName);
    await provider.createOrUpdateUser(updatedUser);

    setState(() => _isEditingName = false);
    _confettiController.play();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name updated! Looking good, Mama! 🌸'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MaaColors.cardLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (file == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (!mounted) return;
      final url = await context.read<CommunityProvider>().uploadMedia(
            fileName,
            bytes,
            bucket: 'community_media',
          );

      if (url != null && mounted) {
        final provider = context.read<UserProvider>();
        final user = provider.user;
        if (user != null) {
          final updatedUser = user.copyWith(avatarUrl: url);
          await provider.createOrUpdateUser(updatedUser);
          _confettiController.play();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Avatar updated! Beautiful! 💕'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: MaaColors.cardLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Try again! 😅'),
            backgroundColor: MaaColors.cardLight,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _editDueDate() async {
    final provider = context.read<UserProvider>();
    final user = provider.user;
    if (user == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: user.dueDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 280)),
      helpText: 'Update your due date 👶',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: MaaColors.pink,
                surface: MaaColors.cardDark,
              ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      final updatedUser = user.copyWith(dueDate: picked);
      await provider.createOrUpdateUser(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Due date updated! 📅💕'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MaaColors.cardLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      body: Stack(
        children: [
          // Particle background
          ...List.generate(20, (index) {
            final random = index * 37 % 100;
            final size = 1.5 + (index % 3);
            return Positioned(
              left: (random * 3.6) % MediaQuery.of(context).size.width,
              top: (random * 5.2) % MediaQuery.of(context).size.height,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index % 3 == 0
                      ? MaaColors.pink.withAlpha(25)
                      : index % 3 == 1
                          ? MaaColors.gold.withAlpha(20)
                          : MaaColors.softPurple.withAlpha(25),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).moveY(
                  begin: 0,
                  end: -25,
                  duration: Duration(seconds: 3 + (index % 4)),
                  curve: Curves.easeInOut,
                );
          }),

          Consumer<UserProvider>(
            builder: (ctx, provider, _) {
              final user = provider.user;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroHeader(user),
                    const SizedBox(height: 24),
                    _buildPointsSection(user),
                    const SizedBox(height: 24),
                    _buildInfoCard(user),
                    const SizedBox(height: 24),
                    _buildBadgesSection(user),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                MaaColors.pink,
                MaaColors.softPurple,
                MaaColors.gold,
              ],
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MaaColors.pink.withAlpha(30),
            MaaColors.softPurple.withAlpha(20),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Back button and title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MaaColors.glassBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MaaColors.glassBorder),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: MaaColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Your Profile',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.textPrimary,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 30),

          // Avatar with glow
          Stack(
            children: [
              // Outer glow
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MaaColors.pink.withAlpha(100),
                          blurRadius: _pulseAnimation.value,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Avatar container
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: MaaColors.primaryGradient,
                    border: Border.all(
                        color: MaaColors.white.withAlpha(50), width: 3),
                  ),
                  child: _isUploadingAvatar
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: MaaColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (_, __, ___) =>
                                    _buildInitial(user),
                              ),
                            )
                          : _buildInitial(user),
                ),
              ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),

              // Camera button
              Positioned(
                right: 5,
                bottom: 5,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: MaaColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MaaColors.pink.withAlpha(100),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: MaaColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          _isEditingName
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  width: 200,
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: MaaColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle:
                          GoogleFonts.poppins(color: MaaColors.textMuted),
                      filled: true,
                      fillColor: MaaColors.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_rounded,
                            color: MaaColors.pink),
                        onPressed: _saveName,
                      ),
                    ),
                    onSubmitted: (_) => _saveName(),
                  ),
                )
              : GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? 'Mama',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: MaaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: MaaColors.pink.withAlpha(150),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 8),

          // Badge title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: MaaColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: MaaColors.gold.withAlpha(60),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👑', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  user?.badgeTitle ?? '🌸 New Mom',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MaaColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(user) {
    return Center(
      child: Text(
        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
        style: const TextStyle(
          fontSize: 48,
          color: MaaColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPointsSection(user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MaaColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: MaaColors.darkShadow,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Points
          Expanded(
            child: _buildStatItem(
              '⭐',
              '${user?.points ?? 0}',
              'Points',
              MaaColors.gold,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: MaaColors.glassBorder,
          ),
          // Streak
          Expanded(
            child: _buildStatItem(
              '🔥',
              '${user?.streak ?? 0}',
              'Day Streak',
              MaaColors.warning,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: MaaColors.glassBorder,
          ),
          // Week
          Expanded(
            child: _buildStatItem(
              '👶',
              '${user?.pregnancyWeek ?? 0}',
              'Weeks',
              MaaColors.pink,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildStatItem(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MaaColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: MaaColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MaaColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: MaaColors.darkShadow,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTappableInfoRow(
            '👤',
            'Name',
            user?.name ?? 'Mama',
            () => setState(() => _isEditingName = true),
          ),
          _buildDivider(),
          _buildTappableInfoRow(
            '📅',
            'Due Date',
            user?.dueDate?.toString().split(' ')[0] ?? 'Not set',
            _editDueDate,
          ),
          _buildDivider(),
          _buildInfoRow('🏆', 'Badge', user?.badgeTitle ?? '🌸 New Mom'),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildTappableInfoRow(
      String emoji, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MaaColors.pink.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: MaaColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: MaaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_rounded,
              size: 14,
              color: MaaColors.pink.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MaaColors.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: MaaColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: MaaColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            MaaColors.glassBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(user) {
    final badges = [
      const _Badge('🌸', 'Day 1 Mama', true, MaaColors.pink),
      const _Badge('⭐', 'Mood Logger', true, MaaColors.gold),
      const _Badge('🍼', 'Water Pro', false, MaaColors.lightBlue),
      const _Badge('🧘', 'Zen Master', false, MaaColors.softPurple),
      const _Badge('💪', 'Streak Hero', false, MaaColors.success),
      const _Badge('👑', 'Super Mom', false, MaaColors.gold),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: MaaColors.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: MaaColors.gold.withAlpha(60),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Text(
                'Your Badges',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MaaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: badges.asMap().entries.map((entry) {
              final index = entry.key;
              final badge = entry.value;
              return _buildBadgeItem(badge, index);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0);
  }

  Widget _buildBadgeItem(_Badge badge, int index) {
    return GestureDetector(
      onTap: badge.unlocked
          ? () {
              _confettiController.play();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: badge.unlocked
              ? MaaColors.cardDark
              : MaaColors.cardDark.withAlpha(50),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.unlocked
                ? badge.color.withAlpha(50)
                : MaaColors.glassBorder.withAlpha(30),
          ),
          boxShadow: badge.unlocked
              ? [
                  BoxShadow(
                    color: badge.color.withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: badge.unlocked
                    ? badge.color.withAlpha(20)
                    : MaaColors.cardLight.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 24,
                    color: badge.unlocked ? null : MaaColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: badge.unlocked
                    ? MaaColors.textPrimary
                    : MaaColors.textMuted,
              ),
            ),
            if (!badge.unlocked)
              const Icon(
                Icons.lock_rounded,
                size: 12,
                color: MaaColors.textMuted,
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (500 + index * 50).ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildActionButton(
            'Sync Data 🔄',
            () async {
              await context.read<UserProvider>().loadUser();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Data synced! ✨'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: MaaColors.cardLight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            MaaColors.pink,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Settings ⚙️',
            () => Navigator.pushNamed(context, '/settings'),
            MaaColors.softPurple,
            outlined: true,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Help Center 🆘',
            () => Navigator.pushNamed(context, '/help'),
            MaaColors.lightBlue,
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color,
      {bool outlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: outlined
                ? null
                : LinearGradient(colors: [color, color.withAlpha(200)]),
            color: outlined ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(16),
            border: outlined
                ? Border.all(color: color.withAlpha(80), width: 1.5)
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: outlined ? color : MaaColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge {
  final String emoji;
  final String label;
  final bool unlocked;
  final Color color;
  const _Badge(this.emoji, this.label, this.unlocked, this.color);
}

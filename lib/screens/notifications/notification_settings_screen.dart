// ============================================================
//  Notification Settings – MaaCare Premium
//  User preferences for push notification categories
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/push_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  Map<NotificationCategory, bool> _settings = {};
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = PushNotificationService.instance.getAllCategorySettings();
    final hasPermission = await PushNotificationService.instance.hasPermission();

    setState(() {
      _settings = settings;
      _hasPermission = hasPermission;
      _isLoading = false;
    });
  }

  Future<void> _toggleCategory(NotificationCategory category, bool value) async {
    await PushNotificationService.instance.setCategoryEnabled(category, value);
    setState(() {
      _settings[category] = value;
    });

    // Show feedback
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? '${category.label} notifications enabled'
              : '${category.label} notifications disabled',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: value ? MaaColors.success : MaaColors.textSecondary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _requestPermission() async {
    final granted = await PushNotificationService.instance.requestPermission();
    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Notifications enabled! You\'ll now receive timely updates.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: MaaColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      if (!mounted) return;
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        title: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enable Notifications',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: MaaColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'To get the most out of MaaCare, please enable notifications in your device settings.\n\nYou\'ll receive:\n• Vaccination reminders\n• Daily nutrition tips\n• Pregnancy milestones\n• Community updates',
          style: GoogleFonts.poppins(
            color: MaaColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not Now',
              style: GoogleFonts.poppins(color: MaaColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              PushNotificationService.instance.openSettings();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableAll() async {
    for (final category in NotificationCategory.values) {
      await PushNotificationService.instance.setCategoryEnabled(category, true);
    }
    _loadSettings();
  }

  Future<void> _disableAll() async {
    for (final category in NotificationCategory.values) {
      await PushNotificationService.instance.setCategoryEnabled(category, false);
    }
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: MaaColors.cardDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Notification Settings',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: MaaColors.textPrimary,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MaaColors.pink.withAlpha(60),
                      MaaColors.softPurple.withAlpha(40),
                      MaaColors.cardDark,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              MaaColors.pink.withAlpha(150),
                              MaaColors.softPurple.withAlpha(100),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: MaaColors.pink.withAlpha(40),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🔔', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MaaColors.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: MaaColors.textPrimary, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Permission Banner
          if (!_hasPermission)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MaaColors.warning.withAlpha(40),
                        MaaColors.peach.withAlpha(25),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MaaColors.warning.withAlpha(50)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MaaColors.warning.withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.notifications_off_rounded,
                              color: MaaColors.warning,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications Disabled',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: MaaColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enable notifications to get timely reminders and updates',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: MaaColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _requestPermission,
                          icon: const Icon(Icons.notifications_active_rounded),
                          label: Text(
                            'Enable Notifications',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MaaColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ),
            ),

          // Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MaaColors.success.withAlpha(25),
                      MaaColors.softGreen.withAlpha(15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MaaColors.success.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose what matters to you. We respect your preferences and will only send notifications for categories you enable.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: MaaColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Actions
          if (!_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _enableAll,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(
                          'Enable All',
                          style: GoogleFonts.poppins(),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MaaColors.success,
                          side: BorderSide(color: MaaColors.success.withAlpha(50)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _disableAll,
                        icon: const Icon(Icons.block_rounded),
                        label: Text(
                          'Disable All',
                          style: GoogleFonts.poppins(),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MaaColors.textSecondary,
                          side: BorderSide(color: MaaColors.glassBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Settings List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = NotificationCategory.values[index];
                        final isEnabled = _settings[category] ?? true;
                        return _buildCategoryTile(category, isEnabled, index);
                      },
                      childCount: NotificationCategory.values.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(NotificationCategory category, bool isEnabled, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEnabled ? MaaColors.cardDark : MaaColors.cardDark.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? _getCategoryColor(category).withAlpha(40)
              : MaaColors.glassBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEnabled
                  ? [
                      _getCategoryColor(category).withAlpha(100),
                      _getCategoryColor(category).withAlpha(50),
                    ]
                  : [
                      MaaColors.textSecondary.withAlpha(30),
                      MaaColors.textSecondary.withAlpha(15),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            category.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          category.label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isEnabled ? MaaColors.textPrimary : MaaColors.textSecondary,
          ),
        ),
        subtitle: Text(
          _getCategoryDescription(category),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: MaaColors.textSecondary,
          ),
        ),
        trailing: Switch.adaptive(
          value: isEnabled,
          onChanged: (value) => _toggleCategory(category, value),
          activeColor: _getCategoryColor(category),
          activeTrackColor: _getCategoryColor(category).withAlpha(40),
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms);
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.vaccination:
        return MaaColors.pink;
      case NotificationCategory.nutrition:
        return MaaColors.success;
      case NotificationCategory.selfCare:
        return MaaColors.softPurple;
      case NotificationCategory.symptomCheck:
        return MaaColors.warning;
      case NotificationCategory.pregnancyMilestone:
        return MaaColors.lightBlue;
      case NotificationCategory.community:
        return MaaColors.softGreen;
      case NotificationCategory.healthNews:
        return MaaColors.peach;
      case NotificationCategory.trackerSync:
        return MaaColors.gold;
      case NotificationCategory.general:
        return MaaColors.textPrimary;
    }
  }

  String _getCategoryDescription(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.vaccination:
        return 'Reminders for your baby\'s vaccination schedule';
      case NotificationCategory.nutrition:
        return 'Daily personalized nutrition tips & meal ideas';
      case NotificationCategory.selfCare:
        return 'Self-care suggestions for your wellbeing';
      case NotificationCategory.symptomCheck:
        return 'Gentle reminders to log symptoms';
      case NotificationCategory.pregnancyMilestone:
        return 'Weekly pregnancy milestones & baby development';
      case NotificationCategory.community:
        return 'New posts and replies from Parents Park';
      case NotificationCategory.healthNews:
        return 'Latest health articles and expert advice';
      case NotificationCategory.trackerSync:
        return 'Reminders to update your pregnancy tracker';
      case NotificationCategory.general:
        return 'App updates and general announcements';
    }
  }
}

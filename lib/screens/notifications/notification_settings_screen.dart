// ============================================================
//  Notification Settings – MaaCare v2.0
//  Grouped categories • Quiet Hours • Frequency control
//  Full 14-category preference management
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/push_notification_service.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<NotificationCategory, bool> _settings = {};
  bool _hasPermission = false;
  late QuietHoursSettings _quietHours;
  String _frequency = 'smart';
  late TabController _tabController;

  // Category groups
  static const _groups = [
    'Baby & Pregnancy',
    'Health & Medical',
    'Wellness & Nutrition',
    'Community & Social',
    'System',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _groups.length, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = PushNotificationService.instance.getAllCategorySettings();
    final hasPermission =
        await PushNotificationService.instance.hasPermission();
    setState(() {
      _settings = settings;
      _hasPermission = hasPermission;
      _quietHours = PushNotificationService.instance.quietHours;
      _frequency = PushNotificationService.instance.notificationFrequency;
      _isLoading = false;
    });
  }

  Future<void> _toggleCategory(
      NotificationCategory category, bool value) async {
    await PushNotificationService.instance.setCategoryEnabled(category, value);
    setState(() => _settings[category] = value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? '${category.emoji} ${category.label} enabled'
              : '${category.emoji} ${category.label} disabled',
          style: GoogleFonts.poppins(fontSize: 13),
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
    setState(() => _hasPermission = granted);
    if (!mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Notifications enabled! You\'ll now receive timely updates.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: MaaColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
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
        ]),
        content: Text(
          'Notifications ke bina aap miss kar sakti hain:\n\n'
          '• Vaccination reminders 💉\n'
          '• Doctor appointment alerts 👩‍⚕️\n'
          '• Daily nutrition tips 🥗\n'
          '• Pregnancy milestones 🤰\n'
          '• Community updates 💬',
          style: GoogleFonts.poppins(
            color: MaaColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Baad Mein',
                style: GoogleFonts.poppins(color: MaaColors.textSecondary)),
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
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Settings Khole',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _setAllEnabled(bool enabled) async {
    for (final cat in NotificationCategory.values) {
      await PushNotificationService.instance.setCategoryEnabled(cat, enabled);
    }
    await _loadSettings();
  }

  Future<void> _updateQuietHours(bool enabled,
      {int? startHour, int? endHour}) async {
    final newQH = QuietHoursSettings(
      enabled: enabled,
      startHour: startHour ?? _quietHours.startHour,
      endHour: endHour ?? _quietHours.endHour,
    );
    await PushNotificationService.instance.setQuietHours(newQH);
    setState(() => _quietHours = newQH);
  }

  Future<void> _pickQuietHour(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isStart ? _quietHours.startHour : _quietHours.endHour,
        minute: 0,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MaaColors.pink,
            surface: MaaColors.cardDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (isStart) {
        await _updateQuietHours(_quietHours.enabled, startHour: picked.hour);
      } else {
        await _updateQuietHours(_quietHours.enabled, endHour: picked.hour);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: MaaColors.cardDark,
            title: Text(
              'Notification Settings',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: MaaColors.textPrimary,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: MaaColors.cardDark,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                  labelColor: MaaColors.pink,
                  unselectedLabelColor: MaaColors.textSecondary,
                  indicatorColor: MaaColors.pink,
                  dividerColor: MaaColors.glassBorder,
                  tabs: _groups.map((g) => Tab(text: g)).toList(),
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

          // ── Permission Banner ────────────────────────────────
          if (!_hasPermission)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildPermissionBanner(),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            ),

          // ── Quick Actions ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickBtn(
                      'Enable All',
                      Icons.check_circle_rounded,
                      MaaColors.success,
                      () => _setAllEnabled(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickBtn(
                      'Disable All',
                      Icons.block_rounded,
                      MaaColors.textSecondary,
                      () => _setAllEnabled(false),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quiet Hours Card ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildQuietHoursCard(),
            ),
          ),

          // ── Frequency Card ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildFrequencyCard(),
            ),
          ),

          // ── Test Notification Card ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildTestNotificationCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Category Tabs ────────────────────────────────────
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
              : SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(
                    height: 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: _groups.map((g) => _buildGroupTab(g)).toList(),
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── Permission Banner ──────────────────────────────────────
  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          MaaColors.warning.withAlpha(40),
          MaaColors.peach.withAlpha(25),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MaaColors.warning.withAlpha(50)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaaColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_off_rounded,
                color: MaaColors.warning, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications Band Hain!',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MaaColors.warning)),
                Text(
                  'Important reminders miss ho rahe hain',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: MaaColors.textSecondary),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _requestPermission,
            icon: const Icon(Icons.notifications_active_rounded, size: 18),
            label: Text('Enable Karo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Quick action buttons ───────────────────────────────────
  Widget _buildQuickBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(80)),
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Quiet Hours Card ───────────────────────────────────────
  Widget _buildQuietHoursCard() {
    String fmt(int h) =>
        '${h.toString().padLeft(2, '0')}:00 ${h < 12 ? 'AM' : 'PM'}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          MaaColors.softPurple.withAlpha(30),
          MaaColors.cardDark,
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MaaColors.softPurple.withAlpha(40)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaaColors.softPurple.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🌙', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quiet Hours',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MaaColors.textPrimary)),
              Text(
                'Is waqt koi notification nahi aayegi',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: MaaColors.textSecondary),
              ),
            ]),
          ),
          Switch.adaptive(
            value: _quietHours.enabled,
            onChanged: (v) => _updateQuietHours(v),
            activeColor: MaaColors.softPurple,
          ),
        ]),
        if (_quietHours.enabled) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _buildTimeButton(
                '${fmt(_quietHours.startHour)}\nShuru',
                () => _pickQuietHour(true),
                MaaColors.softPurple,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('→',
                  style: GoogleFonts.poppins(
                      color: MaaColors.textSecondary, fontSize: 18)),
            ),
            Expanded(
              child: _buildTimeButton(
                '${fmt(_quietHours.endHour)}\nKhatam',
                () => _pickQuietHour(false),
                MaaColors.pink,
              ),
            ),
          ]),
        ]
      ]),
    );
  }

  Widget _buildTimeButton(String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Frequency Card ─────────────────────────────────────────
  Widget _buildFrequencyCard() {
    final options = [
      {
        'value': 'smart',
        'label': 'Smart',
        'emoji': '🧠',
        'desc': 'AI decides best time'
      },
      {
        'value': 'daily',
        'label': 'Daily',
        'emoji': '📅',
        'desc': 'Max 2 per day'
      },
      {
        'value': 'weekly',
        'label': 'Weekly',
        'emoji': '📆',
        'desc': 'Weekly digest only'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          MaaColors.gold.withAlpha(25),
          MaaColors.cardDark,
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MaaColors.gold.withAlpha(40)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaaColors.gold.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('⚡', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notification Frequency',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MaaColors.textPrimary)),
              Text(
                'Kitni baar notifications chahiye?',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: MaaColors.textSecondary),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(
          children: options.map((opt) {
            final isSelected = _frequency == opt['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  await PushNotificationService.instance
                      .setNotificationFrequency(opt['value']!);
                  setState(() => _frequency = opt['value']!);
                },
                child: Container(
                  margin: EdgeInsets.only(right: opt == options.last ? 0 : 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MaaColors.gold.withAlpha(40)
                        : MaaColors.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? MaaColors.gold.withAlpha(80)
                            : MaaColors.glassBorder),
                  ),
                  child: Column(children: [
                    Text(opt['emoji']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(opt['label']!,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? MaaColors.gold
                                : MaaColors.textPrimary)),
                    Text(opt['desc']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: MaaColors.textSecondary)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildTestNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          MaaColors.pink.withAlpha(25),
          MaaColors.cardDark,
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MaaColors.pink.withAlpha(40)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaaColors.pink.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🔔', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Test Notification & Sound',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MaaColors.textPrimary)),
              Text(
                'Notification aur custom sound check karein',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: MaaColors.textSecondary),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await NotificationService.instance.initialize();
                await NotificationService.instance.showInstantNotification(
                  id: 999,
                  title: '🔔 Notification Chalu Hai! (MaaCare)',
                  body: 'Aapka custom notification sound perfect kaam kar raha hai. 🌸',
                  isUrgent: true,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🔔 Test notification sent! Check your device.',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: MaaColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '❌ Error: $e',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text('Sound Test Karein',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Category Tab View ──────────────────────────────────────
  Widget _buildGroupTab(String group) {
    final categories =
        NotificationCategory.values.where((c) => c.group == group).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 50),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isEnabled = _settings[cat] ?? true;
        return _buildCategoryTile(cat, isEnabled, index);
      },
    );
  }

  Widget _buildCategoryTile(
      NotificationCategory cat, bool isEnabled, int index) {
    final color = _getCategoryColor(cat);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            isEnabled ? MaaColors.cardDark : MaaColors.cardDark.withAlpha(160),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? color.withAlpha(50) : MaaColors.glassBorder,
        ),
        boxShadow: isEnabled
            ? [BoxShadow(color: color.withAlpha(15), blurRadius: 8)]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: isEnabled
                    ? [color.withAlpha(100), color.withAlpha(50)]
                    : [
                        MaaColors.textSecondary.withAlpha(30),
                        MaaColors.textSecondary.withAlpha(15)
                      ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          cat.label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isEnabled ? MaaColors.textPrimary : MaaColors.textSecondary,
          ),
        ),
        subtitle: Text(
          _categoryDescription(cat),
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: MaaColors.textSecondary,
          ),
        ),
        trailing: Switch.adaptive(
          value: isEnabled,
          onChanged: (v) => _toggleCategory(cat, v),
          activeColor: color,
          activeTrackColor: color.withAlpha(50),
        ),
      ),
    ).animate().fadeIn(delay: (40 * index).ms);
  }

  Color _getCategoryColor(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.pregnancyMilestone:
        return MaaColors.pink;
      case NotificationCategory.childGrowth:
        return MaaColors.lightBlue;
      case NotificationCategory.vaccination:
        return MaaColors.warning;
      case NotificationCategory.doctorConsult:
        return MaaColors.softPurple;
      case NotificationCategory.symptomCheck:
        return MaaColors.peach;
      case NotificationCategory.healthInsights:
        return MaaColors.gold;
      case NotificationCategory.safetyAlert:
        return Colors.redAccent;
      case NotificationCategory.nutrition:
        return MaaColors.success;
      case NotificationCategory.selfCare:
        return MaaColors.softGreen;
      case NotificationCategory.trackerSync:
        return MaaColors.lightBlue;
      case NotificationCategory.community:
        return MaaColors.softPurple;
      case NotificationCategory.friendRequest:
        return MaaColors.pink;
      case NotificationCategory.healthNews:
        return MaaColors.peach;
      case NotificationCategory.general:
        return MaaColors.textSecondary;
    }
  }

  String _categoryDescription(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.pregnancyMilestone:
        return 'Week-by-week baby development aur trimester alerts';
      case NotificationCategory.childGrowth:
        return 'Age-based milestones from 1 month to 8 years';
      case NotificationCategory.vaccination:
        return 'Indian NIS/UIP schedule – mother & baby reminders';
      case NotificationCategory.doctorConsult:
        return '48h, 24h, 15min appointment reminders';
      case NotificationCategory.symptomCheck:
        return 'AI-powered urgency alerts aur log reminders';
      case NotificationCategory.healthInsights:
        return 'Weight, BMI, risk pattern aur weekly reports';
      case NotificationCategory.safetyAlert:
        return 'Critical health aur security alerts (cannot mute)';
      case NotificationCategory.nutrition:
        return 'Personalized daily tips, recipes aur meal plans';
      case NotificationCategory.selfCare:
        return 'Prenatal yoga, meditation aur self-care guides';
      case NotificationCategory.trackerSync:
        return 'Reminder to update pregnancy tracker';
      case NotificationCategory.community:
        return 'Parents Park posts, replies aur new connections';
      case NotificationCategory.friendRequest:
        return 'New mama ne connect karna chaha';
      case NotificationCategory.healthNews:
        return 'Latest articles aur expert advice';
      case NotificationCategory.general:
        return 'App updates aur general announcements';
    }
  }
}

// ============================================================
//  Notification Permission Screen – MaaCare Onboarding
//  Warm opt-in consent shown after login, before home screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../services/push_notification_service.dart';
import '../../services/notification_service.dart';

class NotificationPermissionScreen extends StatefulWidget {
  final VoidCallback? onComplete; // callback after accept/skip

  const NotificationPermissionScreen({super.key, this.onComplete});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _isRequesting = false;

  // Category opt-in toggles shown on this screen
  final Map<String, bool> _optIns = {
    'pregnancy_milestone': true,
    'vaccination': true,
    'doctor_consult': true,
    'nutrition': true,
    'child_growth': true,
    'community': true,
    'self_care': false,
    'health_insights': false,
  };

  static const _displayItems = [
    {
      'key': 'pregnancy_milestone',
      'emoji': '🤰',
      'label': 'Pregnancy Milestones',
      'desc': 'Har hafte baby ka update aur trimester alerts',
    },
    {
      'key': 'vaccination',
      'emoji': '💉',
      'label': 'Vaccination Reminders',
      'desc': 'Indian UIP schedule – baby aur mama dono ke liye',
    },
    {
      'key': 'doctor_consult',
      'emoji': '👩‍⚕️',
      'label': 'Doctor Appointments',
      'desc': 'Appointment se 48h, 24h, 15min pehle alert',
    },
    {
      'key': 'nutrition',
      'emoji': '🥗',
      'label': 'Nutrition Tips',
      'desc': 'Roz subah personalized meal plan aur recipes',
    },
    {
      'key': 'child_growth',
      'emoji': '👶',
      'label': 'Child Growth',
      'desc': 'Baby ke milestones – 1m se 8 saal tak',
    },
    {
      'key': 'community',
      'emoji': '💬',
      'label': 'Community Updates',
      'desc': 'Parents Park: replies, connections, achievements',
    },
    {
      'key': 'self_care',
      'emoji': '🧘',
      'label': 'Self-Care Reminders',
      'desc': 'Daily yoga aur meditation session',
    },
    {
      'key': 'health_insights',
      'emoji': '📊',
      'label': 'Health Insights',
      'desc': 'Weekly health summary aur progress reports',
    },
  ];

  Future<void> _acceptAndContinue() async {
    setState(() => _isRequesting = true);

    // Request OS permission
    final granted =
        await PushNotificationService.instance.requestPermission();

    if (granted) {
      // Apply user-selected category preferences
      for (final item in _displayItems) {
        final cat = NotificationCategory.values.firstWhere(
          (c) => c.key == item['key'],
          orElse: () => NotificationCategory.general,
        );
        await PushNotificationService.instance.setCategoryEnabled(
            cat, _optIns[item['key']] ?? true);
      }

      // Schedule local reminders that don't depend on user data
      await NotificationService.instance.scheduleDailyNutritionTip();
      await NotificationService.instance.scheduleDailySelfCareReminder();
    }

    setState(() => _isRequesting = false);
    widget.onComplete?.call();
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  void _skipForNow() {
    widget.onComplete?.call();
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 20),
                // Hero icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MaaColors.pink.withAlpha(150),
                        MaaColors.softPurple.withAlpha(120),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MaaColors.pink.withAlpha(60),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🔔', style: TextStyle(fontSize: 52)),
                  ),
                ).animate().scale(begin: const Offset(0.7, 0.7)),

                const SizedBox(height: 28),
                Text(
                  'Mama, Connected Raho! 💕',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: MaaColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 12),
                Text(
                  'Important reminders miss karna afford nahi kar sakti aap!\n'
                  'Notifications enable karo aur choose karo kya chahiye:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: MaaColors.textSecondary,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 28),

                // Category toggles
                ...List.generate(_displayItems.length, (index) {
                  final item = _displayItems[index];
                  final isOn = _optIns[item['key']] ?? true;
                  return _buildCategoryRow(item, isOn, index)
                      .animate()
                      .fadeIn(delay: (100 + index * 60).ms)
                      .slideX(begin: 0.1, end: 0);
                }),

                const SizedBox(height: 8),
                // Privacy note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MaaColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: MaaColors.success.withAlpha(40)),
                  ),
                  child: Row(children: [
                    const Text('🔐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aapki privacy hamare liye important hai. Koi bhi '
                        'notification data share nahi hota. Settings mein '
                        'kabhi bhi change kar sakti hain.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: MaaColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: 900.ms),

                const SizedBox(height: 24),
              ]),
            ),
          ),

          // ── Bottom Buttons ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isRequesting ? null : _acceptAndContinue,
                  icon: _isRequesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.notifications_active_rounded,
                          size: 20),
                  label: Text(
                    _isRequesting ? 'Setting up...' : 'Enable Karo & Continue',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaaColors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: MaaColors.pink.withAlpha(80),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skipForNow,
                child: Text(
                  'Baad Mein Decide Karungi',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryRow(
      Map<String, String> item, bool isOn, int index) {
    return GestureDetector(
      onTap: () => setState(
          () => _optIns[item['key']!] = !(_optIns[item['key']!] ?? true)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isOn
              ? LinearGradient(colors: [
                  MaaColors.pink.withAlpha(25),
                  MaaColors.cardDark,
                ])
              : null,
          color: isOn ? null : MaaColors.cardDark.withAlpha(180),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOn
                ? MaaColors.pink.withAlpha(60)
                : MaaColors.glassBorder,
          ),
        ),
        child: Row(children: [
          Text(item['emoji']!,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(item['label']!,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOn
                          ? MaaColors.textPrimary
                          : MaaColors.textSecondary)),
              Text(item['desc']!,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: MaaColors.textSecondary)),
            ]),
          ),
          Switch.adaptive(
            value: isOn,
            onChanged: (v) =>
                setState(() => _optIns[item['key']!] = v),
            activeColor: MaaColors.pink,
            activeTrackColor: MaaColors.pink.withAlpha(40),
          ),
        ]),
      ),
    );
  }
}

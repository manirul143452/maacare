// ============================================================
//  PeriodDashboardScreen – GyneCare / Menstrual Support Dashboard
//  Premium, dark-themed dashboard. No pregnancy/baby references.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../theme/menstrual_medical_theme.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/menstrual_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/maacare_backend_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import 'widgets/bmi_card.dart';
import '../self_care/self_care_workspace.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/community_provider.dart';
import '../community/parents_park_screen.dart';


class PeriodDashboardScreen extends StatefulWidget {
  const PeriodDashboardScreen({super.key});

  @override
  State<PeriodDashboardScreen> createState() => _PeriodDashboardScreenState();
}

class _PeriodDashboardScreenState extends State<PeriodDashboardScreen> {
  int _selectedIndex = 0;

  // PCOS daily log state
  bool _pcosHairGrowth = false;
  bool _pcosWeightSwing = false;
  bool _pcosCycleVariance = false;

  // Hygiene reminder state
  bool _hygieneReminder = false;
  int _hygieneInterval = 4;

  bool _showEmergencySupportBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.user == null) {
      await userProvider.loadUser();
    }
    final user = userProvider.user;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }
    if (mounted) {
      if (user.userRole != 'unmarried_girl') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Unauthorised role for Period Dashboard.'),
            backgroundColor: Colors.red,
          ),
        );
        if (user.userRole == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else if (user.userRole == 'mother') {
          Navigator.pushReplacementNamed(context, '/mother_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
        return;
      }
      context.read<MenstrualProvider>().loadMenstrualLogs(user.id);
    }
    await _loadEmergencyBannerState();
  }

  Future<void> _savePcosToDb() async {
    final userId = AuthService.instance.getCurrentUserId();
    if (userId == null) return;
    try {
      await MaaCareBackendService.instance.saveMenstrualLog(
        userId: userId,
        extraFields: {
          'pcos_hair_growth': _pcosHairGrowth,
          'pcos_weight_swing': _pcosWeightSwing,
          'pcos_cycle_variance': _pcosCycleVariance,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pcosSaved),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PCOS log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadEmergencyBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showEmergencySupportBanner = prefs.getBool('show_emergency_support_banner') ?? false;
      });
    }
  }

  Future<void> _refreshData() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.loadUser();
    final user = userProvider.user;
    if (user != null && mounted) {
      await context.read<MenstrualProvider>().loadMenstrualLogs(user.id);
    }
    await _loadEmergencyBannerState();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return Theme(
      data: isUnmarried ? MenstrualMedicalTheme.themeData : Theme.of(context),
      child: Scaffold(
        backgroundColor: isUnmarried ? MenstrualMedicalTheme.obsidianBlack : MaaColors.background,
        body: Stack(
          children: [
            // Premium Glow Blobs
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.softPurple).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Consumer<MenstrualProvider>(
                builder: (context, menstrualProvider, child) => LoadingOverlay(
                  isLoading: userProvider.isLoading || menstrualProvider.isLoading,
                  child: child!,
                ),
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: primaryColor,
                  backgroundColor: isUnmarried ? MenstrualMedicalTheme.darkSlate : MaaColors.cardDark,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(user),
                        const SizedBox(height: 16),
                        _buildEmergencySupportCard(user?.id ?? ''),
                        Consumer<MenstrualProvider>(
                          builder: (context, menstrualProvider, _) =>
                              _buildStickyNotificationBanner(menstrualProvider),
                        ),
                        const SizedBox(height: 20),
                        Consumer<MenstrualProvider>(
                          builder: (context, menstrualProvider, _) =>
                              _buildCycleDialCard(user, menstrualProvider),
                        ),
                        const SizedBox(height: 20),
                        const BmiCard(),
                        const SizedBox(height: 20),
                        Consumer<MenstrualProvider>(
                          builder: (context, menstrualProvider, _) =>
                              _buildHealthAlertsBar(menstrualProvider),
                        ),
                        const SizedBox(height: 24),
                        Consumer<MenstrualProvider>(
                          builder: (context, menstrualProvider, _) =>
                              _buildSymptomChecker(user, menstrualProvider),
                        ),
                        const SizedBox(height: 24),
                        Consumer<MenstrualProvider>(
                          builder: (context, menstrualProvider, _) =>
                              _buildContraceptionTrackerCard(menstrualProvider),
                        ),
                        const SizedBox(height: 24),
                        Consumer<MenstrualProvider>(
                          builder: (context, menstrualProvider, _) =>
                              _buildCycleHarmonySuite(menstrualProvider),
                        ),
                        const SizedBox(height: 24),
                        _buildSelfCareSuite(),
                        const SizedBox(height: 24),
                        _buildDoctorConsultCard(),
                        const SizedBox(height: 24),
                        _buildLatestInSakhiCircle(isUnmarried),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/sakhi_ai');
          },
          backgroundColor: primaryColor,
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
          label: Text(
            'Talk to Sakhi AI',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ).animate().scale(delay: 600.ms, curve: Curves.easeOutBack),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: MaaColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              user?.name ?? 'Guest',
              style: GoogleFonts.poppins(
                fontSize: 24,
                color: MaaColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: MaaColors.pink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'GyneCare / Period Support Active',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: MaaColors.pink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MaaColors.pink.withValues(alpha: 0.5), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: MaaColors.cardDark,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'G',
                style: const TextStyle(
                  color: MaaColors.pink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCycleDialCard(UserModel? user, MenstrualProvider provider) {
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    final isLate = provider.isPeriodLate;
    final displayDays = isLate ? provider.daysLate : provider.daysUntilNextPeriod;
    final label = isLate ? 'Days Late' : 'Days Left';
    final progressVal = isLate ? 1.0 : (28 - provider.daysUntilNextPeriod) / 28.0;

    final ringColor = isLate ? Colors.orangeAccent : primaryColor;
    final secondaryRingColor = isLate ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05);

    String dateStr = 'No Log Yet';
    if (provider.nextPeriodDate != null) {
      final date = provider.nextPeriodDate!;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = '${months[date.month - 1]} ${date.day}';
    }

    final targetColor = _getPhaseColor(provider.cyclePhase);

    return _buildDashboardCard(
      isUnmarried: isUnmarried,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular progress dial + Edit Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isUnmarried)
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: targetColor),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, animatedColor, child) {
                        final activeColor = animatedColor ?? targetColor;
                        return Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                activeColor.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: progressVal.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: secondaryRingColor,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$displayDays',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isLate ? Colors.orangeAccent : (isUnmarried ? Colors.white : MaaColors.textPrimary),
                        ),
                      ),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isUnmarried ? Colors.white70 : MaaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _pickPeriodDate(user, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 12, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Last Period Date',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Period: $dateStr',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isUnmarried ? Colors.white : MaaColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLate ? Colors.orange : (isUnmarried ? targetColor : MaaColors.success),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Phase: ${provider.cyclePhase}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isUnmarried ? Colors.white70 : MaaColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isLate
                      ? 'Your cycle is late by $displayDays day(s). If late cycles persist, consult a doctor or run a PCOS review.'
                      : 'Keep logging symptoms to help improve cycle predictions and hormone insights.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPeriodDate(UserModel? user, MenstrualProvider provider) async {
    if (user == null) return;
    final isUnmarried = user.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;
    
    final messenger = ScaffoldMessenger.of(context);
    final periodSavedText = AppLocalizations.of(context).periodSaved;

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.lastPeriodStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: isUnmarried ? MenstrualMedicalTheme.darkSlate : MaaColors.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final success = await provider.savePeriodDate(user.id, picked);
      if (success && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(periodSavedText), backgroundColor: primaryColor),
        );
      }
    }
  }

  Widget _buildHealthAlertsBar(MenstrualProvider provider) {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    String tip;
    switch (provider.cyclePhase.toLowerCase()) {
      case 'menstrual':
        tip = '🩸 Menstrual Phase: Rest, warm compresses, and iron-dense meals (leafy greens, beans) are optimal now.';
        break;
      case 'follicular':
        tip = '✨ Follicular Phase: Energy levels are rising! Great time for active workouts and setting goals.';
        break;
      case 'ovulatory':
        tip = '🥚 Ovulatory Phase: Peak fertility window. Focus on fiber-rich fruits and metabolic stamina.';
        break;
      case 'luteal':
        tip = '🌙 Luteal Phase: Calm activity and magnesium (dark chocolate, nuts) can help ease incoming PMS.';
        break;
      default:
        tip = '🌸 Log your last period date to unlock phase-specific health alerts & tips.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        tip,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.9),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildEmergencySupportCard(String userId) {
    if (!_showEmergencySupportBanner) return const SizedBox.shrink();
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.withAlpha(50),
            Colors.black.withAlpha(80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withAlpha(150), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withAlpha(20),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emergency Support Active',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('show_emergency_support_banner', false);
                  setState(() {
                    _showEmergencySupportBanner = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Aapne haal hi mein severe cramps ya heavy flow log kiya hai. Kripya turant niche diye gaye emergency options ya doctor consultation ka upyog karein.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withAlpha(230),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('tel:108');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 16),
                  label: Text(
                    'Call 108',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/gynecare_consultation');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(Icons.healing_rounded, size: 16, color: primaryColor),
                  label: Text(
                    'Consult Expert',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSymptomChecker(UserModel? user, MenstrualProvider provider) {
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/gynecare'),
      child: _buildDashboardCard(
        isUnmarried: isUnmarried,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withAlpha(40), width: 1.5),
              ),
              child: Icon(
                Icons.health_and_safety_rounded,
                color: primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Symptoms Checker',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Log your symptoms, analyze menstrual comfort levels, and get medical insights.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isUnmarried ? Colors.white70 : MaaColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Check Symptoms',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildContraceptionTrackerCard(MenstrualProvider provider) {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return _buildDashboardCard(
      isUnmarried: isUnmarried,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: primaryColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Contraception & Planning',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isUnmarried ? Colors.white : MaaColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, color: primaryColor, size: 14),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.pushNamed(context, '/contraception_tracker');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'WHO Contraceptive Guidelines',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore public health guidelines, safe sex practices, dual protection, and detailed profiles of barrier & hormonal methods.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isUnmarried ? Colors.white70 : Colors.white54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGuideBadge('Safe Sex 🛡️', isUnmarried),
              const SizedBox(width: 8),
              _buildGuideBadge('WHO Rules 🌍', isUnmarried),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideBadge(String label, bool isUnmarried) {
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCycleHarmonySuite(MenstrualProvider provider) {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    final rawPhase = provider.cyclePhase.toLowerCase();
    String phaseName = provider.cyclePhase;
    String phaseEmoji = '🌸';
    String phaseBrief = 'Balance your hormones with AI-driven nutrition plans.';

    if (rawPhase.contains('menstrual')) {
      phaseEmoji = '🩸';
      phaseBrief = 'Focus: Iron replenishment & soothing cramps.';
    } else if (rawPhase.contains('follicular')) {
      phaseEmoji = '🌱';
      phaseBrief = 'Focus: Estrogen building & rising energy levels.';
    } else if (rawPhase.contains('ovulatory')) {
      phaseEmoji = '🥚';
      phaseBrief = 'Focus: Estrogen clearance & peak metabolism.';
    } else if (rawPhase.contains('luteal')) {
      phaseEmoji = '🌙';
      phaseBrief = 'Focus: Progesterone support & magnesium.';
    }

    return _buildDashboardCard(
      isUnmarried: isUnmarried,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cycle Harmony Suite',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isUnmarried ? Colors.white : MaaColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      phaseEmoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phaseName,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            phaseBrief,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/menstrual_nutrition'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu_rounded, color: primaryColor, size: 20),
                        const SizedBox(height: 6),
                        Text(
                          'AI Nutrition Planner',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phase-Specific Meals',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelfCareSuite() {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final accentColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.softPurple;

    return _buildDashboardCard(
      isUnmarried: isUnmarried,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Self-Care Workflow Suite',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isUnmarried ? Colors.white : MaaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Midnight Cramps
          _buildSelfCareTile(
            Icons.nightlight_round_outlined,
            'Midnight Cramps Protocol',
            '1. Place hot water bag on lower abdomen.\n2. Sip chamomile or ginger tea.\n3. Adopt the fetal sleeping position.',
          ),
          const Divider(color: Colors.white12, height: 24),

          // Period Yoga
          _buildYogaStretchContainer(isUnmarried),
          const Divider(color: Colors.white12, height: 24),

          // PCOS Tracker
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.tealAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'PCOS Daily Logging',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(AppLocalizations.of(context).pcosHairGrowth),
                    selected: _pcosHairGrowth,
                    labelStyle: GoogleFonts.outfit(fontSize: 11, color: _pcosHairGrowth ? Colors.black : Colors.white),
                    selectedColor: Colors.tealAccent,
                    onSelected: (v) => setState(() => _pcosHairGrowth = v),
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context).pcosWeightSwing),
                    selected: _pcosWeightSwing,
                    labelStyle: GoogleFonts.outfit(fontSize: 11, color: _pcosWeightSwing ? Colors.black : Colors.white),
                    selectedColor: Colors.tealAccent,
                    onSelected: (v) => setState(() => _pcosWeightSwing = v),
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context).pcosCycleVariance),
                    selected: _pcosCycleVariance,
                    labelStyle: GoogleFonts.outfit(fontSize: 11, color: _pcosCycleVariance ? Colors.black : Colors.white),
                    selectedColor: Colors.tealAccent,
                    onSelected: (v) => setState(() => _pcosCycleVariance = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Save PCOS Log Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text(AppLocalizations.of(context).savePcosLog),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _savePcosToDb,
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white12, height: 24),

          // Hygiene Reminders
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alarm_on_outlined, color: Colors.lightBlueAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Hygiene Pad Change Reminder',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  Switch(
                    value: _hygieneReminder,
                    activeColor: Colors.lightBlueAccent,
                    onChanged: (v) async {
                      setState(() => _hygieneReminder = v);
                      if (v) {
                        // Schedule actual local notifications
                        await NotificationService.instance.scheduleHygieneReminders(
                          intervalHours: _hygieneInterval,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🔔 Pad/Cup alerts active! Every $_hygieneInterval hours.'),
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
                        }
                      } else {
                        // Cancel all hygiene notifications
                        await NotificationService.instance.cancelHygieneReminders();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hygiene reminders turned off.'),
                              backgroundColor: Colors.grey,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              if (_hygieneReminder) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reminder Interval:',
                      style: GoogleFonts.outfit(fontSize: 12, color: isUnmarried ? Colors.white70 : MaaColors.textSecondary),
                    ),
                    Row(
                      children: [4, 6, 8].map((hours) {
                        final isSelected = _hygieneInterval == hours;
                        return GestureDetector(
                          onTap: () async {
                            setState(() => _hygieneInterval = hours);
                            // Reschedule with new interval if reminders are active
                            if (_hygieneReminder) {
                              await NotificationService.instance.scheduleHygieneReminders(
                                intervalHours: hours,
                              );
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Interval updated: Every $hours hours 🔔'),
                                  backgroundColor: Colors.blueAccent,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.lightBlueAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.lightBlueAccent : Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              '$hours Hours',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.lightBlueAccent : Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelfCareTile(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: GoogleFonts.outfit(fontSize: 12, color: MaaColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorConsultCard() {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return _buildDashboardCard(
      isUnmarried: isUnmarried,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Professional Guidance?',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect with trusted, peer-reviewed gynecologists and women\'s health experts under absolute privacy.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isUnmarried ? Colors.white70 : MaaColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.medical_services_outlined, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/gynecare_consultation');
              },
              label: const Text('Consult Gynaecologists'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyNotificationBanner(MenstrualProvider provider) {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    String alertText = '';
    switch (provider.cyclePhase.toLowerCase()) {
      case 'menstrual':
        alertText = 'SYSTEM PHASE ALERT: You are in the Menstrual Phase. Keep hydrated & practice gentle yoga.';
        break;
      case 'follicular':
        alertText = 'SYSTEM PHASE ALERT: Follicular Phase active. Energy rising — great time for planning!';
        break;
      case 'ovulatory':
        alertText = 'SYSTEM PHASE ALERT: Ovulatory Phase active. Peak performance and strength window.';
        break;
      case 'luteal':
        alertText = 'SYSTEM PHASE ALERT: Luteal Phase active. Focus on calming mind & body.';
        break;
      default:
        alertText = 'SYSTEM PHASE ALERT: Period date log pending. Update your start date to track cycle.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isUnmarried ? MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.8) : const Color(0xFF1F123C).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), duration: 800.ms)
           .fadeIn(duration: 800.ms),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                alertText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .slideX(begin: 0.1, end: -0.1, duration: 5.seconds, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildYogaStretchContainer(bool isUnmarried) {
    return PeriodYogaWorkspace(isUnmarried: isUnmarried);
  }

  Widget _buildBottomNav() {
    final user = context.read<UserProvider>().user;
    final isUnmarried = user?.userRole == 'unmarried_girl';
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;

    return Container(
      decoration: BoxDecoration(
        color: isUnmarried ? MenstrualMedicalTheme.darkSlate : MaaColors.cardDark,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, '/community');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryColor,
        unselectedItemColor: MaaColors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(isUnmarried ? Icons.supervised_user_circle_rounded : Icons.people_rounded),
            label: isUnmarried ? 'Sakhi Circle' : 'Parents Park',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Helper theme-builder for cards
  Widget _buildDashboardCard({
    required Widget child,
    required bool isUnmarried,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    if (isUnmarried) {
      return GlassmorphicCard(
        padding: padding,
        borderColor: borderColor ?? Colors.white10,
        backgroundColor: backgroundColor,
        child: child,
      );
    } else {
      return Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? MaaColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: child,
      );
    }
  }

  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return MenstrualMedicalTheme.redZoneCrimson;
      case 'follicular':
        return MenstrualMedicalTheme.greenZoneMint;
      case 'ovulatory':
        return MenstrualMedicalTheme.electricOrchid;
      case 'luteal':
        return MenstrualMedicalTheme.yellowZoneAmber;
      default:
        return MenstrualMedicalTheme.electricOrchid;
    }
  }

  Widget _buildLatestInSakhiCircle(bool isUnmarried) {
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;
    final headingText = isUnmarried ? 'Latest in Sakhi Circle' : 'Latest in Parents Park';
    
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        // Auto-fetch posts when widget builds (if not already loading or fetched)
        if (!provider.isLoading &&
            !provider.hasFetched &&
            provider.error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.fetchPosts(limit: 5);
          });
        }

        final posts = provider.posts.take(5).toList();

        // Fallback content if no posts yet
        final displayItems = posts.isEmpty
            ? _getPeriodFallbackPosts(isUnmarried)
            : posts
                .map((p) => _PostDisplayItem(
                      id: p.id,
                      text: p.content,
                      imageUrl: p.imageUrl,
                      likes: p.likes,
                      authorName: p.anonymous
                          ? (isUnmarried ? 'Anonymous Sakhi' : 'Anonymous Mama')
                          : (p.authorName ?? (isUnmarried ? 'Sakhi' : 'Mama')),
                      weekTag: p.weekTag,
                    ))
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnmarried
                              ? [
                                  MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.8),
                                  MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.8)
                                ]
                              : [
                                  MaaColors.pink.withAlpha(150),
                                  MaaColors.softPurple.withAlpha(100)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isUnmarried ? Icons.supervised_user_circle_rounded : Icons.favorite_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      headingText,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ParentsParkScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    AppLocalizations.of(context).viewAll,
                    style: GoogleFonts.poppins(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Live indicator when using real data
            if (posts.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MaaColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MaaColors.success.withValues(alpha: 0.2)),
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
                              color: MaaColors.success.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat()).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                        duration: 1000.ms),
                    const SizedBox(width: 8),
                    Text(
                      'Live Updates',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MaaColors.success,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _buildParentsParkCard(item, index, isUnmarried);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<_PostDisplayItem> _getPeriodFallbackPosts(bool isUnmarried) {
    if (isUnmarried) {
      return [
        _PostDisplayItem(
          id: 'p1',
          text: 'Best teas and heat-pad tips for menstrual cramps? ☕ Let\'s share!',
          imageUrl: null,
          likes: 38,
          authorName: 'Riya S.',
          weekTag: 0,
        ),
        _PostDisplayItem(
          id: 'p2',
          text: 'My PCOS fitness journey - diet and exercise tips that actually worked! 💪',
          imageUrl: null,
          likes: 92,
          authorName: 'Anonymous Sakhi',
          weekTag: 0,
        ),
        _PostDisplayItem(
          id: 'p3',
          text: 'Easy daily mindfulness and breathing practices during period days 🧘‍♀️',
          imageUrl: null,
          likes: 47,
          authorName: 'Sneha K.',
          weekTag: 0,
        ),
        _PostDisplayItem(
          id: 'p4',
          text: 'How do you track and manage your cycle irregularity? 🌸',
          imageUrl: null,
          likes: 54,
          authorName: 'Anonymous Sakhi',
          weekTag: 0,
        ),
      ];
    } else {
      return [
        _PostDisplayItem(
          id: 'p1',
          text: 'Best teas and heat-pad tips for menstrual cramps? ☕ Let\'s share!',
          imageUrl: null,
          likes: 42,
          authorName: 'Priya M.',
          weekTag: 0,
        ),
        _PostDisplayItem(
          id: 'p2',
          text: 'How do you handle severe PMS mood swings? 🌸',
          imageUrl: null,
          likes: 67,
          authorName: 'Anonymous Mama',
          weekTag: 0,
        ),
        _PostDisplayItem(
          id: 'p3',
          text: 'Easy daily mindfulness and breathing practices during period days 🧘‍♀️',
          imageUrl: null,
          likes: 41,
          authorName: 'Sarah K.',
          weekTag: 0,
        ),
        _PostDisplayItem(
          id: 'p4',
          text: 'Post-pregnancy menstrual cycle updates - what to expect? 💕',
          imageUrl: null,
          likes: 112,
          authorName: 'Anonymous Mama',
          weekTag: 0,
        ),
      ];
    }
  }

  Widget _buildParentsParkCard(_PostDisplayItem post, int index, bool isUnmarried) {
    final primaryColor = isUnmarried ? MenstrualMedicalTheme.electricOrchid : MaaColors.pink;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParentsParkScreen()),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isUnmarried
                ? [
                    MenstrualMedicalTheme.darkSlate,
                    MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.8),
                  ]
                : [
                    MaaColors.cardDark,
                    MaaColors.cardDark.withAlpha(200),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnmarried
                ? MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.3)
                : MaaColors.pink.withAlpha(30),
          ),
          boxShadow: [
            BoxShadow(
              color: isUnmarried ? Colors.black.withValues(alpha: 0.4) : MaaColors.darkShadow,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with author
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnmarried
                            ? [
                                MenstrualMedicalTheme.electricOrchid.withValues(alpha: 0.25),
                                MenstrualMedicalTheme.darkSlate.withValues(alpha: 0.1),
                              ]
                            : [
                                MaaColors.pink.withAlpha(40),
                                MaaColors.softPurple.withAlpha(20),
                              ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUnmarried
                                  ? [
                                      MenstrualMedicalTheme.electricOrchid,
                                      MenstrualMedicalTheme.darkSlate,
                                    ]
                                  : [
                                      MaaColors.pink,
                                      MaaColors.softPurple,
                                    ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'S',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.authorName,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MaaColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        post.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: MaaColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  // Footer with likes
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded,
                                  color: primaryColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likes}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.weekTag > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isUnmarried
                                      ? MenstrualMedicalTheme.electricOrchid
                                      : MaaColors.softPurple)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Week ${post.weekTag}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isUnmarried
                                    ? MenstrualMedicalTheme.electricOrchid
                                    : MaaColors.softPurple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // "Read More" overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isUnmarried
                          ? [
                              MenstrualMedicalTheme.darkSlate,
                              MenstrualMedicalTheme.darkSlate.withValues(alpha: 0),
                            ]
                          : [
                              MaaColors.cardDark,
                              MaaColors.cardDark.withAlpha(0),
                            ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Read More 💬',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: primaryColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _PostDisplayItem {
  final String id;
  final String text;
  final String? imageUrl;
  final int likes;
  final String authorName;
  final int weekTag;

  _PostDisplayItem({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.likes,
    required this.authorName,
    required this.weekTag,
  });
}

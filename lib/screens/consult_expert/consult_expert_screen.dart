// ============================================================
//  Consult Expert Screen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/insforge_service.dart';
import '../../widgets/maa_button.dart';
import 'patient_booking_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/user_provider.dart';
import 'doctor_profile_screen.dart';
import '../../l10n/app_localizations.dart';

class ConsultExpertScreen extends StatefulWidget {
  const ConsultExpertScreen({super.key});

  @override
  State<ConsultExpertScreen> createState() => _ConsultExpertScreenState();
}

class _ConsultExpertScreenState extends State<ConsultExpertScreen> {
  late Future<List<DoctorModel>> _doctorsFuture;
  DoctorModel? _myDoctorProfile;
  bool _checkingDoctorRole = true;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = InsForgeService.instance.fetchDoctors();
    _checkDoctorRole();
  }

  Future<void> _checkDoctorRole() async {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      final doc = await InsForgeService.instance.fetchDoctorByUserId(user.id);
      if (mounted) {
        setState(() {
          _myDoctorProfile = doc;
          _checkingDoctorRole = false;
        });
      }
    } else {
      if (mounted) setState(() => _checkingDoctorRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: MaaColors.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MaaColors.textPrimary),
          onPressed: () {
            // Force return to home screen (guarantees web routing works securely)
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
        title: Text(
          '${AppLocalizations.of(context).navConsult} 👩‍⚕️',
          style: GoogleFonts.poppins(
            color: MaaColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          debugPrint('Health is wealth, Mama! Consult anytime 💕');
        },
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: MaaColors.primaryGradient,
              ),
              child: Column(
                children: [
                  const Text('🩺', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect with certified doctors',
                    style: TextStyle(
                        color: MaaColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Video consultations from home 💕',
                    style: TextStyle(
                        color: MaaColors.white.withAlpha(200), fontSize: 13),
                  ),
                ],
              ),
            ),
            // Show doctor CTA only for logged-in users
            if (context.read<UserProvider>().user != null)
              _buildDoctorCTA(context),
            Expanded(
              child: FutureBuilder<List<DoctorModel>>(
                future: _doctorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: MaaColors.pink));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: MaaColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to load doctors',
                            style: GoogleFonts.poppins(
                              color: MaaColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: GoogleFonts.poppins(
                              color: MaaColors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _doctorsFuture = InsForgeService.instance.fetchDoctors();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MaaColors.pink,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final doctors = snapshot.data ?? [];
                  if (doctors.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_hospital_outlined, color: MaaColors.textMuted, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors available',
                            style: GoogleFonts.poppins(
                              color: MaaColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Doctors will appear here once they join.\nCheck back later!',
                            style: GoogleFonts.poppins(
                              color: MaaColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _doctorsFuture = InsForgeService.instance.fetchDoctors();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MaaColors.pink,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _DoctorCard(
                      doctor: doctors[i],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCTA(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_checkingDoctorRole) return;
        final route = _myDoctorProfile != null
            ? '/doctor-dashboard'
            : '/doctor-registration';
        Navigator.pushNamed(context, route).then((_) => _checkDoctorRole());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: MaaColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MaaColors.gold.withAlpha(50),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('👩‍⚕️', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _myDoctorProfile != null
                        ? 'Manage your Profile & Bookings'
                        : 'Join our Expert Network',
                    style: GoogleFonts.poppins(
                      color: MaaColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _myDoctorProfile != null
                        ? 'View your upcoming consultations.'
                        : 'Are you a doctor? Help Mamas across India.',
                    style: GoogleFonts.poppins(
                      color: MaaColors.white.withAlpha(200),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!_checkingDoctorRole)
              IgnorePointer(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaaColors.white,
                    foregroundColor: MaaColors.gold,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    _myDoctorProfile != null ? 'My Dashboard' : 'Join Now',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            if (_checkingDoctorRole)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: MaaColors.white,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  const _DoctorCard({required this.doctor});

  void _bookConsultation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientBookingScreen(doctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MaaColors.glassBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: MaaColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(doctor.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(doctor.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700, color: MaaColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (doctor.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                color: MaaColors.pink, size: 16),
                          ],
                        ],
                      ),
                      Text(doctor.specialization,
                          style: const TextStyle(
                              fontSize: 12, color: MaaColors.textSecondary)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: MaaColors.gold, size: 14),
                          Text(' ${doctor.rating}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: MaaColors.textPrimary)),
                          Text(' · ${doctor.experience} exp',
                              style: const TextStyle(
                                  fontSize: 12, color: MaaColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  doctor.fee,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MaaColors.deepPink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: MaaColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: MaaColors.success),
                  const SizedBox(width: 6),
                  Text('Available: ${doctor.availableHours}',
                      style: const TextStyle(
                          fontSize: 12, color: MaaColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MaaButton(
              label: 'Book Appointment',
              onPressed: () => _bookConsultation(context),
            ),
          ],
        ),
      ),
    );
  }
}

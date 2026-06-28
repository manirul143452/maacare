import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_model.dart';
import '../consult_expert/doctor_slots_screen.dart';

class DoctorProfileView extends StatefulWidget {
  const DoctorProfileView({super.key});

  @override
  State<DoctorProfileView> createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends State<DoctorProfileView> {
  DoctorModel? _doctor;
  List<BookingModel> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = context.read<UserProvider>().user;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No active doctor session found.';
        });
        return;
      }

      final doc = await MaaCareBackendService.instance.fetchDoctorByUserId(user.id);
      if (doc != null) {
        final apps = await MaaCareBackendService.instance.fetchAppointmentsForDoctor(doc.id);
        if (mounted) {
          setState(() {
            _doctor = doc;
            _appointments = apps;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Doctor credentials not registered in clinic directory.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load professional stats. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: MaaColors.pink),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(color: MaaColors.pink),
        ),
      );
    }

    if (_errorMessage != null || _doctor == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👩‍⚕️', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Doctor profile not found.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: MaaColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchDoctorData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaaColors.pink,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeQueue = _appointments.where((a) => a.status == 'scheduled' || a.status == 'accepted').toList();
    final completedCount = _appointments.where((a) => a.status == 'completed').toList().length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Doctor Header Hero
          _buildDoctorHeader(user),
          const SizedBox(height: 20),

          // 2. Doctor Stats Grid
          _buildStatsGrid(activeQueue.length, completedCount),
          const SizedBox(height: 20),

          // 3. Clinical Profile Info Details
          _buildProfessionalDetailsCard(),
          const SizedBox(height: 24),

          // 4. Quick Action Buttons
          _buildActionButtons(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        gradient: LinearGradient(
          colors: [
            MaaColors.cardDark,
            MaaColors.cardLight.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MaaColors.pink.withValues(alpha: 0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: MaaColors.pink.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    _doctor!.emoji.isNotEmpty ? _doctor!.emoji : '👩‍⚕️',
                    style: const TextStyle(fontSize: 56),
                  ),
                ),
              ),
              if (_doctor!.isVerified)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: MaaColors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _doctor!.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _doctor!.specialization,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MaaColors.pink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _doctor!.clinicLocation,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: MaaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: MaaColors.pink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MaaColors.pink.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Expert Medical Practitioner',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MaaColors.pink,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsGrid(int activeQueueCount, int completedCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '⭐',
            _doctor!.rating,
            'Rating',
            MaaColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '💼',
            _doctor!.experience,
            'Experience',
            MaaColors.peach,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '🎟️',
            _doctor!.fee,
            'Consult Fee',
            MaaColors.success,
          ),
        ),
      ],
    ).animate().fade(duration: 450.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: MaaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalDetailsCard() {
    // Generate availability days string
    final daysStr = _doctor!.availableDays.join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Credentials & Timings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoDetailRow('🪪', 'Medical Registration', _doctor!.licenseUrl ?? 'REG-12345'),
          _buildDivider(),
          _buildInfoDetailRow('⏰', 'Daily Shifts', _doctor!.availableHours),
          _buildDivider(),
          _buildInfoDetailRow('📅', 'Weekly Schedule', daysStr.isNotEmpty ? daysStr : 'Mon - Fri'),
          _buildDivider(),
          _buildBioDetailRow('📝', 'Doctor Bio', _doctor!.bio.isNotEmpty ? _doctor!.bio : 'No clinical biography provided.'),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoDetailRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: MaaColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioDetailRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: MaaColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.05),
      height: 16,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/edit_profile');
                  _fetchDoctorData();
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaaColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorSlotsScreen()),
                  );
                  _fetchDoctorData();
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const Text('Config Slots'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MaaColors.pink,
                  side: const BorderSide(color: MaaColors.pink),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _fetchDoctorData,
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: const Text('Sync System Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: MaaColors.cardLight,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final userProvider = context.read<UserProvider>();
            await userProvider.signOut();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
            }
          },
          icon: const Icon(Icons.logout_rounded, size: 18, color: MaaColors.error),
          label: const Text('Sign Out Session', style: TextStyle(color: MaaColors.error)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: MaaColors.error.withValues(alpha: 0.5)),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    ).animate().fade(duration: 550.ms).slideY(begin: 0.1, end: 0);
  }
}

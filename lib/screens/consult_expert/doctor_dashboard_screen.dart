// ============================================================
//  Doctor Dashboard Screen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../services/insforge_service.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/maa_button.dart';
import 'join_consultation_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _isLoading = true;
  DoctorModel? _doctor;
  List<BookingModel> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final doc = await InsForgeService.instance.fetchDoctorByUserId(user.id);
    if (doc != null) {
      final apps = await InsForgeService.instance.fetchAppointmentsForDoctor(doc.id);
      if (mounted) {
        setState(() {
          _doctor = doc;
          _appointments = apps;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Dashboard 🩺'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MaaColors.pink))
          : _doctor == null
              ? _buildNoDoctorView()
              : _buildDashboardView(),
    );
  }

  Widget _buildNoDoctorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👩‍⚕️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text(
              'Not Registered as an Expert',
              style: GoogleFonts.poppins(fontSize: 20, color: MaaColors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Join our network to help Mamas and build your professional profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: MaaColors.textMuted),
            ),
            const SizedBox(height: 30),
            MaaButton(
              label: 'Register Now',
              onPressed: () => Navigator.pushReplacementNamed(context, '/doctor-registration'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Appointments',
                style: GoogleFonts.poppins(fontSize: 18, color: MaaColors.white, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: MaaColors.pink.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: Text('${_appointments.length}', style: const TextStyle(color: MaaColors.pink, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_appointments.isEmpty)
            _buildEmptyAppointments()
          else
            ..._appointments.map((app) => _buildAppointmentCard(app)),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isVerified = _doctor?.status == 'verified';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isVerified ? MaaColors.successGradient : MaaColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: MaaColors.white.withAlpha(50),
            backgroundImage: _doctor?.avatarUrl != null ? NetworkImage(_doctor!.avatarUrl!) : null,
            child: _doctor?.avatarUrl == null ? const Text('👩‍⚕️', style: TextStyle(fontSize: 30)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _doctor?.name ?? 'Expert',
                  style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  isVerified ? '✓ Verified Professional' : '⏳ Verification Pending',
                  style: TextStyle(color: MaaColors.white.withAlpha(200), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyAppointments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MaaColors.white.withAlpha(5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined, color: MaaColors.textMuted, size: 40),
          const SizedBox(height: 16),
          Text(
            'No appointments yet',
            style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.w500),
          ),
          Text(
            'Check back later for new bookings.',
            style: GoogleFonts.poppins(color: MaaColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BookingModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: MaaColors.white.withAlpha(10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: MaaColors.pink.withAlpha(20), shape: BoxShape.circle),
            child: const Icon(Icons.person, color: MaaColors.pink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.patientName,
                  style: GoogleFonts.poppins(color: MaaColors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${app.appointmentDate.day}/${app.appointmentDate.month}/${app.appointmentDate.year} • '
                  '${app.symptoms.split('\n').first}', // We stored the time natively on line 1 of symptoms
                  style: GoogleFonts.poppins(color: MaaColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          MaaButton(
            label: 'Join Call',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JoinConsultationScreen(
                    appointment: app,
                    roomCode: 'demo_room_code', // Replace with real code from backend later
                    userName: 'Dr. ${_doctor?.name ?? "Expert"}',
                  ),
                ),
              );
            },
            width: 100,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}

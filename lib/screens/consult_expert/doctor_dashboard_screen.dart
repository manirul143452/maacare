// ============================================================
//  DoctorDashboardScreen – Clinical Workflow Dashboard
//  Fully isolated from consumer features. Protected with role guards.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_theme.dart';
import '../../services/maacare_backend_service.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/maa_button.dart';
import 'doctor_chat_view.dart';
import 'doctor_slots_screen.dart';
import '../../services/realtime_client.dart';

import '../profile/profile_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentTab = 0;
  bool _isLoading = true;
  DoctorModel? _doctor;
  List<BookingModel> _appointments = [];
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    if (_doctor != null) {
      InsForgeRealtimeClient.instance.unsubscribe('appointments:${_doctor!.id}');
    }
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.user == null) {
      await userProvider.loadUser();
    }
    final user = userProvider.user;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // STRICT MIDDLEWARE GUARD: Doctors Only
    if (user.userRole != 'doctor') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Unauthorised Session Token.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    final doc = await MaaCareBackendService.instance.fetchDoctorByUserId(user.id);
    if (doc != null) {
      if (!_isSubscribed) {
        _isSubscribed = true;
        InsForgeRealtimeClient.instance.subscribe('appointments:${doc.id}', (payload) {
          debugPrint('[DoctorDashboard] Real-time appointment update received');
          _loadDashboard();
        });
      }
      final apps = await MaaCareBackendService.instance.fetchAppointmentsForDoctor(doc.id);
      
      // Sort appointments by urgency (Red triage first, then Yellow, then Green)
      apps.sort((a, b) {
        final aUrgent = _isUrgent(a);
        final bUrgent = _isUrgent(b);
        if (aUrgent && !bUrgent) return -1;
        if (!aUrgent && bUrgent) return 1;
        return 0;
      });

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

  bool _isUrgent(BookingModel app) {
    final text = app.symptoms.toLowerCase();
    return text.contains('critical') || text.contains('red zone') || text.contains('emergency');
  }

  bool _isWarning(BookingModel app) {
    final text = app.symptoms.toLowerCase();
    return text.contains('warning') || text.contains('yellow zone');
  }

  Future<void> _editPrescription(BookingModel app) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 1. Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: MaaColors.pink),
      ),
    );

    // 2. Fetch session
    final session = await MaaCareBackendService.instance.fetchConsultationSession(
      app.doctorId,
      app.userId,
    );

    // Close loading dialog
    if (mounted) {
      navigator.pop();
    }

    if (session == null) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No consultation session record found to edit.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final controller = TextEditingController(text: session['prescription_text'] ?? '');

    if (!mounted) return;

    // 3. Show edit dialog
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Prescription - ${app.patientName}',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter clinical notes or prescription...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MaaColors.pink),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newText = controller.text.trim();
              Navigator.of(dialogCtx).pop(); // Close edit dialog
              
              // Show loading again
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const Center(
                  child: CircularProgressIndicator(color: MaaColors.pink),
                ),
              );

              final success = await MaaCareBackendService.instance.updateConsultationSession(
                session['id'],
                {'prescription_text': newText},
              );

              if (mounted) {
                navigator.pop(); // Close loading
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Prescription updated successfully! 💾'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update prescription.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MaaColors.background,
        body: Center(child: CircularProgressIndicator(color: MaaColors.pink)),
      );
    }

    if (_doctor == null) {
      return Scaffold(
        backgroundColor: MaaColors.background,
        body: _buildNoDoctorView(),
      );
    }

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _currentTab == 0
              ? 'Clinical Patient Queue 🩺'
              : _currentTab == 1
                  ? 'Scheduling Settings ⚙️'
                  : _currentTab == 2
                      ? 'Consultation History 📝'
                      : 'Professional Profile 👤',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentTab == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadDashboard,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const DoctorSlotsScreen();
      case 2:
        return _buildLogsView();
      case 3:
        return const ProfileScreen();
      default:
        return _buildDashboardView();
    }
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
                'Active Consultations Queue',
                style: GoogleFonts.poppins(fontSize: 16, color: MaaColors.white, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: MaaColors.pink.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('${_appointments.length}', style: const TextStyle(color: MaaColors.pink, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_appointments.isEmpty)
            _buildEmptyAppointments()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(_appointments[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLogsView() {
    final completedApps = _appointments.where((a) => a.status == 'completed').toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consultation & Prescription History',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (completedApps.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('No completed sessions logged.', style: GoogleFonts.outfit(color: Colors.white38)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedApps.length,
              itemBuilder: (context, index) {
                final app = completedApps[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: MaaColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            app.patientName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${app.appointmentDate.day}/${app.appointmentDate.month}/${app.appointmentDate.year}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MaaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 20),
                      Text(
                        'Diagnostics / Symptoms:',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: MaaColors.pink),
                      ),
                      Text(
                        app.symptoms,
                        style: GoogleFonts.outfit(fontSize: 12, color: MaaColors.textPrimary, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Edit Prescription'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MaaColors.pink.withValues(alpha: 0.15),
                              foregroundColor: Colors.white,
                              side: BorderSide(color: MaaColors.pink.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _editPrescription(app),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
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
            backgroundColor: MaaColors.white.withValues(alpha: 0.2),
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
                  style: TextStyle(color: MaaColors.white.withValues(alpha: 0.8), fontSize: 13),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined, color: MaaColors.textMuted, size: 40),
          const SizedBox(height: 16),
          Text(
            'No appointments queued',
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
    final urgent = _isUrgent(app);
    final warning = _isWarning(app);

    final dotColor = urgent
        ? Colors.redAccent
        : warning
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: urgent ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: MaaColors.pink.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: MaaColors.pink),
              ),
              // Urgency Indicator Dot Widget
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: MaaColors.cardDark, width: 2),
                ),
              ),
            ],
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
                  '${app.symptoms.split('\n').first}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: MaaColors.textMuted, fontSize: 11),
                ),
                if (app.symptoms.contains("Clinical Report: Attached")) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _viewPatientReport(app),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description, color: MaaColors.pink, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'View Patient Report',
                          style: GoogleFonts.outfit(color: MaaColors.pink, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MaaColors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorChatView(
                    appointment: app,
                    doctor: _doctor!,
                  ),
                ),
              ).then((_) => _loadDashboard());
            },
            child: Text(
              'Consult',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: MaaColors.pink,
        unselectedItemColor: MaaColors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_play_next_rounded),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_on_outlined),
            label: 'Schedules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_rounded),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _viewPatientReport(BookingModel app) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: MaaColors.pink),
          ),
        ),
      ),
    );

    final reportUrl = await MaaCareBackendService.instance.fetchPatientReportUrl(
      patientId: app.userId,
      doctorId: app.doctorId,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (reportUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lab report found for this patient.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Show Report Viewer Overlay Modal
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MaaColors.cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Patient Lab Report',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Patient Name: ${app.patientName}',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: reportUrl.endsWith('.pdf')
                        ?
                          // PDF: Show icon + Open PDF button (not just selectable text)
                          Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    'PDF Report Ready',
                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                                    label: const Text('Open PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: MaaColors.pink,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      final uri = Uri.tryParse(reportUrl);
                                      if (uri != null && await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                      : Image.network(
                          reportUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(color: MaaColors.pink));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.broken_image, color: Colors.red, size: 64));
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

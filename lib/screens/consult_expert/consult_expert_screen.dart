// ============================================================
//  Consult Expert Screen – MaaCare Premium Redesign
//  Practo + Teladoc inspired medical consultation UI
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_model.dart';
import '../../services/maacare_backend_service.dart';
import '../../providers/user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'doctor_profile_screen.dart';
import 'patient_chat_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/permission_helper.dart';
import '../../widgets/booking_checkout_sheet.dart';


// ─── Specialty filter chips ───
const _specialties = [
  '✨ All',
  '🤰 Gynecologist',
  '👶 Pediatrician',
  '🧘 Counsellor',
  '🩺 GP',
  '🧬 Nutritionist',
];

class ConsultExpertScreen extends StatefulWidget {
  const ConsultExpertScreen({super.key});

  @override
  State<ConsultExpertScreen> createState() => _ConsultExpertScreenState();
}

class _ConsultExpertScreenState extends State<ConsultExpertScreen> {
  late Future<List<DoctorModel>> _doctorsFuture;
  Future<List<BookingModel>>? _myBookingsFuture;
  DoctorModel? _myDoctorProfile;
  bool _checkingDoctorRole = true;
  String _selectedSpecialty = '✨ All';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _handlingIncomingCall = false;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = MaaCareBackendService.instance.fetchDoctors();
    _loadBookings();
    _checkDoctorRole();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  void _loadBookings() {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      setState(() {
        _myBookingsFuture = MaaCareBackendService.instance.fetchAppointmentsForPatient(user.id);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_handlingIncomingCall) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('room_code')) {
        _handlingIncomingCall = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleIncomingCallNotification(args);
        });
      }
    }
  }

  Future<void> _handleIncomingCallNotification(Map<String, dynamic> args) async {
    final hasPermissions = await PermissionHelper.checkVideoPermissions(context);
    if (!hasPermissions) {
      setState(() => _handlingIncomingCall = false);
      return;
    }

    if (!mounted) return;
    
    final userName = context.read<UserProvider>().user?.name ?? 'Mama';
    final routeArgs = {
      'room_code': args['room_code'],
      'user_name': userName,
      'session_id': args['session_id'],
      'patient_name': userName,
    };

    Navigator.pushNamed(context, '/join-consultation', arguments: routeArgs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkDoctorRole() async {
    final user = context.read<UserProvider>().user;
    if (user != null) {
      final doc = await MaaCareBackendService.instance.fetchDoctorByUserId(user.id);
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

  List<DoctorModel> _filterDoctors(List<DoctorModel> all) {
    return all.where((d) {
      final matchesSpec = _selectedSpecialty == '✨ All' ||
          d.specialization
              .toLowerCase()
              .contains(_selectedSpecialty.split(' ').last.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery) ||
          d.specialization.toLowerCase().contains(_searchQuery);
      return matchesSpec && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.read<UserProvider>().user != null;
    return Scaffold(
      backgroundColor: MaaColors.background,
      body: RefreshIndicator(
        color: MaaColors.pink,
        onRefresh: () async {
          _loadBookings();
          _checkDoctorRole();
          setState(() {
            _doctorsFuture = MaaCareBackendService.instance.fetchDoctors();
          });
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _buildSliverAppBar(context),
          ],
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSearchBar(),
              _buildSpecialtyChips(),
              if (isLoggedIn) _buildDoctorBanner(),
              if (isLoggedIn) _buildMyBookingsSection(),
              const SizedBox(height: 12),
              SizedBox(
                height: 500, // Explicit height for the list to scroll inside the ListView
                child: _buildDoctorList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sliver App Bar with gradient hero ───────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: MaaColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: MaaColors.textPrimary, size: 20),
        onPressed: () =>
            Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
      ),
      title: Text(
        '${AppLocalizations.of(context).navConsult} 👩‍⚕️',
        style: GoogleFonts.poppins(
          color: MaaColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildHeroSection(),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9D4EDD),
            const Color(0xFFFF69B4),
            const Color(0xFFFFADD2).withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect with\nCertified Doctors',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Video consultations from home ❤️',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withAlpha(210),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _HeroBookNowButton(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withAlpha(80), width: 1.5),
                ),
                child: const Center(
                  child: Text('🩺', style: TextStyle(fontSize: 40)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Search bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: MaaColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name or specialty…',
          hintStyle:
              GoogleFonts.poppins(color: MaaColors.textMuted, fontSize: 13),
          prefixIcon:
              const Icon(Icons.search_rounded, color: MaaColors.pink, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: MaaColors.textMuted, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: MaaColors.cardDark,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: MaaColors.glassBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MaaColors.pink, width: 1.5),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ─── Specialty filter chips ───────────────────────────────────────────────

  Widget _buildSpecialtyChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = _specialties[i];
          final selected = _selectedSpecialty == label;
          return GestureDetector(
            onTap: () => setState(() => _selectedSpecialty = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? MaaColors.primaryGradient : null,
                color: selected ? null : MaaColors.cardDark,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? Colors.transparent : MaaColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : MaaColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Doctor CTA banner (only for logged-in users) ────────────────────────

  Widget _buildDoctorBanner() {
    return GestureDetector(
      onTap: () {
        if (_checkingDoctorRole) return;
        final route = _myDoctorProfile != null
            ? '/doctor-dashboard'
            : '/doctor-registration';
        Navigator.pushNamed(context, route).then((_) => _checkDoctorRole());
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MaaColors.pink.withAlpha(60),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: MaaColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👩‍⚕️', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _myDoctorProfile != null
                        ? 'Manage Profile & Bookings'
                        : 'Are you a Doctor? Join Us',
                    style: GoogleFonts.poppins(
                      color: MaaColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _myDoctorProfile != null
                        ? 'View upcoming consultations'
                        : 'Help Mamas across India',
                    style: GoogleFonts.poppins(
                      color: MaaColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (_checkingDoctorRole)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: MaaColors.pink),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _myDoctorProfile != null ? 'Dashboard' : 'Join Now',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
    );
  }

  // ─── My Bookings / Consultations horizontal list ──────────────────────────

  Widget _buildMyBookingsSection() {
    return FutureBuilder<List<BookingModel>>(
      future: _myBookingsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: MaaColors.pink),
              ),
            ),
          );
        }
        final bookings = snap.data ?? [];
        final activeBookings = bookings.where((b) => b.status != 'cancelled').toList();
        if (activeBookings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Consultations 🩺',
                    style: GoogleFonts.poppins(
                      color: MaaColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${activeBookings.length} Active',
                    style: GoogleFonts.poppins(
                      color: MaaColors.pink,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 125,
              child: FutureBuilder<List<DoctorModel>>(
                future: _doctorsFuture,
                builder: (context, docSnap) {
                  final doctors = docSnap.data ?? [];
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: activeBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final booking = activeBookings[index];
                      // Find matching doctor or create a fallback DoctorModel
                      final doctor = doctors.firstWhere(
                        (d) => d.id == booking.doctorId,
                        orElse: () => DoctorModel(
                          id: booking.doctorId,
                          name: 'Consulting Doctor',
                          specialization: 'MaaCare Specialist',
                          experience: '5+ yrs',
                          rating: '4.9',
                          fee: booking.amount,
                          bio: 'Certified teleconsultation specialist.',
                          availableHours: 'Flexible',
                          emoji: '👩‍⚕️',
                        ),
                      );

                      final dateStr = DateFormat('MMM dd, yyyy').format(booking.appointmentDate);
                      final timeStr = DateFormat('jm').format(booking.appointmentDate);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientChatView(
                                appointment: booking,
                              ),
                            ),
                          ).then((_) => _loadBookings());
                        },
                        child: Container(
                          width: 280,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MaaColors.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: booking.status == 'scheduled'
                                  ? MaaColors.pink.withAlpha(50)
                                  : MaaColors.glassBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar / Emoji
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  gradient: MaaColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    doctor.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      doctor.name,
                                      style: GoogleFonts.poppins(
                                        color: MaaColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      doctor.specialization,
                                      style: GoogleFonts.poppins(
                                        color: MaaColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 11,
                                          color: MaaColors.pink,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$dateStr @ $timeStr',
                                          style: GoogleFonts.poppins(
                                            color: MaaColors.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: booking.status == 'scheduled'
                                            ? MaaColors.success.withAlpha(20)
                                            : MaaColors.pink.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        booking.status == 'scheduled'
                                            ? '👉 Tap to Chat & Call'
                                            : booking.status.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          color: booking.status == 'scheduled'
                                              ? MaaColors.success
                                              : MaaColors.pink,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }


  // ─── Doctor list (FutureBuilder) ─────────────────────────────────────────

  Widget _buildDoctorList() {
    return FutureBuilder<List<DoctorModel>>(
      future: _doctorsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: MaaColors.pink));
        }

        if (snap.hasError) {
          return _buildErrorState(snap.error.toString());
        }

        final doctors = _filterDoctors(snap.data ?? []);

        if (doctors.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: doctors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _DoctorCard(
            doctor: doctors[i],
            index: i,
          ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: MaaColors.error, size: 56),
            const SizedBox(height: 16),
            Text(
              'Could not load doctors',
              style: GoogleFonts.poppins(
                color: MaaColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style:
                  GoogleFonts.poppins(color: MaaColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() =>
                  _doctorsFuture = MaaCareBackendService.instance.fetchDoctors()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaaColors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👩‍⚕️', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedSpecialty != '✨ All'
                ? 'No results found'
                : 'No doctors available yet',
            style: GoogleFonts.poppins(
              color: MaaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Doctors will appear here once they join.',
            style: GoogleFonts.poppins(
                color: MaaColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (_selectedSpecialty != '✨ All' || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSpecialty = '✨ All';
                  _searchController.clear();
                });
              },
              child: const Text('Clear Filters',
                  style: TextStyle(color: MaaColors.pink)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Animated Hero "Book Now" button ─────────────────────────────────────────

class _HeroBookNowButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Scroll to doctor list (already visible — just for UX affordance)
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_rounded,
                color: Color(0xFF9D4EDD), size: 18),
            const SizedBox(width: 8),
            Text(
              'Book a Consult',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9D4EDD),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0);
  }
}

// ─── Doctor Card ─────────────────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final int index;

  const _DoctorCard({required this.doctor, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MaaColors.glassBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top row: avatar + info ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  _buildAvatar(),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(child: _buildInfo()),
                  // Fee badge
                  _buildFeeBadge(),
                ],
              ),
            ),

            // ── Availability strip ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: MaaColors.success.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: MaaColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: MaaColors.success.withAlpha(100),
                            blurRadius: 6)
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: MaaColors.success),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      doctor.availableHours,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: MaaColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── CTA button row ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // View Profile
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                DoctorProfileScreen(doctor: doctor)),
                      ),
                      icon: const Icon(Icons.person_outline_rounded, size: 16),
                      label: Text(
                        'Profile',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MaaColors.pink,
                        side: const BorderSide(color: MaaColors.pink, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Book Now
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: MaaColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: MaaColors.pink.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => BookingCheckoutSheet.show(context, doctor),
                        icon: const Icon(Icons.videocam_rounded,
                            size: 16, color: Colors.white),
                        label: Text(
                          'Book Video Consult',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            gradient: MaaColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: doctor.avatarUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 150,
                    placeholder: (context, url) => Center(
                      child: Text(doctor.emoji,
                          style: const TextStyle(fontSize: 32)),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(doctor.emoji,
                          style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                )
              : Center(
                  child:
                      Text(doctor.emoji, style: const TextStyle(fontSize: 32)),
                ),
        ),
        if (doctor.isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: MaaColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded,
                  color: MaaColors.pink, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                doctor.name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MaaColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          doctor.specialization,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: MaaColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Rating
            _statPill(
              icon: Icons.star_rounded,
              label: doctor.rating,
              color: MaaColors.gold,
            ),
            const SizedBox(width: 8),
            // Experience
            _statPill(
              icon: Icons.work_history_rounded,
              label: doctor.experience,
              color: MaaColors.lightBlue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statPill(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: MaaColors.success.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MaaColors.success.withAlpha(40), width: 1),
      ),
      child: Text(
        doctor.fee,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: MaaColors.success,
        ),
      ),
    );
  }
}

// ============================================================
//  GyneCareConsultationScreen – Consult GyneCare Experts
//  Premium, dark-themed. Custom digital triage and unmarried_girl logging.
//  Real Razorpay integration (Web + Mobile)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../app_theme.dart';
import '../../constants.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/menstrual_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../services/razorpay_web_service.dart';
import '../../services/payment_service.dart';
import '../../utils/error_helper.dart';
import '../../widgets/loading_overlay.dart';
import 'package:intl/intl.dart';
import 'patient_chat_view.dart';
import '../../services/push_notification_service.dart';
import 'doctor_profile_screen.dart';

class GyneCareConsultationScreen extends StatefulWidget {
  const GyneCareConsultationScreen({super.key});

  @override
  State<GyneCareConsultationScreen> createState() => _GyneCareConsultationScreenState();
}

class _GyneCareConsultationScreenState extends State<GyneCareConsultationScreen> {
  late Future<List<DoctorModel>> _doctorsFuture;
  Future<List<BookingModel>>? _myBookingsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isBooking = false;

  // Mobile Razorpay
  late Razorpay _razorpay;

  // Holds booking data while payment is in flight
  BookingModel? _pendingBooking;
  DoctorModel? _pendingDoctor;
  DateTime? _pendingDate;
  String? _pendingTime;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _doctorsFuture = MaaCareBackendService.instance.fetchDoctors();
    _loadBookings();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleMobilePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleMobilePaymentError);
    }
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
  void dispose() {
    _searchController.dispose();
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.dispose();
  }

  // ── Fee helpers ──────────────────────────────────────────────────────────

  int _feePaiseFor(DoctorModel doc) {
    final raw = doc.fee
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim()
        .toLowerCase();
    if (raw == 'free' || raw == '0' || raw.isEmpty) return 0;
    return (int.tryParse(raw) ?? 0) * 100;
  }

  bool _isFree(DoctorModel doc) => _feePaiseFor(doc) == 0;

  // ── Mobile Razorpay callbacks ────────────────────────────────────────────

  void _handleMobilePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted || _pendingBooking == null) return;
    // ✅ Verify payment server-side before confirming booking
    PaymentService.instance.verifyPayment(
      razorpayOrderId: response.orderId ?? _pendingOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    ).then((result) {
      if (!mounted) return;
      if (result.success) {
        _confirmBookingRecord(
          booking: _pendingBooking!,
          doctor: _pendingDoctor!,
          date: _pendingDate!,
          time: _pendingTime!,
        );
      } else {
        setState(() => _isBooking = false);
        ErrorHelper.showError(context, 'Payment could not be verified. Please contact support.');
      }
    });
  }

  void _handleMobilePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isBooking = false);
    ErrorHelper.showError(context, 'Payment failed or cancelled: ${response.message}');
  }

  // ── Unified payment trigger ──────────────────────────────────────────────

  Future<void> _triggerPayment({
    required DoctorModel doctor,
    required BookingModel booking,
    required DateTime date,
    required String time,
    required String userEmail,
  }) async {
    _pendingBooking = booking;
    _pendingDoctor = doctor;
    _pendingDate = date;
    _pendingTime = time;

    if (_isFree(doctor)) {
      _confirmBookingRecord(booking: booking, doctor: doctor, date: date, time: time);
      return;
    }

    setState(() => _isBooking = true);

    // ✅ Step 1: Create order server-side (amount enforced on server)
    final order = await PaymentService.instance.createOrder(
      amountPaise: _feePaiseFor(doctor),
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _isBooking = false);
      ErrorHelper.showError(context, 'Could not initiate payment. Please try again.');
      return;
    }

    final orderId = order['id'] as String? ?? '';
    _pendingOrderId = orderId;

    // ✅ Step 2: Open Razorpay with server-generated order ID
    if (kIsWeb) {
      RazorpayWebService.instance.openCheckout(
        keyId: AppConstants.razorpayKey,
        amount: _feePaiseFor(doctor),
        currency: 'INR',
        name: 'MaaCare Health',
        description: 'GyneCare Consult with ${doctor.name}',
        email: userEmail,
        orderId: orderId,
        phone: '9999999999',
        onSuccess: (paymentId) async {
          if (!mounted) return;
          // Verify server-side before booking
          final result = await PaymentService.instance.verifyPayment(
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: '',
          );
          if (!mounted) return;
          if (result.success) {
            _confirmBookingRecord(booking: booking, doctor: doctor, date: date, time: time);
          } else {
            setState(() => _isBooking = false);
            ErrorHelper.showError(context, 'Payment could not be verified.');
          }
        },
        onFailed: (error) {
          if (!mounted) return;
          setState(() => _isBooking = false);
          ErrorHelper.showError(context, 'Payment failed or cancelled.');
        },
        onDismiss: () {
          if (!mounted) return;
          setState(() => _isBooking = false);
        },
      );
    } else {
      final options = PaymentService.instance.buildCheckoutOptions(
        orderId: orderId,
        amountPaise: _feePaiseFor(doctor),
        description: 'GyneCare Consult with ${doctor.name}',
        userEmail: userEmail,
      );
      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isBooking = false);
        ErrorHelper.showError(context, 'Failed to open payment gateway: $e');
      }
    }
  }

  Future<void> _confirmBookingRecord({
    required BookingModel booking,
    required DoctorModel doctor,
    required DateTime date,
    required String time,
  }) async {
    setState(() => _isBooking = true);
    final success = await MaaCareBackendService.instance.bookAppointment(booking);
    
    if (success && doctor.userId != null) {
      try {
        final user = context.read<UserProvider>().user;
        final doctorUser = await MaaCareBackendService.instance.fetchUser(doctor.userId!);
        if (doctorUser != null &&
            doctorUser.onesignalPlayerId != null &&
            doctorUser.onesignalPlayerId!.isNotEmpty) {
          await PushNotificationService.instance.sendPushViaBackend(
            playerIds: [doctorUser.onesignalPlayerId!],
            title: 'New Patient Booking 🩺',
            body: 'You have a new pending reservation request from ${user?.name ?? "Patient"}.',
            type: 'doctor_consultation_request',
            route: '/doctor_dashboard',
          );
        }
      } catch (e) {
        debugPrint('Failed to send push notification to doctor: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isBooking = false);
    if (success) {
      _showSuccessDialog(doctor, date, time);
    } else {
      ErrorHelper.showError(context, 'Booking failed. Please try again.');
    }
  }

  List<DoctorModel> _filterGyneCareDoctors(List<DoctorModel> all) {
    return all.where((doc) {
      final spec = doc.specialization.toLowerCase();
      final matchesGyne = spec.contains('gynecologist') ||
          spec.contains('gynaecologist') ||
          spec.contains('gynecare') ||
          spec.contains('obstetrician') ||
          spec.contains('obstetrics') ||
          spec.contains('women\'s health') ||
          spec.contains('women') ||
          spec.contains('gyn');

      final matchesSearch = _searchQuery.isEmpty ||
          doc.name.toLowerCase().contains(_searchQuery) ||
          doc.specialization.toLowerCase().contains(_searchQuery);

      return matchesGyne && matchesSearch;
    }).toList();
  }

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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: activeBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final booking = activeBookings[index];
                      final doctor = doctors.firstWhere(
                        (d) => d.id == booking.doctorId,
                        orElse: () => DoctorModel(
                          id: booking.doctorId,
                          name: 'Consulting Doctor',
                          specialization: 'GyneCare Specialist',
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
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().user;
    return Scaffold(
      backgroundColor: MaaColors.background,
      body: Stack(
        children: [
          // Background Glows
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
                    MaaColors.pink.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LoadingOverlay(
              isLoading: _isBooking,
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildSearchBar(),
                  if (user != null) _buildMyBookingsSection(),
                  Expanded(
                    child: FutureBuilder<List<DoctorModel>>(
                      future: _doctorsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: MaaColors.pink),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load doctors: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        final filtered = _filterGyneCareDoctors(snapshot.data ?? []);

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('👩‍⚕️', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text(
                                  'No GyneCare Specialists found',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try updating your search query',
                                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            return _buildDoctorCard(doc);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GyneCare Consultations',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Confidential, Peer-Reviewed Expert Care',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MaaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name or specialization...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
          filled: true,
          fillColor: MaaColors.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doc) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doc)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: MaaColors.pink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    doc.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (doc.isVerified)
                          const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.specialization,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: MaaColors.pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          doc.rating,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.work_outline, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${doc.experience} exp',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            doc.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white60,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee: ${doc.fee}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MaaColors.pink,
                      side: const BorderSide(color: MaaColors.pink, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doc)),
                    ),
                    child: Text(
                      'Profile',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaaColors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => _openBookingDialog(doc),
                    child: Text(
                      'Book Consult',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _openBookingDialog(DoctorModel doctor) {
    final user = context.read<UserProvider>().user;
    final menstrual = context.read<MenstrualProvider>();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a consultation.'), backgroundColor: Colors.red),
      );
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final notesController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:00 AM';

    final hasRedSymptom = menstrual.loggedSymptoms.any(
      (s) => ['Extreme Pain', 'Heavy Hemorrhage', 'Persistent Vomiting', 'Fainting'].contains(s),
    );
    final triageRisk = hasRedSymptom ? 'CRITICAL (Red Zone Symptoms logged)' : 'Standard GyneCare Review';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaaColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Book GyneCare Consult',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'with ${doctor.name}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: MaaColors.pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Triage Brief
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasRedSymptom ? Colors.red.withValues(alpha: 0.1) : MaaColors.pink.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasRedSymptom ? Colors.red.withValues(alpha: 0.3) : MaaColors.pink.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasRedSymptom ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                color: hasRedSymptom ? Colors.redAccent : MaaColors.pink,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Digital Triage Briefing',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hasRedSymptom ? Colors.redAccent : MaaColors.pink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cycle Phase: ${menstrual.cyclePhase}',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Symptoms: ${menstrual.loggedSymptoms.isEmpty ? "None logged" : menstrual.loggedSymptoms.join(", ")}',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Triage Vector: $triageRisk',
                            style: GoogleFonts.outfit(
                              color: hasRedSymptom ? Colors.redAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Patient Name input
                    Text(
                      'Patient Full Name',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: MaaColors.pink,
                                            onPrimary: Colors.white,
                                            surface: MaaColors.cardDark,
                                            onSurface: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedDate == null
                                            ? 'Choose Date'
                                            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, color: Colors.white60, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Slot',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedTime,
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.3),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '09:00 AM', child: Text('09:00 AM')),
                                  DropdownMenuItem(value: '10:30 AM', child: Text('10:30 AM')),
                                  DropdownMenuItem(value: '02:00 PM', child: Text('02:00 PM')),
                                  DropdownMenuItem(value: '04:30 PM', child: Text('04:30 PM')),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setSheetState(() => selectedTime = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes input
                    Text(
                      'Reason / Additional Symptoms',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Any other issues you would like to report in absolute confidence...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MaaColors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter patient name'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          if (selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select an appointment date'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          Navigator.pop(context); // Close booking sheet

                          final bundledSymptoms = '''
Time Slot: $selectedTime
Cycle Phase: ${menstrual.cyclePhase}
Logged Symptoms: ${menstrual.loggedSymptoms.join(', ')}
Triage Vector: $triageRisk
Notes: ${notesController.text.trim()}
''';

                          final booking = BookingModel(
                            id: '',
                            userId: user.id,
                            doctorId: doctor.id,
                            patientName: nameController.text.trim(),
                            symptoms: bundledSymptoms,
                            appointmentDate: selectedDate!,
                            status: 'scheduled',
                            paymentStatus: _isFree(doctor) ? 'free' : 'paid',
                            meetingLink: '',
                            amount: _isFree(doctor) ? '₹0 (Free)' : doctor.fee,
                            userRole: 'unmarried_girl',
                            createdAt: DateTime.now(),
                          );

                          _triggerPayment(
                            doctor: doctor,
                            booking: booking,
                            date: selectedDate!,
                            time: selectedTime,
                            userEmail: user.email ?? '',
                          );
                        },
                        child: Text(
                          _isFree(doctor)
                              ? 'Book FREE Consultation 🎁'
                              : 'Pay ${doctor.fee} & Confirm 💳',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(DoctorModel doctor, DateTime date, String time) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MaaColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: MaaColors.success, size: 28),
              SizedBox(width: 10),
              Text('Booking Confirmed', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Your private consultation with ${doctor.name} has been successfully scheduled for ${date.day}/${date.month}/${date.year} at $time.\n\nA secure video consulting link will be available in your profile dashboard shortly. 🌸',
            style: GoogleFonts.outfit(color: Colors.white70, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: MaaColors.pink, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to dashboard
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        );
      },
    );
  }
}

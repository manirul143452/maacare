// ============================================================
//  BookingCheckoutSheet – MaaCare v3
//  High-fidelity glassmorphic doctor booking sheet
//  Real Razorpay integration (Web + Mobile)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../app_theme.dart';
import '../constants.dart';
import '../models/doctor_model.dart';
import '../models/booking_model.dart';
import '../providers/user_provider.dart';
import '../services/maacare_backend_service.dart';
import '../services/push_notification_service.dart';
import '../services/razorpay_web_service.dart';
import '../services/payment_service.dart';
import '../utils/error_helper.dart';
import 'maa_button.dart';

class BookingCheckoutSheet extends StatefulWidget {
  final DoctorModel doctor;

  const BookingCheckoutSheet({super.key, required this.doctor});

  static void show(BuildContext context, DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingCheckoutSheet(doctor: doctor),
    );
  }

  @override
  State<BookingCheckoutSheet> createState() => _BookingCheckoutSheetState();
}

class _BookingCheckoutSheetState extends State<BookingCheckoutSheet> {
  // Booking details
  late DateTime _selectedDate;
  DateTime? _selectedSlot;
  List<DateTime> _availableSlots = [];

  // Triage configuration
  String _selectedTriageColor = 'green'; // 'green', 'yellow', 'red'

  bool _isProcessingPayment = false;
  bool _paymentSuccess = false;

  // Mobile Razorpay instance
  late Razorpay _razorpay;
  String? _pendingOrderId;

  // ── Fee helpers ─────────────────────────────────────────────────────────────

  /// Parses doctor.fee string (e.g. "₹500", "500", "₹0", "Free") → int (paise)
  int get _feePaise {
    final raw = widget.doctor.fee
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim()
        .toLowerCase();
    if (raw == 'free' || raw == '0' || raw.isEmpty) return 0;
    final parsed = int.tryParse(raw) ?? 0;
    return parsed * 100; // Convert ₹ to paise
  }

  bool get _isFree => _feePaise == 0;

  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _generateSlotsForSelectedDate();

    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleMobilePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleMobilePaymentError);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.dispose();
  }

  void _generateSlotsForSelectedDate() {
    final doc = widget.doctor;
    final date = _selectedDate;

    final startParts = doc.dailyStartTime.split(':');
    final endParts = doc.dailyEndTime.split(':');

    final startHour = startParts.isNotEmpty ? int.parse(startParts[0]) : 9;
    final startMin = startParts.length > 1 ? int.parse(startParts[1]) : 0;
    final endHour = endParts.isNotEmpty ? int.parse(endParts[0]) : 17;
    final endMin = endParts.length > 1 ? int.parse(endParts[1]) : 0;

    final startTime = DateTime(date.year, date.month, date.day, startHour, startMin);
    final endTime = DateTime(date.year, date.month, date.day, endHour, endMin);

    final List<DateTime> slots = [];
    var current = startTime;
    while (current.isBefore(endTime)) {
      slots.add(current);
      current = current.add(Duration(minutes: doc.slotDurationMinutes));
    }

    setState(() {
      _availableSlots = slots;
      _selectedSlot = slots.isNotEmpty ? slots.first : null;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: MaaColors.pink,
              onPrimary: Colors.white,
              surface: MaaColors.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _generateSlotsForSelectedDate();
    }
  }

  // ── Razorpay payment handlers ─────────────────────────────────────────────

  void _handleMobilePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    PaymentService.instance.verifyPayment(
      razorpayOrderId: response.orderId ?? _pendingOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    ).then((result) {
      if (!mounted) return;
      if (result.success) {
        _proceedToCreateSession(
          orderId: response.orderId ?? _pendingOrderId ?? '',
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
        );
      } else {
        setState(() => _isProcessingPayment = false);
        ErrorHelper.showError(context, 'Payment could not be verified. Please contact support.');
      }
    });
  }

  void _handleMobilePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessingPayment = false);
    ErrorHelper.showError(context, 'Payment failed or cancelled: ${response.message}');
  }

  /// Triggered once payment is confirmed (or free booking).
  Future<void> _proceedToCreateSession({String? orderId, String? paymentId, String? signature}) async {
    try {
      final user = context.read<UserProvider>().user;
      if (user == null) throw Exception('User authentication context is missing.');

      final bundledSymptoms = '''
Time Slot: ${DateFormat('h:mm a').format(_selectedSlot!)}
Triage Vector: ${_selectedTriageColor.toUpperCase()}
''';

      final booking = BookingModel(
        id: '', // DB generates UUID
        userId: user.id,
        doctorId: widget.doctor.id,
        patientName: user.name,
        symptoms: bundledSymptoms,
        appointmentDate: _selectedSlot!,
        status: 'scheduled',
        paymentStatus: _isFree ? 'free' : 'paid',
        meetingLink: '',
        amount: _isFree ? '₹0 (Free)' : widget.doctor.fee,
        userRole: user.userRole,
        createdAt: DateTime.now(),
      );

      final success = await MaaCareBackendService.instance.bookAppointment(booking);
      if (!success) {
        throw Exception('Server failed to save appointment.');
      }

      // Notify doctor via push
      if (widget.doctor.userId != null) {
        final doctorUser = await MaaCareBackendService.instance.fetchUser(widget.doctor.userId!);
        if (doctorUser != null &&
            doctorUser.onesignalPlayerId != null &&
            doctorUser.onesignalPlayerId!.isNotEmpty) {
          await PushNotificationService.instance.sendPushViaBackend(
            playerIds: [doctorUser.onesignalPlayerId!],
            title: 'New Patient Booking 🩺',
            body: 'You have a new pending reservation request from ${user.name}.',
            type: 'doctor_consultation_request',
            route: '/doctor_dashboard',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
        _paymentSuccess = true;
      });

      await Future.delayed(2.seconds);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reservation confirmed for ${DateFormat('EEE, MMM d @ h:mm a').format(_selectedSlot!)} 🎉',
            ),
            backgroundColor: MaaColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ErrorHelper.showError(context, 'Booking Error: ${e.toString()}');
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available consultation slot.')),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    // ── FREE path ────────────────────────────────────────────────────────────
    if (_isFree) {
      await _proceedToCreateSession();
      return;
    }

    // ── PAID path ────────────────────────────────────────────────────────────
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() => _isProcessingPayment = false);
      ErrorHelper.showError(context, 'Please log in to book appointments.');
      return;
    }

    // ✅ Step 1: Create order server-side
    final order = await PaymentService.instance.createOrder(
      amountPaise: _feePaise,
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _isProcessingPayment = false);
      ErrorHelper.showError(context, 'Could not initiate payment. Please try again.');
      return;
    }
    final orderId = order['id'] as String? ?? '';

    // ✅ Step 2: Open Razorpay with server-generated order ID
    if (kIsWeb) {
      RazorpayWebService.instance.openCheckout(
        keyId: AppConstants.razorpayKey,
        amount: _feePaise,
        currency: 'INR',
        name: 'MaaCare Health',
        description: 'Consultation with ${widget.doctor.name}',
        email: user.email,
        orderId: orderId,
        phone: '9999999999',
        onSuccess: (paymentId) async {
          if (!mounted) return;
          // Verify payment server-side before booking
          final result = await PaymentService.instance.verifyPayment(
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: '',
          );
          if (!mounted) return;
          if (result.success) {
            _proceedToCreateSession(orderId: orderId, paymentId: paymentId);
          } else {
            setState(() => _isProcessingPayment = false);
            ErrorHelper.showError(context, 'Payment could not be verified.');
          }
        },
        onFailed: (error) {
          if (!mounted) return;
          setState(() => _isProcessingPayment = false);
          ErrorHelper.showError(context, 'Payment failed or cancelled.');
        },
        onDismiss: () {
          if (!mounted) return;
          setState(() => _isProcessingPayment = false);
        },
      );
    } else {
      _pendingOrderId = orderId;
      final options = PaymentService.instance.buildCheckoutOptions(
        orderId: orderId,
        amountPaise: _feePaise,
        description: 'Consultation with ${widget.doctor.name}',
        userEmail: user.email ?? '',
      );
      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isProcessingPayment = false);
        ErrorHelper.showError(context, 'Failed to open payment gateway: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: MaaColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + keyboardSpace,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _paymentSuccess ? _buildSuccessState() : _buildCheckoutFlow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle_rounded, color: MaaColors.successGlow, size: 80)
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut)
            .shimmer(delay: 600.ms, duration: 1.seconds),
        const SizedBox(height: 20),
        Text(
          _isFree ? 'Booking Confirmed!' : 'Payment Successful!',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Your appointment is registered as pending approval. We have alerted the doctor.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54, height: 1.4),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCheckoutFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Doctor Header Card
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: MaaColors.pink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.doctor.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctor.name,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    widget.doctor.specialization,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (_isFree ? MaaColors.success : MaaColors.pink).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isFree ? 'FREE' : widget.doctor.fee,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _isFree ? MaaColors.success : MaaColors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Date Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Date:',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            TextButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month_rounded, color: MaaColors.pink, size: 18),
              label: Text(
                DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                style: GoogleFonts.poppins(color: MaaColors.pink, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dynamic Slot Grid
        Text(
          'Select Time Slot (20-min increments):',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
        ),
        const SizedBox(height: 10),
        _availableSlots.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No available slots on this day.',
                    style: GoogleFonts.poppins(color: Colors.white38),
                  ),
                ),
              )
            : SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableSlots.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final slot = _availableSlots[index];
                    final isSelected = _selectedSlot != null &&
                        _selectedSlot!.hour == slot.hour &&
                        _selectedSlot!.minute == slot.minute;

                    return ChoiceChip(
                      label: Text(DateFormat('h:mm a').format(slot)),
                      selected: isSelected,
                      selectedColor: MaaColors.pink,
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? MaaColors.pink : Colors.white12,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedSlot = slot);
                        }
                      },
                    );
                  },
                ),
              ),
        const SizedBox(height: 24),

        // Triage Priority Flag Selector
        Text(
          'Select Booking Triage Priority:',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTriageChip('green', 'Low Risk', Colors.green),
            const SizedBox(width: 8),
            _buildTriageChip('yellow', 'Medium Concern', Colors.amber),
            const SizedBox(width: 8),
            _buildTriageChip('red', 'Critical Emergency', Colors.red),
          ],
        ),
        const SizedBox(height: 28),

        // Razorpay Payment Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MaaColors.pink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MaaColors.pink.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: MaaColors.pink, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isFree ? 'Free Consultation' : 'Secured by Razorpay',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isFree
                          ? 'No payment required for this appointment.'
                          : 'UPI, Cards, Netbanking & Wallets accepted. SSL Encrypted.',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              if (!_isFree)
                Image.network(
                  'https://razorpay.com/favicon.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.payment_rounded,
                    color: MaaColors.pink,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        MaaButton(
          label: _isProcessingPayment
              ? 'Processing...'
              : _isFree
                  ? 'Confirm Free Appointment 🎁'
                  : 'Pay ${widget.doctor.fee} & Confirm 💳',
          isLoading: _isProcessingPayment,
          onPressed: _submitBooking,
        ),
      ],
    );
  }

  Widget _buildTriageChip(String colorCode, String label, Color dotColor) {
    final isSelected = _selectedTriageColor == colorCode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTriageColor = colorCode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? dotColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? dotColor : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

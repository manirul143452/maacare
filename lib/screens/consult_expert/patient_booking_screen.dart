import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../constants.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../services/maacare_backend_service.dart';
import 'package:flutter/foundation.dart';
import '../../services/razorpay_web_service.dart';
import '../../services/payment_service.dart';
import '../../utils/error_helper.dart';
import '../../widgets/maa_button.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/push_notification_service.dart';
import '../home/widgets/submit_report_sheet.dart';

class PatientBookingScreen extends StatefulWidget {
  final DoctorModel doctor;

  const PatientBookingScreen({super.key, required this.doctor});

  @override
  State<PatientBookingScreen> createState() => _PatientBookingScreenState();
}

class _PatientBookingScreenState extends State<PatientBookingScreen> {
  int _currentStep = 0; // 0 = Details, 1 = Slot Selection
  bool _processing = false;

  final _formKey = GlobalKey<FormState>();

  // Patient Vitals
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();
  String _selectedGender = 'Female';

  // Slot Selection
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _uploadedReportUrl;

  // Strict allowed times
  final List<String> _allowedTimes = [
    '06:00 AM',
    '07:00 AM',
    '08:00 AM',
    '09:00 AM'
  ];

  late Razorpay _razorpay;
  String? _pendingOrderId;

  // ── Fee helpers ─────────────────────────────────────────────────────────────

  /// Parses doctor.fee string (e.g. "₹500", "500", "₹0", "Free") → int (paise for Razorpay)
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

  String get _feeDisplayLabel => _isFree ? 'FREE' : widget.doctor.fee;

  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleMobilePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleMobilePaymentError);
    }
  }

  void _handleMobilePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    // ✅ Verify payment server-side before allowing slot booking
    PaymentService.instance.verifyPayment(
      razorpayOrderId: response.orderId ?? _pendingOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    ).then((result) {
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _processing = false;
          _currentStep = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Please schedule your slot. ✅'),
            backgroundColor: MaaColors.success,
          ),
        );
      } else {
        setState(() => _processing = false);
        ErrorHelper.showError(context, 'Payment could not be verified. Please contact support.');
      }
    });
  }

  void _handleMobilePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _processing = false);
    ErrorHelper.showError(
        context, 'Payment failed or cancelled: ${response.message}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.dispose();
  }

  /// Main entry: either skip payment (free) or open Razorpay.
  void _triggerPaymentOrBook() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<UserProvider>().user;
    if (user == null) {
      ErrorHelper.showError(context, 'Please log in to book appointments.');
      return;
    }

    // ── FREE path ─────────────────────────────────────────────────────────
    if (_isFree) {
      setState(() {
        _processing = false;
        _currentStep = 1; // Go directly to slot selection
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free consultation! Please choose your slot. 🎁'),
          backgroundColor: MaaColors.success,
        ),
      );
      return;
    }

    // ── PAID path ─────────────────────────────────────────────────────────
    setState(() => _processing = true);

    // ✅ Step 1: Create order server-side (amount enforced by server)
    final order = await PaymentService.instance.createOrder(
      amountPaise: _feePaise,
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _processing = false);
      ErrorHelper.showError(context, 'Could not initiate payment. Please try again.');
      return;
    }
    final orderId = order['id'] as String? ?? '';
    _pendingOrderId = orderId;

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
          final result = await PaymentService.instance.verifyPayment(
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: '',
          );
          if (!mounted) return;
          if (result.success) {
            setState(() { _processing = false; _currentStep = 1; });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment Successful! Please schedule your slot. ✅'),
                backgroundColor: MaaColors.success,
              ),
            );
          } else {
            setState(() => _processing = false);
            ErrorHelper.showError(context, 'Payment could not be verified.');
          }
        },
        onFailed: (error) {
          if (!mounted) return;
          setState(() => _processing = false);
          ErrorHelper.showError(context, 'Payment failed or cancelled.');
        },
        onDismiss: () {
          if (!mounted) return;
          setState(() => _processing = false);
        },
      );
    } else {
      final options = PaymentService.instance.buildCheckoutOptions(
        orderId: orderId,
        amountPaise: _feePaise,
        description: 'Consultation with ${widget.doctor.name}',
        userEmail: user.email ?? '',
      );
      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _processing = false);
        ErrorHelper.showError(context, 'Failed to open payment gateway: $e');
      }
    }
  }

  void _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ErrorHelper.showError(
          context, 'Please select both Date and Time constraints.');
      return;
    }

    setState(() => _processing = true);

    final user = context.read<UserProvider>().user;

    // Bundle vitals safely into symptoms payload to avoid schema migration overhead
    final bundledSymptoms = '''
[Patient Profile]
Age: ${_ageController.text.trim()} yrs
Gender: $_selectedGender
Height: ${_heightController.text.trim()} cm
Weight: ${_weightController.text.trim()} kg
${_uploadedReportUrl != null ? "Clinical Report: Attached (See Patient Reports tab)\n" : ""}
[Symptoms / Reason]
${_symptomsController.text.trim()}
    ''';

    final booking = BookingModel(
      id: '', // Generated by backend
      userId: user!.id,
      doctorId: widget.doctor.id,
      patientName: _nameController.text.trim(),
      symptoms: '$_selectedTime\n\n${bundledSymptoms.trim()}',
      appointmentDate: _selectedDate!,
      status: 'scheduled',
      paymentStatus: _isFree ? 'free' : 'paid',
      meetingLink: '',
      amount: _isFree ? '₹0 (Free)' : widget.doctor.fee,
      createdAt: DateTime.now(),
    );

    final success = await MaaCareBackendService.instance.bookAppointment(booking);

    if (success && widget.doctor.userId != null) {
      try {
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
      } catch (e) {
        debugPrint('Failed to send push notification to doctor: $e');
      }
    }

    if (!mounted) return;
    setState(() => _processing = false);

    if (success) {
      // Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: MaaColors.cardDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _isFree ? '🎁 Free Consultation Booked!' : '🎉 Appointment Confirmed',
            style: const TextStyle(color: MaaColors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your consultation with ${widget.doctor.name} is confirmed for $_selectedTime on ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}.',
                style: const TextStyle(color: MaaColors.textMuted),
              ),
              if (_isFree) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MaaColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: MaaColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volunteer_activism,
                          color: MaaColors.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a FREE consultation provided by the doctor.',
                          style: TextStyle(
                              color: MaaColors.success, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'A secure Video Meeting link will be generated shortly.',
                style: TextStyle(color: MaaColors.textGrey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back out to consult list
              },
              child: const Text('Return to Dashboard',
                  style: TextStyle(color: MaaColors.pink)),
            )
          ],
        ),
      );
    } else {
      ErrorHelper.showError(
          context, 'Failed to save appointment. Please contact support.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Patient Details' : 'Select Slot'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Doctor Fee Badge ─────────────────────────────────────────
              _buildDoctorFeeBadge(),
              const SizedBox(height: 20),

              // ── Step Indicator ───────────────────────────────────────────
              Row(
                children: [
                  _buildStepIndicator(
                      0, _isFree ? 'Details' : 'Details & Payment'),
                  Expanded(
                      child: Container(
                          height: 2,
                          color: _currentStep > 0
                              ? MaaColors.pink
                              : MaaColors.textGrey.withValues(alpha: 0.2))),
                  _buildStepIndicator(1, 'Pick Slot 🗓️'),
                ],
              ),
              const SizedBox(height: 32),

              if (_currentStep == 0)
                _buildDetailsForm()
              else
                _buildSlotSelection(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Doctor Fee Badge Widget ────────────────────────────────────────────────
  Widget _buildDoctorFeeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isFree
              ? [
                  MaaColors.success.withValues(alpha: 0.15),
                  MaaColors.success.withValues(alpha: 0.05),
                ]
              : [
                  MaaColors.pink.withValues(alpha: 0.15),
                  MaaColors.pink.withValues(alpha: 0.05),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFree
              ? MaaColors.success.withValues(alpha: 0.5)
              : MaaColors.pink.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                _isFree ? MaaColors.success.withValues(alpha: 0.2) : MaaColors.pink.withValues(alpha: 0.2),
            child: Text(
              widget.doctor.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: GoogleFonts.poppins(
                    color: MaaColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  widget.doctor.specialization,
                  style: const TextStyle(
                      color: MaaColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Fee pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isFree ? MaaColors.success : MaaColors.pink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFree
                      ? Icons.volunteer_activism
                      : Icons.currency_rupee,
                  color: MaaColors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _feeDisplayLabel,
                  style: GoogleFonts.poppins(
                    color: MaaColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? MaaColors.pink : MaaColors.cardDark,
            border: Border.all(
                color: isActive ? Colors.transparent : MaaColors.pink),
          ),
          child: Center(
            child: Icon(
              stepIndex == 0 ? Icons.person : Icons.access_time_rounded,
              size: 16,
              color: isActive ? MaaColors.white : MaaColors.pink,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? MaaColors.white : MaaColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Patient Information',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MaaColors.white)),
          const SizedBox(height: 20),
          _buildTextField(_nameController, 'Full Name', Icons.person),
          _buildTextField(_ageController, 'Age', Icons.cake, isNumber: true),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              items: ['Female', 'Male', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v!),
              decoration: InputDecoration(
                labelText: 'Gender',
                labelStyle: const TextStyle(color: MaaColors.textMuted),
                prefixIcon: const Icon(Icons.wc, color: MaaColors.pink),
                filled: true,
                fillColor: MaaColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: MaaColors.background,
              style: const TextStyle(color: MaaColors.white),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: _buildTextField(_heightController, 'Height (cm)',
                    Icons.height,
                    isNumber: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(_weightController, 'Weight (kg)',
                    Icons.monitor_weight,
                    isNumber: true),
              ),
            ],
          ),

          _buildTextField(_symptomsController, 'Reasons / Symptoms',
              Icons.medical_services,
              maxLines: 3),

          const SizedBox(height: 16),
          _buildReportUploadSection(),

          const SizedBox(height: 32),

          // ── Smart CTA button ─────────────────────────────────────────────
          if (_isFree)
            _buildFreeBookingButton()
          else
            _buildPaidBookingButton(),

          const SizedBox(height: 12),

          // ── Footer note ──────────────────────────────────────────────────
          Center(
            child: Text(
              _isFree
                  ? '🎁 This doctor offers free consultations'
                  : 'Secured by Razorpay. SSL Encrypted 🔒',
              style:
                  const TextStyle(color: MaaColors.textGrey, fontSize: 12),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  /// Green "Book FREE" button
  Widget _buildFreeBookingButton() {
    return GestureDetector(
      onTap: _processing ? null : _triggerPaymentOrBook,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: MaaColors.success.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volunteer_activism,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Book FREE Consultation 🎁',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pink "Proceed to Payment" button
  Widget _buildPaidBookingButton() {
    return MaaButton(
      label: 'Proceed to Payment (${widget.doctor.fee})',
      icon: Icons.lock_rounded,
      isLoading: _processing,
      onPressed: _triggerPaymentOrBook,
    );
  }

  Widget _buildSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Secure a Consultation Slot',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: MaaColors.white)),
        const SizedBox(height: 4),
        const Text(
            'Doctor available between 6:00 AM - 9:00 AM.',
            style: TextStyle(color: MaaColors.textGrey, fontSize: 13)),
        const SizedBox(height: 24),

        // Date Picker Request
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 30)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: MaaColors.pink,
                      onPrimary: MaaColors.white,
                      surface: MaaColors.cardDark,
                      onSurface: MaaColors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MaaColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: MaaColors.pink.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: MaaColors.pink),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? 'Tap to select Date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(
                    color: _selectedDate == null
                        ? MaaColors.textMuted
                        : MaaColors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Text('Select Time',
            style: TextStyle(
                color: MaaColors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _allowedTimes.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = time),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? MaaColors.pink : MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? MaaColors.pink
                        : MaaColors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? MaaColors.white : MaaColors.textMuted,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 48),

        MaaButton(
          label: 'Confirm Final Booking',
          icon: Icons.check_circle_rounded,
          isLoading: _processing,
          onPressed: _confirmBooking,
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildReportUploadSection() {
    final hasReport = _uploadedReportUrl != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasReport ? MaaColors.success.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clinical/Hormonal Lab Report',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (hasReport)
                const Icon(Icons.check_circle, color: MaaColors.success, size: 20)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Optional',
                    style: GoogleFonts.outfit(color: MaaColors.textMuted, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasReport
                ? 'Clinical report uploaded successfully. It will be shared with the doctor.'
                : 'Share your blood test, TSH, or hormonal health panel scan for accurate triage.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: hasReport ? Colors.white70 : MaaColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: hasReport ? MaaColors.success : MaaColors.pink,
                side: BorderSide(
                  color: hasReport ? MaaColors.success.withValues(alpha: 0.4) : MaaColors.pink.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(hasReport ? Icons.edit_document : Icons.cloud_upload_outlined),
              label: Text(
                hasReport ? 'Change Lab Report' : 'Upload Lab Report',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                final user = context.read<UserProvider>().user;
                if (user == null) {
                  ErrorHelper.showError(context, 'Please log in first.');
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: SubmitReportSheet(
                      patientId: user.id,
                      doctorId: widget.doctor.id,
                      onReportUploaded: (url) {
                        setState(() {
                          _uploadedReportUrl = url;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: MaaColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: MaaColors.textMuted),
          prefixIcon: Icon(icon, color: MaaColors.pink),
          filled: true,
          fillColor: MaaColors.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MaaColors.pink),
          ),
        ),
        validator: (v) => v!.isEmpty ? 'Field required' : null,
      ),
    );
  }
}

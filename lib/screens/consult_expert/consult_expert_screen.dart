// ============================================================
//  Consult Expert Screen – MaaCare
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../constants.dart';
import '../../widgets/maa_button.dart';

class ConsultExpertScreen extends StatelessWidget {
  const ConsultExpertScreen({super.key});

  static const List<Map<String, String>> _doctors = [
    {
      'name': 'Dr. Priya Sharma',
      'spec': 'Obstetrician & Gynecologist',
      'exp': '15 yrs',
      'rating': '4.9',
      'fee': '₹500',
      'emoji': '👩‍⚕️',
      'available': 'Today 3PM – 7PM',
    },
    {
      'name': 'Dr. Sunita Rao',
      'spec': 'Maternal Fetal Medicine',
      'exp': '12 yrs',
      'rating': '4.8',
      'fee': '₹700',
      'emoji': '🩺',
      'available': 'Today 5PM – 9PM',
    },
    {
      'name': 'Dr. Meera Joshi',
      'spec': 'Lactation Consultant',
      'exp': '8 yrs',
      'rating': '4.7',
      'fee': '₹400',
      'emoji': '🌸',
      'available': 'Tomorrow 10AM',
    },
    {
      'name': 'Dr. Ananya Gupta',
      'spec': 'Pediatrician',
      'exp': '10 yrs',
      'rating': '4.9',
      'fee': '₹450',
      'emoji': '👶',
      'available': 'Today 6PM – 8PM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consult Expert 👩‍⚕️')),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
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
                      color: MaaColors.white.withAlpha(200),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          // Web platform warning
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(12),
              color: MaaColors.warning.withAlpha(30),
              child: const Row(
                children: [
                  Text('ℹ️'),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payments are available on Android/iOS app only',
                      style: TextStyle(fontSize: 12, color: MaaColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _doctors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _DoctorCard(
                doctor: _doctors[i],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _DoctorCard extends StatelessWidget {
  final Map<String, String> doctor;
  const _DoctorCard({required this.doctor});

  void _bookConsultation(BuildContext context) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Payments available on Android/iOS app. Download MaaCare! 📱')),
      );
      return;
    }

    // Show booking confirmation sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(doctor: doctor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: MaaColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(doctor['emoji']!,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor['name']!,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(doctor['spec']!,
                        style: const TextStyle(
                            fontSize: 12, color: MaaColors.textGrey)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: MaaColors.gold, size: 14),
                        Text(' ${doctor['rating']!}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(' · ${doctor['exp']!} exp',
                            style: const TextStyle(
                                fontSize: 12, color: MaaColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                doctor['fee']!,
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
                Text('Available: ${doctor['available']!}',
                    style: const TextStyle(
                        fontSize: 12, color: MaaColors.success)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MaaButton(
            label: kIsWeb
                ? 'Download App to Book'
                : 'Book Video Consult 📞',
            onPressed: () => _bookConsultation(context),
          ),
        ],
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final Map<String, String> doctor;
  const _BookingSheet({required this.doctor});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  bool _processing = false;

  void _pay() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 1));

    // In real app: instantiate Razorpay with AppConstants.razorpayKey
    // and launch payment options. Razorpay-specific code is conditionally
    // compiled via kIsWeb check in the widget tree above.

    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Appointment booked with ${widget.doctor['name']!}! 🎉 Check your email.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Book with ${widget.doctor['name']!}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(widget.doctor['available']!,
              style: const TextStyle(
                  fontSize: 13, color: MaaColors.textGrey)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoChip('🩺 Video Call', MaaColors.pink),
              _InfoChip('⏱ 30 min', MaaColors.peach),
              _InfoChip(widget.doctor['fee']!, MaaColors.gold),
            ],
          ),
          const SizedBox(height: 20),
          MaaButton(
            label: 'Pay & Confirm ${widget.doctor['fee']!}',
            isLoading: _processing,
            onPressed: _pay,
            icon: Icons.payment_rounded,
          ),
          const SizedBox(height: 8),
          const Text('Secured by Razorpay 🔒',
              style: TextStyle(fontSize: 11, color: MaaColors.textGrey)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

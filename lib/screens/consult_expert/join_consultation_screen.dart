import 'package:flutter/material.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import '../../app_theme.dart';
import '../../models/booking_model.dart';
import '../../services/maacare_backend_service.dart';

class JoinConsultationScreen extends StatefulWidget {
  final BookingModel appointment;
  final String roomCode;
  final String userName;

  const JoinConsultationScreen({
    super.key,
    required this.appointment,
    required this.roomCode,
    required this.userName,
  });

  @override
  State<JoinConsultationScreen> createState() => _JoinConsultationScreenState();
}

class _JoinConsultationScreenState extends State<JoinConsultationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: Text('Consultation: ${widget.appointment.patientName}'),
        backgroundColor: MaaColors.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleCallEnded(),
        ),
      ),
      body: HMSPrebuilt(
        roomCode: widget.roomCode,
        onLeave: () => _handleCallEnded(),
        options: HMSPrebuiltOptions(
          userName: widget.userName,
        ),
      ),
    );
  }

  void _handleCallEnded() async {
    // Mark appointment as 'completed' in backend
    try {
      await MaaCareBackendService.instance.updateAppointmentStatus(
        widget.appointment.id,
        'completed',
      );
    } catch (e) {
      debugPrint('Failed to mark complete: $e');
    }

    if (!mounted) return;

    // Pop the HMS screen if it pushed itself
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: MaaColors.cardDark,
        title: const Text('Consultation Finished', style: TextStyle(color: MaaColors.white)),
        content: const Text(
          'Thank you for using MaaCare. Your consultation summary will be updated shortly.',
          style: TextStyle(color: MaaColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Close dialog then navigate cleanly home — removes all screens from stack
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            child: const Text('Back to Home', style: TextStyle(color: MaaColors.pink)),
          )
        ],
      ),
    );
  }
}

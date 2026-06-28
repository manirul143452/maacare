import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import '../../app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/doctor_model.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import '../../services/maacare_backend_service.dart';
import '../../services/push_notification_service.dart';
import '../../utils/permission_helper.dart';

class DoctorChatView extends StatefulWidget {
  final BookingModel appointment;
  final DoctorModel doctor;

  const DoctorChatView({
    super.key,
    required this.appointment,
    required this.doctor,
  });

  @override
  State<DoctorChatView> createState() => _DoctorChatViewState();
}

class _DoctorChatViewState extends State<DoctorChatView> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final _uuid = const Uuid();

  String? _conversationId;
  String? _sessionId;
  String? _activeRoomCode; // Unique per-session room code (not hardcoded)
  bool _isLoading = true;
  bool _isSavingPrescription = false;
  bool _isVideoActive = false;

  @override
  void initState() {
    super.initState();
    _initConsultation();
  }

  @override
  void dispose() {
    _isVideoActive = false;
    _messageController.dispose();
    _prescriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initConsultation() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load or create chat conversation
      final convs = await MaaCareBackendService.instance.fetchConversations(widget.appointment.userId);
      final chatTitle = 'Consultation: Dr. ${widget.doctor.name}';
      
      final conv = convs.firstWhere(
        (c) => c.title.contains('Consultation'),
        orElse: () => ConversationModel(
          id: '',
          userId: '',
          title: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );

      if (conv.id.isNotEmpty) {
        _conversationId = conv.id;
      } else {
        final newId = _uuid.v4();
        final newConv = ConversationModel(
          id: newId,
          userId: widget.appointment.userId,
          title: chatTitle,
          createdAt: DateTime.now(),
        );
        await MaaCareBackendService.instance.createConversation(newConv);
        _conversationId = newId;
      }

      await _loadChatMessages();

      // 2. Fetch or create consultation session log
      final session = await MaaCareBackendService.instance.fetchConsultationSession(
        widget.doctor.id,
        widget.appointment.userId,
      );

      if (session != null) {
        _sessionId = session['id'];
        _activeRoomCode = session['room_id'] as String?; // Load existing room code if call was already started
        _prescriptionController.text = session['prescription_text'] ?? '';
      } else {
        // Create new session entry
        final newSessionPayload = {
          'id': _uuid.v4(),
          'doctor_id': widget.doctor.id,
          'patient_id': widget.appointment.userId,
          'patient_role': widget.appointment.userRole ?? 'mother',
          'scheduled_time': widget.appointment.appointmentDate.toIso8601String(),
          'status': 'pending',
          'prescription_text': '',
        };
        final created = await MaaCareBackendService.instance.createConsultationSession(newSessionPayload);
        if (created != null) {
          _sessionId = created['id'];
        }
      }
    } catch (e) {
      debugPrint('Consultation init error: $e');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _loadChatMessages() async {
    if (_conversationId == null) return;
    final history = await MaaCareBackendService.instance.fetchChatHistory(
      widget.appointment.userId,
      conversationId: _conversationId,
    );
    setState(() {
      _messages.clear();
      _messages.addAll(history);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    _messageController.clear();
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      conversationId: _conversationId,
      userId: widget.doctor.userId ?? 'system',
      role: 'assistant', // Doctor acts as assistant responder here
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
    });
    _scrollToBottom();

    await MaaCareBackendService.instance.saveMessage(userMsg);
    _loadChatMessages();
  }

  Future<void> _savePrescription(String status) async {
    if (_sessionId == null) return;
    setState(() => _isSavingPrescription = true);

    final success = await MaaCareBackendService.instance.updateConsultationSession(_sessionId!, {
      'prescription_text': _prescriptionController.text.trim(),
      'status': status,
    });

    if (mounted) {
      setState(() => _isSavingPrescription = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'completed' ? 'Session completed & locked! 📝' : 'Prescription saved! 💾'),
            backgroundColor: MaaColors.pink,
          ),
        );
        if (status == 'completed') {
          // Also mark appointment completed
          await MaaCareBackendService.instance.updateAppointmentStatus(widget.appointment.id, 'completed');
          if (mounted) Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save prescription.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MaaColors.background,
        body: Center(child: CircularProgressIndicator(color: MaaColors.pink)),
      );
    }

    final isUnmarried = widget.appointment.userRole == 'unmarried_girl';
    final hasRedSymptom = widget.appointment.symptoms.toLowerCase().contains('critical') || 
                          widget.appointment.symptoms.toLowerCase().contains('red zone');

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: MaaColors.cardDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.appointment.patientName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              isUnmarried ? 'Unmarried Girl / Period Support' : 'Pregnant Mother',
              style: GoogleFonts.outfit(fontSize: 11, color: MaaColors.textSecondary),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadChatMessages,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              icon: Icon(_isVideoActive ? Icons.videocam_off : Icons.videocam, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isVideoActive ? Colors.redAccent : MaaColors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                if (!_isVideoActive) {
                  final hasPermissions = await PermissionHelper.checkVideoPermissions(context);
                  if (!hasPermissions) return;
                }

                if (!_isVideoActive) {
                  // Generate a unique room code for this session (format: maa-XXXX-XXXX)
                  final shortId = _uuid.v4().replaceAll('-', '').substring(0, 8);
                  final newRoomCode = 'maa-${shortId.substring(0, 4)}-${shortId.substring(4, 8)}';
                  setState(() {
                    _activeRoomCode = newRoomCode;
                    _isVideoActive = true;
                  });

                  // Save room code to DB so patient can query it
                  if (_sessionId != null) {
                    await MaaCareBackendService.instance.updateConsultationSession(_sessionId!, {
                      'room_id': newRoomCode,
                      'status': 'active',
                    });
                  }

                  final patientUser = await MaaCareBackendService.instance
                      .fetchUser(widget.appointment.userId);
                  if (patientUser != null && patientUser.fcmToken != null) {
                    await PushNotificationService.instance.sendFcmPushViaBackend(
                      fcmToken: patientUser.fcmToken!,
                      title: 'Incoming Video Consult 📞',
                      body: 'Dr. ${widget.doctor.name} is calling you. Tap to join room!',
                      data: {
                        'type': 'doctor_consult',
                        'room_code': newRoomCode,
                        'doctor_name': widget.doctor.name,
                        'session_id': _sessionId ?? '',
                      },
                    );
                  } else {
                    await PushNotificationService.instance.sendPushViaBackend(
                      playerIds: [patientUser?.onesignalPlayerId ?? 'mock_player_id'],
                      title: 'Incoming Video Consult 📞',
                      body: 'Dr. ${widget.doctor.name} is calling you. Tap to join!',
                      type: 'doctor_consult',
                      route: '/consult',
                      data: {
                        'room_code': newRoomCode,
                        'doctor_name': widget.doctor.name,
                        'session_id': _sessionId ?? '',
                      },
                    );
                  }
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('📞 Room: $newRoomCode — Notification sent to patient!'),
                        backgroundColor: MaaColors.pink,
                      ),
                    );
                  }
                } else {
                  setState(() => _isVideoActive = false);
                }
              },
              label: Text(_isVideoActive ? 'End Call' : 'Video Consult', style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Live Video Call + Chat messages
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // Picture-in-Picture (PiP) Video Panel with RepaintBoundary for locked 60/120 FPS
                if (_isVideoActive)
                  RepaintBoundary(
                    child: Container(
                      height: 220,
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MaaColors.pink.withValues(alpha: 0.5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: HMSPrebuilt(
                          roomCode: _activeRoomCode ?? 'maa-default-room', // Unique per-session room
                          onLeave: () {
                            setState(() => _isVideoActive = false);
                          },
                          options: HMSPrebuiltOptions(
                            userName: 'Dr. ${widget.doctor.name}',
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Chat messaging window
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final isDoc = m.role == 'assistant';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isDoc ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isDoc)
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: MaaColors.pink,
                                child: Icon(Icons.person, color: Colors.white, size: 14),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDoc ? MaaColors.pink : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  m.content,
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            ),
          ),

          // Right Side: Triage & E-Prescription Panel
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: MaaColors.cardDark,
                border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Digital Triage Box
                    Text(
                      'Digital Triage Status',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hasRedSymptom ? Colors.red.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasRedSymptom ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: hasRedSymptom ? Colors.red : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasRedSymptom ? '⚠️ CRITICAL RISK' : '✓ STABLE CONSULT',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasRedSymptom ? Colors.redAccent : Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.appointment.symptoms,
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Prescription Area
                    Text(
                      'E-Prescription / Clinical Notes',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _prescriptionController,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter clinical diagnostics, dosage directions, and self-care plans here...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white60,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isSavingPrescription ? null : () => _savePrescription('pending'),
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MaaColors.pink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isSavingPrescription ? null : () => _savePrescription('completed'),
                            child: const Text('Complete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message to patient...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: MaaColors.pink),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

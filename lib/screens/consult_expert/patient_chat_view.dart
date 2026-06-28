import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/doctor_model.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import '../../providers/user_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../services/realtime_client.dart';
import '../../utils/permission_helper.dart';

class PatientChatView extends StatefulWidget {
  final BookingModel appointment;

  const PatientChatView({
    super.key,
    required this.appointment,
  });

  @override
  State<PatientChatView> createState() => _PatientChatViewState();
}

class _PatientChatViewState extends State<PatientChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final _uuid = const Uuid();

  DoctorModel? _doctor;
  String? _conversationId;
  String? _activeRoomCode;
  String? _prescriptionText;
  bool _isLoading = true;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _initConsultation();
  }

  @override
  void dispose() {
    if (_doctor != null && _conversationId != null) {
      InsForgeRealtimeClient.instance.unsubscribe('chats:$_conversationId');
      InsForgeRealtimeClient.instance.unsubscribe('appointments:${_doctor!.id}');
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initConsultation() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Doctor
      final doc = await MaaCareBackendService.instance.fetchDoctorById(widget.appointment.doctorId);
      if (doc == null) {
        throw Exception('Doctor profile not found.');
      }
      _doctor = doc;

      // 2. Fetch or create chat conversation
      final convs = await MaaCareBackendService.instance.fetchConversations(widget.appointment.userId);
      final chatTitle = 'Consultation: Dr. ${doc.name}';
      
      final conv = convs.firstWhere(
        (c) => c.title.contains('Consultation') && c.title.contains(doc.name),
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
      await _checkSessionStatus();

      // 3. Realtime WebSockets Subscription
      if (!_isSubscribed && _conversationId != null) {
        _isSubscribed = true;
        
        // Listen to new chat messages
        InsForgeRealtimeClient.instance.subscribe('chats:$_conversationId', (payload) {
          debugPrint('[PatientChat] Real-time message received');
          _loadChatMessages();
        });

        // Listen to session modifications (e.g. Doctor starts a call or updates prescription)
        InsForgeRealtimeClient.instance.subscribe('appointments:${doc.id}', (payload) {
          debugPrint('[PatientChat] Real-time session/appointment update received');
          _checkSessionStatus();
        });
      }
    } catch (e) {
      debugPrint('Patient Chat Init Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _checkSessionStatus() async {
    if (_doctor == null) return;
    final session = await MaaCareBackendService.instance.fetchConsultationSession(
      _doctor!.id,
      widget.appointment.userId,
    );
    if (session != null && mounted) {
      setState(() {
        _activeRoomCode = session['room_id'] as String?;
        _prescriptionText = session['prescription_text'] as String?;
      });
    }
  }

  Future<void> _loadChatMessages() async {
    if (_conversationId == null) return;
    final history = await MaaCareBackendService.instance.fetchChatHistory(
      widget.appointment.userId,
      conversationId: _conversationId,
    );
    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(history);
      });
      _scrollToBottom();
    }
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
      userId: widget.appointment.userId,
      role: 'user',
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
        appBar: AppBar(title: const Text('Consultation')),
        body: const Center(child: Text('Doctor details not available.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: MaaColors.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: MaaColors.pink.withValues(alpha: 0.15),
              child: Text(_doctor!.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_doctor!.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(_doctor!.specialization, style: GoogleFonts.outfit(fontSize: 11, color: MaaColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              _loadChatMessages();
              _checkSessionStatus();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Prescription Section (if written by doctor)
          if (_prescriptionText != null && _prescriptionText!.trim().isNotEmpty)
            _buildPrescriptionCard(),

          // 2. Incoming Call Floating Banner
          if (_activeRoomCode != null && _activeRoomCode!.trim().isNotEmpty)
            _buildCallIndicatorCard(),

          // 3. Message Stream
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isDoctor = msg.role == 'assistant';
                      return _buildMessageBubble(msg, isDoctor);
                    },
                  ),
          ),

          // 4. Message Input
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaaColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: MaaColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rx Prescription & Notes',
                style: GoogleFonts.poppins(color: MaaColors.success, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _prescriptionText!,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildCallIndicatorCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MaaColors.pink, MaaColors.softPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MaaColors.pink.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.phone_in_talk, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation Call Active',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Dr. ${_doctor!.name} is waiting for you.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _joinVideoCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: MaaColors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Join Call',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(duration: 1.5.seconds, color: Colors.white30)
     .scale(begin: const Offset(0.98, 0.98), end: const Offset(1.02, 1.02), duration: 1.seconds);
  }

  void _joinVideoCall() async {
    if (_activeRoomCode == null) return;
    
    final userName = context.read<UserProvider>().user?.name ?? 'Mama';
    final hasPermissions = await PermissionHelper.checkVideoPermissions(context);
    if (!hasPermissions) return;

    final routeArgs = {
      'appointment': widget.appointment,
      'room_code': _activeRoomCode,
      'user_name': userName,
    };

    if (mounted) {
      Navigator.pushNamed(context, '/join-consultation', arguments: routeArgs);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: MaaColors.cardDark, shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: MaaColors.textMuted, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Start Chatting',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask Dr. ${_doctor!.name} any questions, describe symptoms, or attach report links. The doctor will call you when they are ready.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: MaaColors.textMuted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDoctor) {
    return Align(
      alignment: isDoctor ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isDoctor ? MaaColors.cardDark : MaaColors.pink,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isDoctor ? 4 : 16),
            bottomRight: Radius.circular(isDoctor ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: MaaColors.pink),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

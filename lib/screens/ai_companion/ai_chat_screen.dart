import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../providers/community_provider.dart'; // Reuse for uploadMedia
import '../../widgets/premium_paywall_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final chatProvider = context.read<ChatProvider>();
    chatProvider.addListener(_chatProviderListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserProvider>().user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<ChatProvider>().loadConversations(userId);
      }

      // Check for initial message from deep link/navigation
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialMessage')) {
        final initialMsg = args['initialMessage'] as String;
        _inputController.text = initialMsg;
        _sendMessage();
      }
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().removeListener(_chatProviderListener);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _paywallShown = false;

  void _chatProviderListener() {
    final chatProvider = context.read<ChatProvider>();
    final userProvider = context.read<UserProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;

    if (chatProvider.isEmergencyTriage) {
      final message = chatProvider.triageMessage ?? 'Emergency detected!';
      chatProvider.clearEmergencyTriage();
      _showEmergencyTriageModal(message);
    }
    if (chatProvider.isPaywallGateTriggered) {
      chatProvider.clearPaywallGate();
      PremiumPaywallSheet.show(context, message: "You've successfully tested your 5 Free AI Consultations. Upgrade to MaaCare Elite Pass for continuous, personalized guidance.");
    }

    if (!isPremium && chatProvider.freeAiChatCount >= 5 && !_paywallShown) {
      _paywallShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PremiumPaywallSheet.show(context, message: "You've successfully tested your 5 Free AI Consultations. Upgrade to MaaCare Elite Pass for continuous, personalized guidance.");
      });
    }
  }

  void _showEmergencyTriageModal(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: MaaColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
                SizedBox(width: 12),
                Text(
                  'Emergency Alert!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Critical / High-Risk Symptoms Detected!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: MaaColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Emergency Services: 108\nAmbulance Services: 102',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MaaColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('tel:108');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.phone_in_talk),
                      label: Text('Call Emergency (108)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('tel:102');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MaaColors.pink,
                        side: const BorderSide(color: MaaColors.pink),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.local_hospital),
                      label: Text('Call Ambulance (102)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Acknowledge & Close',
                        style: GoogleFonts.poppins(color: MaaColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final userProvider = context.read<UserProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final chatProvider = context.read<ChatProvider>();
    
    if (!isPremium && chatProvider.freeAiChatCount >= 5) {
      PremiumPaywallSheet.show(context, message: "You've successfully tested your 5 Free AI Consultations. Upgrade to MaaCare Elite Pass for continuous, personalized guidance.");
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last;
      final fileName =
          'chat_media_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (!mounted) return;
      final url = await context
          .read<CommunityProvider>()
          .uploadMedia(fileName, bytes, bucket: 'chat_media');
      if (url != null && mounted) {
        final userId = context.read<UserProvider>().user?.id ?? 'guest';
        await context.read<ChatProvider>().sendMessage(
              userId: userId,
              text: '',
              imageUrl: url,
            );
        _scrollToBottom();
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMessage() async {
    final userProvider = context.read<UserProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final chatProvider = context.read<ChatProvider>();
    
    if (!isPremium && chatProvider.freeAiChatCount >= 5) {
      PremiumPaywallSheet.show(context, message: "You've successfully tested your 5 Free AI Consultations. Upgrade to MaaCare Elite Pass for continuous, personalized guidance.");
      return;
    }

    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    final userId = userProvider.user?.id ?? 'guest';
    await chatProvider.sendMessage(
          userId: userId,
          text: text,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).maaAiChat),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'clear') context.read<ChatProvider>().clearChat();
              if (val == 'delete') {
                final userId = context.read<UserProvider>().user?.id ?? '';
                final convId =
                    context.read<ChatProvider>().activeConversationId;
                if (convId != null) {
                  context
                      .read<ChatProvider>()
                      .deleteConversation(userId, convId);
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'clear', child: Text(AppLocalizations.of(context).clearHistory)),
              PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context).deleteChat)),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (ctx, chatProvider, _) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: MaaColors.deepPink));
                }
                // Schedule scroll AFTER build, never inside builder
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length +
                      (chatProvider.isTyping ? 1 : 0),
                  itemBuilder: (ctx, index) {
                    if (chatProvider.isTyping &&
                        index == chatProvider.messages.length) {
                      return _TypingBubble();
                    }
                    final msg = chatProvider.messages[index];
                    return _ChatBubble(message: msg);
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: MaaColors.deepPink),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = context.watch<UserProvider>().user;
    final chatProvider = context.watch<ChatProvider>();

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration:
                const BoxDecoration(gradient: MaaColors.primaryGradient),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                      radius: 30,
                      backgroundColor: MaaColors.white,
                      child: Text('🤱', style: TextStyle(fontSize: 30))),
                  const SizedBox(height: 10),
                  Text(user?.name ?? 'Mama',
                      style: const TextStyle(
                          color: MaaColors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.add_circle_outline, color: MaaColors.deepPink),
            title: Text(AppLocalizations.of(context).newConversation,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              if (user != null) chatProvider.createNewConversation(user.id);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: chatProvider.conversations.length,
              itemBuilder: (ctx, i) {
                final conv = chatProvider.conversations[i];
                final isSelected = conv.id == chatProvider.activeConversationId;
                return ListTile(
                  title: Text(conv.title,
                      style: TextStyle(
                          color: isSelected ? MaaColors.deepPink : null,
                          fontWeight: isSelected ? FontWeight.bold : null)),
                  leading: const Icon(Icons.chat_bubble_outline),
                  selected: isSelected,
                  onTap: () {
                    if (user != null) {
                      chatProvider.selectConversation(user.id, conv.id);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign Out'),
            onTap: () async {
              await MaaCareBackendService.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/splash');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final userProvider = context.watch<UserProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final chatProvider = context.watch<ChatProvider>();
    final isLocked = !isPremium && chatProvider.freeAiChatCount >= 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: MaaColors.white,
        boxShadow: [
          BoxShadow(
              color: MaaColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: MaaColors.deepPink),
            onPressed: (isLocked || _isUploading) ? null : _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !isLocked,
              decoration: InputDecoration(
                hintText: isLocked 
                    ? 'Limit reached. Upgrade to Premium... 🔒' 
                    : 'Type your message... 💕',
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24))),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => isLocked ? null : _sendMessage(),
              maxLines: null,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send_rounded,
                color: (isLocked || chatProvider.isTyping) ? MaaColors.pink : MaaColors.deepPink),
            onPressed: (isLocked || chatProvider.isTyping) ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
                radius: 16,
                backgroundColor: MaaColors.pink,
                child: Text('🤱', style: TextStyle(fontSize: 16))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        message.imageUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, loading) => loading == null
                            ? child
                            : const SizedBox(
                                width: 200,
                                height: 150,
                                child:
                                    Center(child: CircularProgressIndicator())),
                      ),
                    ),
                  ),
                if (message.content.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser ? MaaColors.primaryGradient : null,
                      color: isUser ? null : MaaColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: MaaColors.cardShadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                          color: isUser ? MaaColors.white : MaaColors.textDark,
                          fontSize: 14,
                          height: 1.5),
                    ),
                  ),
              ],
            ).animate().slideY(begin: 0.2, end: 0).fadeIn(),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
                radius: 16,
                backgroundColor: MaaColors.peach,
                child: Text('👩', style: TextStyle(fontSize: 16))),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 16,
              backgroundColor: MaaColors.pink,
              child: Text('🤱', style: TextStyle(fontSize: 16))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: MaaColors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: MaaColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Text('...',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: MaaColors.deepPink))
                .animate(onPlay: (c) => c.repeat())
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(2, 2),
                    duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

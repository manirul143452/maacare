import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/insforge_service.dart';
import '../../providers/community_provider.dart'; // Reuse for uploadMedia

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
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    final userId = context.read<UserProvider>().user?.id ?? 'guest';
    await context.read<ChatProvider>().sendMessage(
          userId: userId,
          text: text,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maa AI Chat'),
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
              const PopupMenuItem(value: 'clear', child: Text('Clear History')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Chat')),
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
                _scrollToBottom();
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
            title: const Text('New Conversation',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
              await InsForgeService.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/splash');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
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
            onPressed: _isUploading ? null : _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Type your message... 💕',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24))),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          Consumer<ChatProvider>(
            builder: (_, cp, __) => IconButton(
              icon: Icon(Icons.send_rounded,
                  color: cp.isTyping ? MaaColors.pink : MaaColors.deepPink),
              onPressed: cp.isTyping ? null : _sendMessage,
            ),
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

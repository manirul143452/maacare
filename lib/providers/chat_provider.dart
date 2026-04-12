// ============================================================
//  ChatProvider – AI Companion State – MaaCare (InsForge)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../services/insforge_service.dart';
import '../services/realtime_client.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final List<ConversationModel> _conversations = [];
  String? _activeConversationId;
  bool _isTyping = false;
  bool _isLoading = false;
  final _uuid = const Uuid();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  String? get activeConversationId => _activeConversationId;
  bool get isTyping => _isTyping;
  bool get isLoading => _isLoading;

  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final conversations =
          await InsForgeService.instance.fetchConversations(userId);
      _conversations.clear();
      _conversations.addAll(conversations);

      if (_conversations.isNotEmpty && _activeConversationId == null) {
        _activeConversationId = _conversations.first.id;
        await loadHistory(userId, conversationId: _activeConversationId);
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(String userId, String convId) async {
    _activeConversationId = convId;
    await loadHistory(userId, conversationId: convId);
  }

  Future<void> createNewConversation(String userId) async {
    final conv = ConversationModel(
      id: _uuid.v4(),
      userId: userId,
      title: 'Chat ${DateTime.now().hour}:${DateTime.now().minute}',
      createdAt: DateTime.now(),
    );
    await InsForgeService.instance.createConversation(conv);
    _conversations.insert(0, conv);
    _activeConversationId = conv.id;
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
  }

  Future<void> deleteConversation(String userId, String convId) async {
    await InsForgeService.instance.deleteConversation(convId);
    _conversations.removeWhere((c) => c.id == convId);
    if (_activeConversationId == convId) {
      _activeConversationId =
          _conversations.isNotEmpty ? _conversations.first.id : null;
      if (_activeConversationId != null) {
        await loadHistory(userId, conversationId: _activeConversationId);
      } else {
        _messages.clear();
        _addWelcomeMessage();
      }
    }
    notifyListeners();
  }

  Future<void> loadHistory(String userId, {String? conversationId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final history = await InsForgeService.instance
          .fetchChatHistory(userId, conversationId: conversationId);
      _messages.clear();
      _messages.addAll(history);
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      // Start REALTIME Subscription for this chat
      if (conversationId != null) {
        InsForgeRealtimeClient.instance.subscribe('chats:$conversationId',
            (payload) {
          // Check if payload is from chat trigger
          if (payload['event'] == 'INSERT_chat') {
            final newMsg = ChatMessage.fromMap(payload['record']);
            // Check if not already explicitly added by local sendMessage
            if (!_messages.any((m) => m.id == newMsg.id)) {
              _messages.add(newMsg);
              notifyListeners();
            }
          }
        });
      }
    } catch (_) {
      _addWelcomeMessage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      userId: 'system',
      role: 'assistant',
      content:
          'Namaste, Mama! 💕 I\'m Maa, your 24/7 companion. I\'m here to listen, support, and celebrate every step of your journey. How are you feeling today? 🌸',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> sendMessage({
    required String userId,
    required String text,
    String? imageUrl,
  }) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    if (_activeConversationId == null) {
      await createNewConversation(userId);
    }

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      conversationId: _activeConversationId,
      userId: userId,
      role: 'user',
      content: text.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // Save user message (fire & forget)
    InsForgeService.instance.saveMessage(userMsg).catchError((_) {});

    try {
      // Prepare history for AI context (last 10 messages)
      final history = _messages
          .take(10)
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      String aiResponseText =
          'I\'m here with you, Mama 💕 Please try again in a moment.';
      final edgeFunctionResponse =
          await InsForgeService.instance.invokeAiChat(history);

      if (edgeFunctionResponse != null &&
          edgeFunctionResponse['data'] != null) {
        final data = edgeFunctionResponse['data'];
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          aiResponseText =
              data['choices'][0]['message']['content'] ?? aiResponseText;
        }
      }

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        conversationId: _activeConversationId,
        userId: 'assistant',
        role: 'assistant',
        content: aiResponseText,
        createdAt: DateTime.now(),
      );
      _messages.add(aiMsg);

      // Save AI response
      InsForgeService.instance.saveMessage(aiMsg).catchError((_) {});
    } catch (_) {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        conversationId: _activeConversationId,
        userId: 'assistant',
        role: 'assistant',
        content: 'I\'m here with you, Mama 💕 Please try again in a moment.',
        createdAt: DateTime.now(),
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    if (_activeConversationId != null) {
      await InsForgeService.instance.deleteChatHistory(_activeConversationId!);
      _messages.clear();
      _addWelcomeMessage();
      notifyListeners();
    }
  }
}

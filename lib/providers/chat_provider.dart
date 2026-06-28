// ============================================================
//  ChatProvider – AI Companion State – MaaCare (InsForge)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../services/maacare_backend_service.dart';
import '../services/realtime_client.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final List<ConversationModel> _conversations = [];
  String? _activeConversationId;
  bool _isTyping = false;
  bool _isLoading = false;
  bool _isEmergencyTriage = false;
  String? _triageMessage;
  bool _isPaywallGateTriggered = false;
  int _freeAiChatCount = 0;
  final _uuid = const Uuid();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  String? get activeConversationId => _activeConversationId;
  bool get isTyping => _isTyping;
  bool get isLoading => _isLoading;
  bool get isEmergencyTriage => _isEmergencyTriage;
  String? get triageMessage => _triageMessage;
  bool get isPaywallGateTriggered => _isPaywallGateTriggered;
  int get freeAiChatCount => _freeAiChatCount;

  void clearEmergencyTriage() {
    _isEmergencyTriage = false;
    _triageMessage = null;
    notifyListeners();
  }

  void clearPaywallGate() {
    _isPaywallGateTriggered = false;
    notifyListeners();
  }

  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final conversations =
          await MaaCareBackendService.instance.fetchConversations(userId);
      _conversations.clear();
      _conversations.addAll(conversations);

      final sub = await MaaCareBackendService.instance.fetchUserSubscription(userId);
      if (sub != null) {
        _freeAiChatCount = sub['free_ai_chat_count'] as int? ?? 0;
      }

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
    await MaaCareBackendService.instance.createConversation(conv);
    _conversations.insert(0, conv);
    _activeConversationId = conv.id;
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
  }

  Future<void> deleteConversation(String userId, String convId) async {
    await MaaCareBackendService.instance.deleteConversation(convId);
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
      final history = await MaaCareBackendService.instance
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
          final event = payload['event'];
          if (event == 'INSERT_chat') {
            final newMsg = ChatMessage.fromMap(payload['record']);
            if (!_messages.any((m) => m.id == newMsg.id)) {
              _messages.add(newMsg);
              notifyListeners();
            }
          } else if (event == 'UPDATE_chat') {
            final updatedMsg = ChatMessage.fromMap(payload['record']);
            final index = _messages.indexWhere((m) => m.id == updatedMsg.id);
            if (index != -1) {
              _messages[index] = updatedMsg;
              notifyListeners();
            }
          } else if (event == 'DELETE_chat') {
            final deletedId = payload['old_record']?['id'] ?? payload['record']?['id'];
            if (deletedId != null) {
              _messages.removeWhere((m) => m.id == deletedId);
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
    MaaCareBackendService.instance.saveMessage(userMsg).catchError((_) {});

    try {
      // Prepare history for AI context (last 10 messages)
      final history = (_messages.length > 10
              ? _messages.sublist(_messages.length - 10)
              : _messages)
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      String aiResponseText =
          'I\'m here with you, Mama 💕 Please try again in a moment.';
      final edgeFunctionResponse =
          await MaaCareBackendService.instance.invokeAiChat(history);

      if (edgeFunctionResponse != null) {
        if (edgeFunctionResponse.containsKey('free_ai_chat_count')) {
          _freeAiChatCount = edgeFunctionResponse['free_ai_chat_count'] as int;
        } else if (edgeFunctionResponse['data'] != null &&
            edgeFunctionResponse['data'] is Map &&
            edgeFunctionResponse['data'].containsKey('free_ai_chat_count')) {
          _freeAiChatCount = edgeFunctionResponse['data']['free_ai_chat_count'] as int;
        }
        notifyListeners();

        final isPaywallRoot = edgeFunctionResponse['paywall_limit'] == true;
        final isPaywallData = edgeFunctionResponse['data'] != null &&
            edgeFunctionResponse['data'] is Map &&
            edgeFunctionResponse['data']['paywall_limit'] == true;

        if (isPaywallRoot || isPaywallData) {
          _isPaywallGateTriggered = true;
          _isTyping = false;
          notifyListeners();
          return;
        }

        final isTriageRoot = edgeFunctionResponse['triage_status'] == 'emergency';
        final isTriageData = edgeFunctionResponse['data'] != null &&
            edgeFunctionResponse['data'] is Map &&
            edgeFunctionResponse['data']['triage_status'] == 'emergency';

        if (isTriageRoot || isTriageData) {
          _isEmergencyTriage = true;
          _triageMessage = isTriageRoot 
              ? (edgeFunctionResponse['message'] as String?) 
              : (edgeFunctionResponse['data']['message'] as String?);
          _isTyping = false;
          notifyListeners();
          return;
        }

        if (edgeFunctionResponse.containsKey('data') && edgeFunctionResponse['data'] != null) {
          final data = edgeFunctionResponse['data'];
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            aiResponseText = data['choices'][0]['message']['content'] ?? aiResponseText;
          }
        } else if (edgeFunctionResponse.containsKey('choices') && edgeFunctionResponse['choices'] != null) {
          if (edgeFunctionResponse['choices'].isNotEmpty) {
            aiResponseText = edgeFunctionResponse['choices'][0]['message']['content'] ?? aiResponseText;
          }
        } else if (edgeFunctionResponse.containsKey('error')) {
          aiResponseText = 'Runtime Error: ${edgeFunctionResponse['error']}';
          if (edgeFunctionResponse['details'] != null) {
             aiResponseText += '\nDetails: ${edgeFunctionResponse['details']}';
          }
        }
      } else {
        aiResponseText = 'System Error: Edge Function failed to connect (Returned Null). Check debug console for HTTP status.';
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

      // Save AI response if successful
      if (!aiResponseText.startsWith('Runtime Error')) {
        MaaCareBackendService.instance.saveMessage(aiMsg).catchError((_) {});
      }
    } catch (e) {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        conversationId: _activeConversationId,
        userId: 'assistant',
        role: 'assistant',
        content: 'System catch error: $e',
        createdAt: DateTime.now(),
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    if (_activeConversationId != null) {
      await MaaCareBackendService.instance.deleteChatHistory(_activeConversationId!);
      _messages.clear();
      _addWelcomeMessage();
      notifyListeners();
    }
  }
}

// ============================================================
//  ChatMessage Model – MaaCare
// ============================================================

class ChatMessage {
  final String id;
  final String? conversationId;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.isLoading = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading',
      userId: '',
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String?,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

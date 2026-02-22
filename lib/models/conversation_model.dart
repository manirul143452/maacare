// ============================================================
//  Conversation Model – MaaCare / Chatbot
// ============================================================

class ConversationModel {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String? ?? 'New Conversation',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
    };
  }
}

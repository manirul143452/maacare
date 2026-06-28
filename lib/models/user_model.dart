// ============================================================
//  UserModel – MaaCare
// ============================================================

class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final DateTime? dueDate;
  final String? mood;
  final int points;
  final int streak;
  final String? avatarUrl;
  final String language;
  final bool isPremium;
  final String? premiumPlan;
  final String userRole;
  final int? trimester;
  final String? ageBracket;
  final DateTime createdAt;
  final String? fcmToken;
  final String? onesignalPlayerId;
  final double? heightCm;
  final double? weightKg;
  final int trialUsesLeft;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.dueDate,
    this.mood,
    this.points = 0,
    this.streak = 0,
    this.avatarUrl,
    this.language = 'en',
    this.isPremium = false,
    this.premiumPlan,
    this.userRole = '',
    this.trimester,
    this.ageBracket,
    required this.createdAt,
    this.fcmToken,
    this.onesignalPlayerId,
    this.heightCm,
    this.weightKg,
    this.trialUsesLeft = 10,
  });

  /// Weeks of pregnancy elapsed (based on due date – 40 weeks).
  int get pregnancyWeek {
    if (dueDate == null) return 0;
    final totalDays = dueDate!.difference(DateTime.now()).inDays;
    final daysPregnant = 280 - totalDays; // 40 weeks = 280 days
    return (daysPregnant / 7).clamp(0, 42).toInt();
  }

  /// Badge tier based on points.
  String get badgeTitle {
    if (points >= 5000) return '🏆 Super Mom';
    if (points >= 2000) return '💎 Diamond Mom';
    if (points >= 1000) return '🌟 Star Mom';
    if (points >= 500) return '💕 Care Mom';
    return '🌸 New Mom';
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? dueDate,
    String? mood,
    int? points,
    int? streak,
    String? avatarUrl,
    String? language,
    bool? isPremium,
    String? premiumPlan,
    String? userRole,
    int? trimester,
    String? ageBracket,
    String? fcmToken,
    String? onesignalPlayerId,
    double? heightCm,
    double? weightKg,
    int? trialUsesLeft,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dueDate: dueDate ?? this.dueDate,
      mood: mood ?? this.mood,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      isPremium: isPremium ?? this.isPremium,
      premiumPlan: premiumPlan ?? this.premiumPlan,
      userRole: userRole ?? this.userRole,
      trimester: trimester ?? this.trimester,
      ageBracket: ageBracket ?? this.ageBracket,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      onesignalPlayerId: onesignalPlayerId ?? this.onesignalPlayerId,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      trialUsesLeft: trialUsesLeft ?? this.trialUsesLeft,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? 'Mama',
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      mood: map['mood'] as String?,
      points: (map['points'] as int?) ?? 0,
      streak: (map['streak'] as int?) ?? 0,
      avatarUrl: map['profile_photo_url'] as String? ?? map['avatar_url'] as String?,
      language: (map['language'] as String?) ?? 'en',
      isPremium: (map['is_premium'] as bool?) ?? false,
      premiumPlan: map['premium_plan'] as String?,
      userRole: (map['user_role'] as String?) ?? '',
      trimester: map['trimester'] as int?,
      ageBracket: map['age_bracket'] as String?,
      createdAt: DateTime.parse(
          (map['created_at'] as String?) ?? DateTime.now().toIso8601String()),
      fcmToken: map['fcm_token'] as String?,
      onesignalPlayerId: map['onesignal_player_id'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      trialUsesLeft: (map['trial_uses_left'] as int?) ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'mood': mood,
      'points': points,
      'streak': streak,
      'avatar_url': avatarUrl,
      'profile_photo_url': avatarUrl,
      'language': language,
      'is_premium': isPremium,
      if (premiumPlan != null) 'premium_plan': premiumPlan,
      'user_role': userRole,
      if (trimester != null) 'trimester': trimester,
      if (ageBracket != null) 'age_bracket': ageBracket,
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (onesignalPlayerId != null) 'onesignal_player_id': onesignalPlayerId,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      'trial_uses_left': trialUsesLeft,
    };
  }
}

// --------------- Fruit size comparison ---------------
const List<Map<String, String>> babyFruitSizes = [
  {'week': '4', 'fruit': 'Poppy Seed', 'emoji': '🌱', 'size': '0.4 mm'},
  {'week': '6', 'fruit': 'Lentil', 'emoji': '🌿', 'size': '6 mm'},
  {'week': '8', 'fruit': 'Raspberry', 'emoji': '🫐', 'size': '1.6 cm'},
  {'week': '10', 'fruit': 'Strawberry', 'emoji': '🍓', 'size': '3.1 cm'},
  {'week': '12', 'fruit': 'Lime', 'emoji': '🍋', 'size': '5.4 cm'},
  {'week': '16', 'fruit': 'Avocado', 'emoji': '🥑', 'size': '11.6 cm'},
  {'week': '20', 'fruit': 'Banana', 'emoji': '🍌', 'size': '25.6 cm'},
  {'week': '24', 'fruit': 'Corn', 'emoji': '🌽', 'size': '30 cm'},
  {'week': '28', 'fruit': 'Eggplant', 'emoji': '🍆', 'size': '37.6 cm'},
  {'week': '32', 'fruit': 'Coconut', 'emoji': '🥥', 'size': '42.4 cm'},
  {'week': '36', 'fruit': 'Honeydew', 'emoji': '🍈', 'size': '47.4 cm'},
  {'week': '40', 'fruit': 'Watermelon', 'emoji': '🍉', 'size': '51 cm'},
];

Map<String, String> getBabyFruitForWeek(int week) {
  Map<String, String> result =
      {'fruit': 'growing', 'emoji': '👶', 'size': 'tiny'};
  for (final entry in babyFruitSizes) {
    if (week >= int.parse(entry['week']!)) result = entry;
  }
  return result;
}

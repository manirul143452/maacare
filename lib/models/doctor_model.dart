// ============================================================
//  DoctorModel – MaaCare
// ============================================================

class DoctorModel {
  final String id;
  final String? userId; // Link to user account
  final String name;
  final String specialization;
  final String experience;
  final String rating;
  final String fee;
  final String bio;
  final String availableHours;
  final String? avatarUrl;
  final String? licenseUrl; // Proof of credentials
  final String emoji;
  final bool isVerified;
  final String status; // 'pending', 'verified', 'rejected'
  final String clinicLocation;
  final List<String> availableDays;
  final int slotDurationMinutes;
  final String dailyStartTime;
  final String dailyEndTime;

  const DoctorModel({
    required this.id,
    this.userId,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.rating,
    required this.fee,
    required this.bio,
    required this.availableHours,
    this.avatarUrl,
    this.licenseUrl,
    required this.emoji,
    this.isVerified = false,
    this.status = 'pending',
    this.clinicLocation = 'Online / Clinic',
    this.availableDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    this.slotDurationMinutes = 20,
    this.dailyStartTime = '09:00:00',
    this.dailyEndTime = '17:00:00',
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      name: map['name'] ?? 'Doctor',
      specialization: map['specialization'] ?? 'General Physician',
      experience: map['experience'] ?? '0 yrs',
      rating: map['rating']?.toString() ?? '5.0',
      fee: map['fee'] ?? '₹0',
      bio: map['bio'] ?? '',
      availableHours: map['available_hours'] ?? 'Consultation only',
      avatarUrl: map['profile_photo_url'] as String? ?? map['avatar_url'] as String?,
      licenseUrl: map['license_url'],
      emoji: map['emoji'] ?? '👩‍⚕️',
      isVerified: map['is_verified'] ?? false,
      status: map['status'] ?? 'pending',
      clinicLocation: map['clinic_location'] ?? 'Online / Clinic',
      availableDays: map['available_days'] != null
          ? List<String>.from(map['available_days'])
          : const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      slotDurationMinutes: map['slot_duration_minutes'] as int? ?? 20,
      dailyStartTime: map['daily_start_time'] ?? '09:00:00',
      dailyEndTime: map['daily_end_time'] ?? '17:00:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'specialization': specialization,
      'experience': experience,
      'rating': rating,
      'fee': fee,
      'bio': bio,
      'available_hours': availableHours,
      'avatar_url': avatarUrl,
      'profile_photo_url': avatarUrl,
      'license_url': licenseUrl,
      'emoji': emoji,
      'is_verified': isVerified,
      'status': status,
      'clinic_location': clinicLocation,
      'available_days': availableDays,
      'slot_duration_minutes': slotDurationMinutes,
      'daily_start_time': dailyStartTime,
      'daily_end_time': dailyEndTime,
    };
  }

  DoctorModel copyWith({
    String? name,
    String? specialization,
    String? experience,
    String? rating,
    String? fee,
    String? bio,
    String? availableHours,
    String? avatarUrl,
    String? licenseUrl,
    String? emoji,
    bool? isVerified,
    String? status,
    String? clinicLocation,
    List<String>? availableDays,
    int? slotDurationMinutes,
    String? dailyStartTime,
    String? dailyEndTime,
  }) {
    return DoctorModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      fee: fee ?? this.fee,
      bio: bio ?? this.bio,
      availableHours: availableHours ?? this.availableHours,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      emoji: emoji ?? this.emoji,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      clinicLocation: clinicLocation ?? this.clinicLocation,
      availableDays: availableDays ?? this.availableDays,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      dailyStartTime: dailyStartTime ?? this.dailyStartTime,
      dailyEndTime: dailyEndTime ?? this.dailyEndTime,
    );
  }
}

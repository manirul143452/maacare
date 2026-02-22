// ============================================================
//  Symptom & Vaccination Models – MaaCare
// ============================================================

class SymptomCheckModel {
  final String id;
  final String userId;
  final List<String> symptoms;
  final String riskLevel; // 'low', 'medium', 'high'
  final String advice;
  final DateTime createdAt;

  const SymptomCheckModel({
    required this.id,
    required this.userId,
    required this.symptoms,
    required this.riskLevel,
    required this.advice,
    required this.createdAt,
  });

  factory SymptomCheckModel.fromMap(Map<String, dynamic> map) {
    return SymptomCheckModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      symptoms: List<String>.from(map['symptoms'] as List),
      riskLevel: map['risk_level'] as String,
      advice: (map['advice'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

// Common pregnancy symptoms
const List<Map<String, dynamic>> commonSymptoms = [
  {'name': 'Nausea / Morning sickness', 'risk': 'low', 'emoji': '🤢'},
  {'name': 'Back pain', 'risk': 'low', 'emoji': '🔙'},
  {'name': 'Headache', 'risk': 'medium', 'emoji': '🤕'},
  {'name': 'Swelling (feet/hands)', 'risk': 'medium', 'emoji': '🦶'},
  {'name': 'Fatigue', 'risk': 'low', 'emoji': '😴'},
  {'name': 'Heartburn', 'risk': 'low', 'emoji': '🔥'},
  {'name': 'Leg cramps', 'risk': 'low', 'emoji': '😣'},
  {'name': 'Shortness of breath', 'risk': 'medium', 'emoji': '😮‍💨'},
  {'name': 'Vaginal bleeding', 'risk': 'high', 'emoji': '⚠️'},
  {'name': 'Severe abdominal pain', 'risk': 'high', 'emoji': '🚨'},
  {'name': 'High fever (>38°C)', 'risk': 'high', 'emoji': '🌡️'},
  {'name': 'Blurred vision', 'risk': 'high', 'emoji': '👁️'},
  {'name': 'No fetal movement (after 20w)', 'risk': 'high', 'emoji': '⚠️'},
  {'name': 'Mood swings', 'risk': 'low', 'emoji': '😊'},
  {'name': 'Constipation', 'risk': 'low', 'emoji': '😖'},
];

String evaluateRisk(List<String> selectedSymptoms) {
  for (final symptom in commonSymptoms) {
    if (selectedSymptoms.contains(symptom['name']) &&
        symptom['risk'] == 'high') {
      return 'high';
    }
  }
  for (final symptom in commonSymptoms) {
    if (selectedSymptoms.contains(symptom['name']) &&
        symptom['risk'] == 'medium') {
      return 'medium';
    }
  }
  return 'low';
}

// ───────────────────────────────────────────────────────────

class VaccinationModel {
  final String id;
  final String userId;
  final String vaccineName;
  final String description;
  final DateTime dueDate;
  bool completed;

  VaccinationModel({
    required this.id,
    required this.userId,
    required this.vaccineName,
    required this.description,
    required this.dueDate,
    this.completed = false,
  });

  factory VaccinationModel.fromMap(Map<String, dynamic> map) {
    return VaccinationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      vaccineName: map['vaccine_name'] as String,
      description: (map['description'] as String?) ?? '',
      dueDate: DateTime.parse(map['due_date'] as String),
      completed: (map['completed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'vaccine_name': vaccineName,
      'description': description,
      'due_date': dueDate.toIso8601String().split('T').first,
      'completed': completed,
    };
  }
}

// Indian WHO vaccination schedule (prenatal & infant)
List<VaccinationModel> generateVaccinationSchedule({
  required String userId,
  required DateTime dueDate,
}) {
  final birth = dueDate;
  return [
    VaccinationModel(
      id: 'tdap',
      userId: userId,
      vaccineName: 'Tdap (Tetanus, Diphtheria, Pertussis)',
      description: 'Recommended between 27–36 weeks of pregnancy',
      dueDate: birth.subtract(const Duration(days: 91)),
    ),
    VaccinationModel(
      id: 'flu',
      userId: userId,
      vaccineName: 'Influenza (Flu)',
      description: 'Recommended during flu season in any trimester',
      dueDate: birth.subtract(const Duration(days: 180)),
    ),
    VaccinationModel(
      id: 'hepb_1',
      userId: userId,
      vaccineName: 'Hepatitis B – Dose 1',
      description: 'At birth (within 24 hours)',
      dueDate: birth,
    ),
    VaccinationModel(
      id: 'bcg',
      userId: userId,
      vaccineName: 'BCG (Tuberculosis)',
      description: 'At birth',
      dueDate: birth,
    ),
    VaccinationModel(
      id: 'opv_0',
      userId: userId,
      vaccineName: 'OPV (Polio) – 0 dose',
      description: 'At birth',
      dueDate: birth,
    ),
    VaccinationModel(
      id: 'dpt_1',
      userId: userId,
      vaccineName: 'DPT + HepB + Hib – 1st dose',
      description: 'At 6 weeks',
      dueDate: birth.add(const Duration(days: 42)),
    ),
    VaccinationModel(
      id: 'dpt_2',
      userId: userId,
      vaccineName: 'DPT + HepB + Hib – 2nd dose',
      description: 'At 10 weeks',
      dueDate: birth.add(const Duration(days: 70)),
    ),
    VaccinationModel(
      id: 'dpt_3',
      userId: userId,
      vaccineName: 'DPT + HepB + Hib – 3rd dose',
      description: 'At 14 weeks',
      dueDate: birth.add(const Duration(days: 98)),
    ),
    VaccinationModel(
      id: 'mmr',
      userId: userId,
      vaccineName: 'MMR (Measles, Mumps, Rubella)',
      description: 'At 9 months',
      dueDate: birth.add(const Duration(days: 274)),
    ),
  ];
}

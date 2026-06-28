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
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      symptoms: map['symptoms'] != null ? List<String>.from(map['symptoms'] as List) : [],
      riskLevel: map['risk_level']?.toString() ?? 'low',
      advice: map['advice']?.toString() ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }
}

// Common pregnancy symptoms aligned with simplified bilingual plain language labels
const List<Map<String, dynamic>> commonSymptoms = [
  // High-Risk Emergency Symptoms (CRITICAL RED ZONE)
  {
    'name': 'Vaginal Bleeding or Spotting (Khoon aana ya dhabbe lagna)',
    'risk': 'high',
    'emoji': '🚨'
  },
  {
    'name': 'Severe, Unending Abdominal or Pelvic Pain (Pet ya kammar ke neeche ka tez dard jo theek na ho)',
    'risk': 'high',
    'emoji': '🚨'
  },
  {
    'name': 'Decreased or No Baby Movement (Bacche ki halchal kam hona ya band hona)',
    'risk': 'high',
    'emoji': '🚨'
  },
  {
    'name': 'Sudden Gush or Leaking of Fluid / Water Breaking (Achanak pani nikalna)',
    'risk': 'high',
    'emoji': '🚨'
  },
  {
    'name': 'Chills and High Fever over 101°F (Tez bukhar aur kapkapi)',
    'risk': 'high',
    'emoji': '🚨'
  },

  // High-Risk Warning Symptoms (YELLOW ZONE)
  {
    'name': 'Sudden Severe Swelling in Face, Hands, or Eyes (Chehre, hathon ya aankhon par achanak zyada soojan)',
    'risk': 'medium',
    'emoji': '⚠️'
  },
  {
    'name': 'Blurry Vision, Flashing Lights, or Severe Headaches (Aankhon ke samne dhundhlapan, roshni chamakna, ya lagaatar tez sir dard)',
    'risk': 'medium',
    'emoji': '⚠️'
  },
  {
    'name': 'Persistent Vomiting and Inability to Keep Fluids Down (Lagaatar ultiyan hona aur pani bhi na pachtana)',
    'risk': 'medium',
    'emoji': '⚠️'
  },
  {
    'name': 'Very High Blood Sugar or Extreme Thirst (Bahut zyada pyaas lagna aur thakan)',
    'risk': 'medium',
    'emoji': '⚠️'
  },
  {
    'name': 'Mild Fever (Halka bukhar)',
    'risk': 'medium',
    'emoji': '⚠️'
  },

  // Common / Mild Pregnancy Symptoms (GREEN ZONE)
  {
    'name': 'Morning Sickness / Nausea (Subah ji machlana)',
    'risk': 'low',
    'emoji': '🤢'
  },
  {
    'name': 'Heartburn / Acidity (Chhati mein jalan)',
    'risk': 'low',
    'emoji': '🔥'
  },
  {
    'name': 'Mild Fatigue / Tiredness (Halki thakan)',
    'risk': 'low',
    'emoji': '😴'
  },
  {
    'name': 'Frequent Urination (Baar baar peshab aana)',
    'risk': 'low',
    'emoji': '🚽'
  },
  {
    'name': 'Swollen Ankles or Feet (Paeron mein halki soojan)',
    'risk': 'low',
    'emoji': '🦶'
  },
  {
    'name': 'Back Pain (Peeth mein dard)',
    'risk': 'low',
    'emoji': '🔙'
  },
  // GyneCare / Period Support symptoms
  {
    'name': 'Severe Period Cramps / Lower Belly Pain (Periods ka tez dard)',
    'risk': 'low',
    'emoji': '🟢'
  },
  {
    'name': 'Normal White Discharge (Saaf pani aana - bina badboo/khujli ke)',
    'risk': 'low',
    'emoji': '🟢'
  },
  {
    'name': 'Period Fatigue & Mood Swings (Thakan aur chidchidapan)',
    'risk': 'low',
    'emoji': '🟢'
  },
  {
    'name': 'Irregular or Delayed Periods (Periods time par na aana)',
    'risk': 'medium',
    'emoji': '🟡'
  },
  {
    'name': 'Thick, Smelly White Discharge with Itching (Gaadha, badboodar pani aur khujli)',
    'risk': 'medium',
    'emoji': '🟡'
  },
  {
    'name': 'Heavy Bleeding lasting more than 7 Days (7 din se zyada bleeding)',
    'risk': 'medium',
    'emoji': '🟡'
  },
  {
    'name': 'Extreme Pain causing Fainting or Vomiting (Itna tez dard ki chakkar ya ulti aaye)',
    'risk': 'high',
    'emoji': '🔴'
  },
  {
    'name': 'Excessive Bleeding - Changing 1 Pad every hour (Bahut zyada bleeding hona)',
    'risk': 'high',
    'emoji': '🔴'
  },
  {
    'name': 'Missed Period with Severe One-Sided Pain (Period miss hona aur ek taraf tez dard)',
    'risk': 'high',
    'emoji': '🔴'
  },
  {
    'name': 'Bloating and breast tenderness (Pet phoolna aur stano mein dard)',
    'risk': 'low',
    'emoji': '🟢'
  },
  {
    'name': 'Mild lower back pain (Peeth ke neeche ka halka dard)',
    'risk': 'low',
    'emoji': '🟢'
  },
  {
    'name': 'Spotting between periods (Periods ke beech mein spotting ya khoon aana)',
    'risk': 'medium',
    'emoji': '🟡'
  },
  {
    'name': 'Pain during urination or intercourse (Peshab ya sambandh ke samay dard)',
    'risk': 'medium',
    'emoji': '🟡'
  },
  {
    'name': 'Missed period for more than 3 months (3 mahine se zyada period na aana)',
    'risk': 'medium',
    'emoji': '🟡'
  },
  {
    'name': 'Fever and chills with pelvic pain (Bukhar aur kapkapi ke sath pet ke neeche tez dard)',
    'risk': 'high',
    'emoji': '🔴'
  },
  {
    'name': 'Foul-smelling or purulent discharge with fever (Badboodar pani aana aur bukhar)',
    'risk': 'high',
    'emoji': '🔴'
  },
  {
    'name': 'Severe dizziness, fainting, or pale skin (Tez chakkar aana, behoshi, ya sharir peela padna)',
    'risk': 'high',
    'emoji': '🔴'
  }
];

const List<Map<String, dynamic>> gyneCareSymptoms = [
  // Period Comfort & Hygiene (GREEN ZONE)
  {
    'name': 'Severe Period Cramps / Lower Belly Pain (Periods ka tez dard)',
    'risk': 'low',
    'emoji': '🟢',
    'zone': 'Green Zone (Period Comfort & Hygiene)'
  },
  {
    'name': 'Normal White Discharge (Saaf pani aana - bina badboo/khujli ke)',
    'risk': 'low',
    'emoji': '🟢',
    'zone': 'Green Zone (Period Comfort & Hygiene)'
  },
  {
    'name': 'Period Fatigue & Mood Swings (Thakan aur chidchidapan)',
    'risk': 'low',
    'emoji': '🟢',
    'zone': 'Green Zone (Period Comfort & Hygiene)'
  },
  {
    'name': 'Bloating and breast tenderness (Pet phoolna aur stano mein dard)',
    'risk': 'low',
    'emoji': '🟢',
    'zone': 'Green Zone (Period Comfort & Hygiene)'
  },
  {
    'name': 'Mild lower back pain (Peeth ke neeche ka halka dard)',
    'risk': 'low',
    'emoji': '🟢',
    'zone': 'Green Zone (Period Comfort & Hygiene)'
  },
  // Gynaecological Consultation (YELLOW ZONE)
  {
    'name': 'Irregular or Delayed Periods (Periods time par na aana)',
    'risk': 'medium',
    'emoji': '🟡',
    'zone': 'Yellow Zone (Gynaecological Consultation)'
  },
  {
    'name': 'Thick, Smelly White Discharge with Itching (Gaadha, badboodar pani aur khujli)',
    'risk': 'medium',
    'emoji': '🟡',
    'zone': 'Yellow Zone (Gynaecological Consultation)'
  },
  {
    'name': 'Heavy Bleeding lasting more than 7 Days (7 din se zyada bleeding)',
    'risk': 'medium',
    'emoji': '🟡',
    'zone': 'Yellow Zone (Gynaecological Consultation)'
  },
  {
    'name': 'Spotting between periods (Periods ke beech mein spotting ya khoon aana)',
    'risk': 'medium',
    'emoji': '🟡',
    'zone': 'Yellow Zone (Gynaecological Consultation)'
  },
  {
    'name': 'Pain during urination or intercourse (Peshab ya sambandh ke samay dard)',
    'risk': 'medium',
    'emoji': '🟡',
    'zone': 'Yellow Zone (Gynaecological Consultation)'
  },
  {
    'name': 'Missed period for more than 3 months (3 mahine se zyada period na aana)',
    'risk': 'medium',
    'emoji': '🟡',
    'zone': 'Yellow Zone (Gynaecological Consultation)'
  },
  // Menstrual Emergency (CRITICAL RED ZONE)
  {
    'name': 'Extreme Pain causing Fainting or Vomiting (Itna tez dard ki chakkar ya ulti aaye)',
    'risk': 'high',
    'emoji': '🔴',
    'zone': 'Red Zone (Menstrual Emergency)'
  },
  {
    'name': 'Excessive Bleeding - Changing 1 Pad every hour (Bahut zyada bleeding hona)',
    'risk': 'high',
    'emoji': '🔴',
    'zone': 'Red Zone (Menstrual Emergency)'
  },
  {
    'name': 'Missed Period with Severe One-Sided Pain (Period miss hona aur ek taraf tez dard)',
    'risk': 'high',
    'emoji': '🔴',
    'zone': 'Red Zone (Menstrual Emergency)'
  },
  {
    'name': 'Fever and chills with pelvic pain (Bukhar aur kapkapi ke sath pet ke neeche tez dard)',
    'risk': 'high',
    'emoji': '🔴',
    'zone': 'Red Zone (Menstrual Emergency)'
  },
  {
    'name': 'Foul-smelling or purulent discharge with fever (Badboodar pani aana aur bukhar)',
    'risk': 'high',
    'emoji': '🔴',
    'zone': 'Red Zone (Menstrual Emergency)'
  },
  {
    'name': 'Severe dizziness, fainting, or pale skin (Tez chakkar aana, behoshi, ya sharir peela padna)',
    'risk': 'high',
    'emoji': '🔴',
    'zone': 'Red Zone (Menstrual Emergency)'
  },
];

String evaluateRisk(List<String> selectedSymptoms) {
  for (final symptom in gyneCareSymptoms) {
    if (selectedSymptoms.contains(symptom['name']) &&
        symptom['risk'] == 'high') {
      return 'high';
    }
  }
  for (final symptom in commonSymptoms) {
    if (selectedSymptoms.contains(symptom['name']) &&
        symptom['risk'] == 'high') {
      return 'high';
    }
  }
  for (final symptom in gyneCareSymptoms) {
    if (selectedSymptoms.contains(symptom['name']) &&
        symptom['risk'] == 'medium') {
      return 'medium';
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

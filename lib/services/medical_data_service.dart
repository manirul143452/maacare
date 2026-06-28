import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/medical_models.dart';

class MedicalDataService {
  static final MedicalDataService _instance = MedicalDataService._internal();
  factory MedicalDataService() => _instance;
  MedicalDataService._internal();

  List<Disease> _diseases = [];
  Map<String, int> _symptomWeights = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    if (_isLoaded) return;

    try {
      final String response = await rootBundle.loadString('assets/data/medical_database/medical_database.json');
      final data = json.decode(response);

      _diseases = (data['diseases'] as List)
          .map((d) => Disease.fromJson(d))
          .toList();

      _symptomWeights = Map<String, int>.from(data['symptoms']);
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading medical database: $e');
    }
  }

  static const Map<String, String> _symptomLabels = {
    "morning_sickness_nausea": "Morning Sickness / Nausea (Subah ji machlana)",
    "heartburn_acidity": "Heartburn / Acidity (Chhati mein jalan)",
    "mild_fatigue_tiredness": "Mild Fatigue / Tiredness (Halki thakan)",
    "frequent_urination": "Frequent Urination (Baar baar peshab aana)",
    "swollen_ankles_feet": "Swollen Ankles or Feet (Paeron mein halki soojan)",
    "back_pain": "Back Pain (Peeth mein dard)",
    "severe_swelling": "Sudden Severe Swelling in Face, Hands, or Eyes (Chehre, hathon ya aankhon par achanak zyada soojan)",
    "blurry_vision_headache": "Blurry Vision, Flashing Lights, or Severe Headaches (Aankhon ke samne dhundhlapan, roshni chamakna, ya lagaatar tez sir dard)",
    "persistent_vomiting": "Persistent Vomiting and Inability to Keep Fluids Down (Lagaatar ultiyan hona aur pani bhi na pachtana)",
    "high_blood_sugar_thirst": "Very High Blood Sugar or Extreme Thirst (Bahut zyada pyaas lagna aur thakan)",
    "mild_fever": "Mild Fever (Halka bukhar)",
    "vaginal_bleeding_spotting": "Vaginal Bleeding or Spotting (Khoon aana ya dhabbe lagna)",
    "severe_abdominal_pelvic_pain": "Severe, Unending Abdominal or Pelvic Pain (Pet ya kammar ke neeche ka tez dard jo theek na ho)",
    "decreased_baby_movement": "Decreased or No Baby Movement (Bacche ki halchal kam hona ya band hona)",
    "fluid_leaking_water_breaking": "Sudden Gush or Leaking of Fluid / Water Breaking (Achanak pani nikalna)",
    "chills_high_fever": "Chills and High Fever over 101°F (Tez bukhar aur kapkapi)",
    "severe_period_cramps": "Severe Period Cramps / Lower Belly Pain (Periods ka tez dard)",
    "normal_white_discharge": "Normal White Discharge (Saaf pani aana - bina badboo/khujli ke)",
    "period_fatigue_mood_swings": "Period Fatigue & Mood Swings (Thakan aur chidchidapan)",
    "irregular_delayed_periods": "Irregular or Delayed Periods (Periods time par na aana)",
    "thick_smelly_white_discharge": "Thick, Smelly White Discharge with Itching (Gaadha, badboodar pani aur khujli)",
    "heavy_bleeding_7_days": "Heavy Bleeding lasting more than 7 Days (7 din se zyada bleeding)",
    "extreme_pain_fainting_vomiting": "Extreme Pain causing Fainting or Vomiting (Itna tez dard ki chakkar ya ulti aaye)",
    "excessive_bleeding_hourly": "Excessive Bleeding - Changing 1 Pad every hour (Bahut zyada bleeding hona)",
    "missed_period_one_sided_pain": "Missed Period with Severe One-Sided Pain (Period miss hona aur ek taraf tez dard)",
    "bloating_breast_tenderness": "Bloating and breast tenderness (Pet phoolna aur stano mein dard)",
    "mild_lower_back_pain": "Mild lower back pain (Peeth ke neeche ka halka dard)",
    "spotting_between_periods": "Spotting between periods (Periods ke beech mein spotting ya khoon aana)",
    "pain_urination_intercourse": "Pain during urination or intercourse (Peshab ya sambandh ke samay dard)",
    "missed_period_3_months": "Missed period for more than 3 months (3 mahine se zyada period na aana)",
    "fever_chills_pelvic_pain": "Fever and chills with pelvic pain (Bukhar aur kapkapi ke sath pet ke neeche tez dard)",
    "foul_discharge_fever": "Foul-smelling or purulent discharge with fever (Badboodar pani aana aur bukhar)",
    "dizziness_fainting_pale": "Severe dizziness, fainting, or pale skin (Tez chakkar aana, behoshi, ya sharir peela padna)"
  };

  List<String> getAllSymptoms() {
    return _symptomWeights.keys.map((s) => _formatSymptom(s)).toList()..sort();
  }

  String _formatSymptom(String symptom) {
    return _symptomLabels[symptom] ?? symptom;
  }

  String _reverseFormatSymptom(String formatted) {
    for (var entry in _symptomLabels.entries) {
      if (entry.value == formatted) {
        return entry.key;
      }
    }
    return formatted.toLowerCase().replaceAll(' ', '_');
  }

  List<DiagnosticResult> diagnose(List<String> selectedFormattedSymptoms) {
    if (selectedFormattedSymptoms.isEmpty) return [];

    final List<String> selectedKeys = selectedFormattedSymptoms
        .map((fs) => _reverseFormatSymptom(fs))
        .toList();

    List<DiagnosticResult> results = [];

    for (var disease in _diseases) {
      int matchWeight = 0;
      int diseaseTotalWeight = 0;
      List<String> matched = [];

      // Calculate total weight of all symptoms this disease HAS
      for (var s in disease.symptoms) {
        int weight = _symptomWeights[s] ?? 1;
        diseaseTotalWeight += weight;
        
        // Check if user has this symptom
        // We do a loose match because of naming inconsistencies in original dataset
        if (selectedKeys.contains(s.trim())) {
          matchWeight += weight;
          matched.add(_formatSymptom(s));
        }
      }

      if (matched.isNotEmpty) {
        double confidence = (matchWeight / diseaseTotalWeight) * 100;
        results.add(DiagnosticResult(
          disease: disease,
          confidence: confidence,
          matchedSymptoms: matched,
        ));
      }
    }

    // Sort by confidence descending
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }
}

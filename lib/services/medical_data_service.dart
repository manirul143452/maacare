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

  List<String> getAllSymptoms() {
    return _symptomWeights.keys.map((s) => _formatSymptom(s)).toList()..sort();
  }

  String _formatSymptom(String symptom) {
    return symptom.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ').trim();
  }

  String _reverseFormatSymptom(String formatted) {
    // Basic mapping back to key
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

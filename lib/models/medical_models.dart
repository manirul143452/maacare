class Disease {
  final String name;
  final String description;
  final List<String> precautions;
  final List<String> symptoms;

  Disease({
    required this.name,
    required this.description,
    required this.precautions,
    required this.symptoms,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      precautions: List<String>.from(json['precautions'] ?? []),
      symptoms: List<String>.from(json['symptoms'] ?? []),
    );
  }
}

class DiagnosticResult {
  final Disease disease;
  final double confidence;
  final List<String> matchedSymptoms;

  DiagnosticResult({
    required this.disease,
    required this.confidence,
    required this.matchedSymptoms,
  });
}

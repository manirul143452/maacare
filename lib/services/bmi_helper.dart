// ============================================================
//  BmiHelper – Medical BMI Engine & Boundaries Evaluator
// ============================================================

class BmiHelper {
  /// Calculate BMI score based on metric formula: weight_kg / (height_m)^2
  static double calculateBmi({required double heightCm, required double weightKg}) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightMeters = heightCm / 100.0;
    return weightKg / (heightMeters * heightMeters);
  }

  /// Get medical classification status category
  static String getBmiStatus(double bmi) {
    if (bmi <= 0.0) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Get specific cycle and hormonal wellness recommendation alert text
  static String getBmiAlert(double bmi) {
    if (bmi <= 0.0) return 'Please input valid height and weight values to evaluate.';
    if (bmi < 18.5) {
      return 'Irregular cycles alert: Consider increasing nutrient-dense healthy fats.';
    } else if (bmi < 25.0) {
      return 'Healthy weight status.';
    } else if (bmi < 30.0) {
      return 'Hormonal balancing alert: Pair complex carbs with daily 5-min period yoga.';
    } else {
      return 'Hormonal and cardiovascular wellness monitoring recommended.';
    }
  }
}

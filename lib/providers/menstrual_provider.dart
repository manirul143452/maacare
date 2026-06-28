import 'package:flutter/foundation.dart';
import '../services/maacare_backend_service.dart';

class MenstrualProvider extends ChangeNotifier {
  DateTime? _lastPeriodStartDate;
  int _averageCycleLength = 28;
  List<String> _loggedSymptoms = [];
  List<Map<String, dynamic>> _loggedSymptomDetails = [];
  bool _isLoading = false;

  DateTime? get lastPeriodStartDate => _lastPeriodStartDate;
  int get averageCycleLength => _averageCycleLength;
  List<String> get loggedSymptoms => _loggedSymptoms;
  List<Map<String, dynamic>> get loggedSymptomDetails => _loggedSymptomDetails;
  bool get isLoading => _isLoading;

  // ─────────────────── Calculations ───────────────────

  DateTime? get nextPeriodDate {
    if (_lastPeriodStartDate == null) return null;
    return _lastPeriodStartDate!.add(Duration(days: _averageCycleLength));
  }

  DateTime? get ovulationStartDate {
    if (nextPeriodDate == null) return null;
    return nextPeriodDate!.subtract(const Duration(days: 16));
  }

  DateTime? get ovulationEndDate {
    if (nextPeriodDate == null) return null;
    return nextPeriodDate!.subtract(const Duration(days: 12));
  }

  int get daysUntilNextPeriod {
    if (nextPeriodDate == null) return 0;
    final diff = nextPeriodDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isPeriodLate {
    if (nextPeriodDate == null) return false;
    final now = DateTime.now();
    // Late if current time is past next period date by at least 1 full day
    return now.isAfter(nextPeriodDate!) && now.difference(nextPeriodDate!).inDays >= 1;
  }

  int get daysLate {
    if (nextPeriodDate == null) return 0;
    if (!isPeriodLate) return 0;
    return DateTime.now().difference(nextPeriodDate!).inDays;
  }

  String get cyclePhase {
    if (_lastPeriodStartDate == null) return 'Unknown';
    final daysSinceStart = DateTime.now().difference(_lastPeriodStartDate!).inDays;
    final currentDay = (daysSinceStart % _averageCycleLength) + 1;

    if (currentDay >= 1 && currentDay <= 5) {
      return 'Menstrual';
    } else if (currentDay >= 6 && currentDay <= 13) {
      return 'Follicular';
    } else if (currentDay >= 14 && currentDay <= 16) {
      return 'Ovulatory';
    } else {
      return 'Luteal';
    }
  }

  // ─────────────────── Database Operations ───────────────────

  Future<void> loadMenstrualLogs(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final log = await MaaCareBackendService.instance.fetchMenstrualLogs(userId);
      if (log != null) {
        if (log['last_period_start_date'] != null) {
          _lastPeriodStartDate = DateTime.tryParse(log['last_period_start_date']);
        }
        _averageCycleLength = (log['average_cycle_length'] as int?) ?? 28;
        if (log['logged_symptoms'] != null) {
          final rawList = log['logged_symptoms'] as List;
          _loggedSymptoms = rawList.map((item) {
            if (item is Map) {
              return item['symptom_name'] as String;
            }
            return item.toString();
          }).toList();
          _loggedSymptomDetails = rawList.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return {
              'symptom_name': item.toString(),
              'severity_level': 'mild',
              'logged_at': DateTime.now().toIso8601String(),
              'cycle_phase': cyclePhase,
            };
          }).toList();
        } else {
          _loggedSymptoms = [];
          _loggedSymptomDetails = [];
        }
      } else {
        // Default init for new logs
        _lastPeriodStartDate = DateTime.now().subtract(const Duration(days: 14));
        _averageCycleLength = 28;
        _loggedSymptoms = [];
        _loggedSymptomDetails = [];
      }
    } catch (e) {
      debugPrint('Error loading menstrual logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePeriodDate(String userId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final logPayload = {
        'user_id': userId,
        'last_period_start_date': date.toIso8601String(),
        'average_cycle_length': _averageCycleLength,
        'logged_symptoms': _loggedSymptomDetails.isNotEmpty ? _loggedSymptomDetails : _loggedSymptoms,
      };
      final success = await MaaCareBackendService.instance.upsertMenstrualLogs(logPayload);
      if (success) {
        _lastPeriodStartDate = date;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error saving period date: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> saveSymptoms(String userId, List<String> symptoms) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> details = [];
      for (final s in symptoms) {
        final existing = _loggedSymptomDetails.firstWhere(
          (d) => d['symptom_name'] == s,
          orElse: () => <String, dynamic>{},
        );
        if (existing.isNotEmpty) {
          details.add(existing);
        } else {
          details.add({
            'symptom_name': s,
            'severity_level': 'mild',
            'logged_at': DateTime.now().toIso8601String(),
            'cycle_phase': cyclePhase,
          });
        }
      }

      final logPayload = {
        'user_id': userId,
        'last_period_start_date': _lastPeriodStartDate?.toIso8601String(),
        'average_cycle_length': _averageCycleLength,
        'logged_symptoms': details,
      };
      final success = await MaaCareBackendService.instance.upsertMenstrualLogs(logPayload);
      if (success) {
        _loggedSymptomDetails = details;
        _loggedSymptoms = symptoms;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error saving period symptoms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> saveDetailedSymptoms(String userId, List<Map<String, dynamic>> details) async {
    _isLoading = true;
    notifyListeners();

    try {
      final logPayload = {
        'user_id': userId,
        'last_period_start_date': _lastPeriodStartDate?.toIso8601String(),
        'average_cycle_length': _averageCycleLength,
        'logged_symptoms': details,
      };
      final success = await MaaCareBackendService.instance.upsertMenstrualLogs(logPayload);
      if (success) {
        _loggedSymptomDetails = details;
        _loggedSymptoms = details.map((d) => d['symptom_name'] as String).toList();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error saving detailed symptoms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> saveCycleParameters(String userId, {required int averageCycleLength, DateTime? lastPeriodStartDate}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final logPayload = {
        'user_id': userId,
        'last_period_start_date': lastPeriodStartDate?.toIso8601String() ?? _lastPeriodStartDate?.toIso8601String(),
        'average_cycle_length': averageCycleLength,
        'logged_symptoms': _loggedSymptoms,
      };
      final success = await MaaCareBackendService.instance.upsertMenstrualLogs(logPayload);
      if (success) {
        _averageCycleLength = averageCycleLength;
        if (lastPeriodStartDate != null) {
          _lastPeriodStartDate = lastPeriodStartDate;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error saving cycle parameters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}

// ============================================================
//  NutritionProvider – MaaCare state for nutrition plan credit gating
// ============================================================

import 'package:flutter/foundation.dart';
import '../services/maacare_backend_service.dart';

class NutritionProvider extends ChangeNotifier {
  int _freeCycleGenerationCount = 0;
  int _freePregnancyGenerationCount = 0;
  bool _isLoading = false;

  int get freeCycleGenerationCount => _freeCycleGenerationCount;
  int get freePregnancyGenerationCount => _freePregnancyGenerationCount;
  bool get isLoading => _isLoading;

  Future<void> loadCounts(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final sub = await MaaCareBackendService.instance.fetchUserSubscription(userId);
      if (sub != null) {
        _freeCycleGenerationCount = sub['free_cycle_generation_count'] as int? ?? 0;
        _freePregnancyGenerationCount = sub['free_pregnancy_generation_count'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading nutrition counts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> incrementCycleCount(String userId) async {
    final nextVal = _freeCycleGenerationCount + 1;
    _freeCycleGenerationCount = nextVal;
    notifyListeners();
    try {
      await MaaCareBackendService.instance.updateUserSubscription(userId, {
        'free_cycle_generation_count': nextVal,
      });
    } catch (e) {
      debugPrint('Error incrementing cycle count: $e');
    }
  }

  Future<void> incrementPregnancyCount(String userId) async {
    final nextVal = _freePregnancyGenerationCount + 1;
    _freePregnancyGenerationCount = nextVal;
    notifyListeners();
    try {
      await MaaCareBackendService.instance.updateUserSubscription(userId, {
        'free_pregnancy_generation_count': nextVal,
      });
    } catch (e) {
      debugPrint('Error incrementing pregnancy count: $e');
    }
  }
}

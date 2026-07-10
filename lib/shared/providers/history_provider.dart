import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/hive_database.dart';
import '../models/calculation_history.dart';

class HistoryNotifier extends StateNotifier<List<CalculationHistory>> {
  HistoryNotifier() : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    state = HiveDatabase.getHistory();
  }

  Future<void> addHistory(CalculationHistory history) async {
    await HiveDatabase.addHistory(history);
    _loadHistory();
  }

  Future<void> deleteHistory(String id) async {
    await HiveDatabase.deleteHistory(id);
    state = state.where((h) => h.id != id).toList();
  }

  Future<void> clearAll() async {
    await HiveDatabase.clearHistory();
    state = [];
  }

  List<CalculationHistory> getByCategory(String category) {
    return state.where((h) => h.category == category).toList();
  }

  List<CalculationHistory> getByCalculator(String calculatorId) {
    return state.where((h) => h.calculatorId == calculatorId).toList();
  }

  List<CalculationHistory> getRecent({int limit = 5}) {
    return state.take(limit).toList();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<CalculationHistory>>(
  (ref) => HistoryNotifier(),
);

final recentHistoryProvider = Provider<List<CalculationHistory>>((ref) {
  return ref.watch(historyProvider).take(10).toList();
});

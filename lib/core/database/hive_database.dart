import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/calculation_history.dart';
import '../../shared/models/app_settings.dart';
import '../constants/app_constants.dart';

class HiveDatabase {
  HiveDatabase._();

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CalculationHistoryAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    await Hive.openBox<CalculationHistory>(AppConstants.historyBox);
    await Hive.openBox<AppSettings>(AppConstants.settingsBox);
    await Hive.openBox<String>(AppConstants.favoritesBox);
  }

  static Box<CalculationHistory> get historyBox =>
      Hive.box<CalculationHistory>(AppConstants.historyBox);

  static Box<AppSettings> get settingsBox =>
      Hive.box<AppSettings>(AppConstants.settingsBox);

  static Box<String> get favoritesBox =>
      Hive.box<String>(AppConstants.favoritesBox);

  static AppSettings getSettings() {
    final box = settingsBox;
    if (box.isEmpty) {
      final defaults = AppSettings();
      box.put('settings', defaults);
      return defaults;
    }
    return box.get('settings') ?? AppSettings();
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await settingsBox.put('settings', settings);
  }

  static Future<void> addHistory(CalculationHistory history) async {
    final box = historyBox;
    final settings = getSettings();
    if (box.length >= settings.maxHistory) {
      final oldestKey = box.keys.first;
      await box.delete(oldestKey);
    }
    await box.put(history.id, history);
  }

  static List<CalculationHistory> getHistory() {
    return historyBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> deleteHistory(String id) async {
    await historyBox.delete(id);
  }

  static Future<void> clearHistory() async {
    await historyBox.clear();
  }

  static List<String> getFavorites() {
    return favoritesBox.values.toList();
  }

  static Future<void> addFavorite(String calculatorId) async {
    await favoritesBox.put(calculatorId, calculatorId);
  }

  static Future<void> removeFavorite(String calculatorId) async {
    await favoritesBox.delete(calculatorId);
  }

  static bool isFavorite(String calculatorId) {
    return favoritesBox.containsKey(calculatorId);
  }
}

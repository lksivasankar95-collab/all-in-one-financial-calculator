import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/hive_database.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _load();
  }

  void _load() {
    state = HiveDatabase.getSettings();
  }

  Future<void> setCurrency(String currency, String symbol) async {
    state = state.copyWith(currency: currency, currencySymbol: symbol);
    await HiveDatabase.saveSettings(state);
  }

  Future<void> setMaxHistory(int max) async {
    state = state.copyWith(maxHistory: max);
    await HiveDatabase.saveSettings(state);
  }

  Future<void> setHaptic(bool enabled) async {
    state = state.copyWith(hapticFeedback: enabled);
    await HiveDatabase.saveSettings(state);
  }

  Future<void> setShowChart(bool show) async {
    state = state.copyWith(showCalculationChart: show);
    await HiveDatabase.saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).currencySymbol;
});

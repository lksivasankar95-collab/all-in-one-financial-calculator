import 'package:hive_flutter/hive_flutter.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool biometricEnabled;

  @HiveField(1)
  String currency;

  @HiveField(2)
  String currencySymbol;

  @HiveField(3)
  int maxHistory;

  @HiveField(4)
  bool hapticFeedback;

  @HiveField(5)
  bool showCalculationChart;

  @HiveField(6)
  String language;

  AppSettings({
    this.biometricEnabled = false,
    this.currency = 'INR',
    this.currencySymbol = '₹',
    this.maxHistory = 100,
    this.hapticFeedback = true,
    this.showCalculationChart = true,
    this.language = 'en',
  });

  AppSettings copyWith({
    bool? biometricEnabled,
    String? currency,
    String? currencySymbol,
    int? maxHistory,
    bool? hapticFeedback,
    bool? showCalculationChart,
    String? language,
  }) {
    return AppSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      maxHistory: maxHistory ?? this.maxHistory,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      showCalculationChart: showCalculationChart ?? this.showCalculationChart,
      language: language ?? this.language,
    );
  }
}

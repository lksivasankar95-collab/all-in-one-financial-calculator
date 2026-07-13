import 'package:hive_flutter/hive_flutter.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  String currency;

  @HiveField(1)
  String currencySymbol;

  @HiveField(2)
  int maxHistory;

  @HiveField(3)
  bool hapticFeedback;

  @HiveField(4)
  bool showCalculationChart;

  @HiveField(5)
  String language;

  AppSettings({
    this.currency = 'INR',
    this.currencySymbol = '₹',
    this.maxHistory = 100,
    this.hapticFeedback = true,
    this.showCalculationChart = true,
    this.language = 'en',
  });

  AppSettings copyWith({
    String? currency,
    String? currencySymbol,
    int? maxHistory,
    bool? hapticFeedback,
    bool? showCalculationChart,
    String? language,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      maxHistory: maxHistory ?? this.maxHistory,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      showCalculationChart: showCalculationChart ?? this.showCalculationChart,
      language: language ?? this.language,
    );
  }
}

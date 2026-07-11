class AppConstants {
  AppConstants._();

  static const String appName = 'ShyBlack';
  static const String appFullName = 'All-in-One Financial Calculator';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.shyblack.calculator';

  // Hive Box Names
  static const String historyBox = 'calculation_history';
  static const String favoritesBox = 'favorites';
  static const String settingsBox = 'settings';

  // Hive Type IDs
  static const int historyTypeId = 0;
  static const int settingsTypeId = 1;
  static const int favoriteTypeId = 2;

  // Settings Keys
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyCurrency = 'currency';
  static const String keyLanguage = 'language';
  static const String keyMaxHistory = 'max_history';

  // Defaults
  static const int defaultMaxHistory = 100;
  static const String defaultCurrency = 'INR';
  static const String defaultCurrencySymbol = '₹';

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);

  // UI Constants
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 18.0;
  static const double radiusXL = 24.0;

  static const double paddingXS = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;

  static const double cardElevation = 0.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;

  // Calculator Categories
  static const String catInvestment = 'Investment';
  static const String catLoan = 'Loan';
  static const String catSavings = 'Savings';
  static const String catTax = 'Tax';
  static const String catBusiness = 'Business';
  static const String catUtility = 'Utility';
  static const String catBanking = 'Banking';
  static const String catInsurance = 'Insurance';
  static const String catRetirement = 'Retirement';
  static const String catRealEstate = 'Real Estate';
  static const String catStockMarket = 'Stock Market';
  static const String catCrypto = 'Crypto';

  // Currency List
  static const List<Map<String, String>> currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'CHF', 'symbol': 'Fr', 'name': 'Swiss Franc'},
  ];
}

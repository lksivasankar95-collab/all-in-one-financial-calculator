import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  bool get isSmallScreen => MediaQuery.sizeOf(this).width < 360;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : const Color(0xFF222222),
      ),
    );
  }
}

extension StringExtensions on String {
  double? toDoubleOrNull() => double.tryParse(replaceAll(',', '').trim());
  int? toIntOrNull() => int.tryParse(replaceAll(',', '').trim());
  bool get isNotBlankOrEmpty => trim().isNotEmpty;
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

extension DoubleExtensions on double {
  bool get isValidAmount => this > 0 && isFinite;
  double clampMin(double min) => this < min ? min : this;
}

extension NumExtensions on num {
  bool get isValidInput => this > 0 && isFinite;
}

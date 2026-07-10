import 'dart:math' as math;

class UtilityCalculators {
  UtilityCalculators._();

  // ─── Percentage ───────────────────────────────────────────────────────────

  static PercentageResult calculatePercentage({
    required double value,
    required double percent,
    required PercentageMode mode,
  }) {
    switch (mode) {
      case PercentageMode.percentOf:
        // X% of Y → result
        final result = percent * value / 100;
        return PercentageResult(
          result: result,
          explanation:
              '${_fmt(percent)}% of ${_fmt(value)} = ${_fmt(result)}',
        );

      case PercentageMode.percentChange:
        // % change from value to percent (using "percent" field as target)
        final change = percent - value;
        final result = value != 0 ? (change / value) * 100 : 0.0;
        final direction = result >= 0 ? 'increase' : 'decrease';
        return PercentageResult(
          result: result,
          explanation:
              '${_fmt(value)} → ${_fmt(percent)}: ${result.abs().toStringAsFixed(2)}% $direction',
        );

      case PercentageMode.whatPercent:
        // value is what % of percent
        final result = percent != 0 ? (value / percent) * 100 : 0.0;
        return PercentageResult(
          result: result,
          explanation:
              '${_fmt(value)} is ${result.toStringAsFixed(2)}% of ${_fmt(percent)}',
        );

      case PercentageMode.addPercent:
        // Add X% to value
        final addition = value * percent / 100;
        final result = value + addition;
        return PercentageResult(
          result: result,
          explanation:
              '${_fmt(value)} + ${_fmt(percent)}% (${_fmt(addition)}) = ${_fmt(result)}',
        );

      case PercentageMode.subtractPercent:
        // Subtract X% from value
        final subtraction = value * percent / 100;
        final result = value - subtraction;
        return PercentageResult(
          result: result,
          explanation:
              '${_fmt(value)} − ${_fmt(percent)}% (${_fmt(subtraction)}) = ${_fmt(result)}',
        );
    }
  }

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  // ─── Inflation ────────────────────────────────────────────────────────────

  static InflationResult calculateInflation({
    required double currentValue,
    required double inflationRate,
    required int years,
  }) {
    final futureValue =
        currentValue * math.pow(1 + inflationRate / 100, years);
    final inflationAmount = futureValue - currentValue;
    final purchasingPowerLoss =
        currentValue > 0 ? ((futureValue - currentValue) / futureValue) * 100 : 0.0;

    return InflationResult(
      futureValue: futureValue,
      inflationAmount: inflationAmount,
      purchasingPowerLoss: purchasingPowerLoss,
    );
  }

  // ─── Age Calculator ───────────────────────────────────────────────────────

  static AgeResult calculateAge({
    required DateTime dob,
    required DateTime targetDate,
  }) {
    int years = targetDate.year - dob.year;
    int months = targetDate.month - dob.month;
    int days = targetDate.day - dob.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(targetDate.year, targetDate.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    final totalDays = targetDate.difference(dob).inDays;
    final totalMonths = years * 12 + months;

    return AgeResult(
      years: years,
      months: months,
      days: days,
      totalDays: totalDays,
      totalMonths: totalMonths,
    );
  }

  // ─── Date Difference ──────────────────────────────────────────────────────

  static DateDiffResult calculateDateDiff({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    final totalDays = end.difference(start).inDays.abs();

    int workingDays = 0;
    int weekends = 0;
    final earliest = start.isBefore(end) ? start : end;
    for (int i = 0; i < totalDays; i++) {
      final d = earliest.add(Duration(days: i));
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
        weekends++;
      } else {
        workingDays++;
      }
    }

    // Decompose into years, months, days
    final later = start.isBefore(end) ? end : start;
    final earlier = start.isBefore(end) ? start : end;
    int years = later.year - earlier.year;
    int months = later.month - earlier.month;
    int days = later.day - earlier.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(later.year, later.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    return DateDiffResult(
      totalDays: totalDays,
      workingDays: workingDays,
      weekends: weekends,
      years: years,
      months: months,
      days: days,
    );
  }

  // ─── Unit Converter ───────────────────────────────────────────────────────

  static double convertUnit({
    required double value,
    required String fromUnit,
    required String toUnit,
    required String category,
  }) {
    if (fromUnit == toUnit) return value;

    switch (category) {
      case 'Length':
        return _convertLength(value, fromUnit, toUnit);
      case 'Weight':
        return _convertWeight(value, fromUnit, toUnit);
      case 'Temperature':
        return _convertTemperature(value, fromUnit, toUnit);
      case 'Area':
        return _convertArea(value, fromUnit, toUnit);
      default:
        return value;
    }
  }

  // All length units converted to metres first
  static const _lengthToMetre = {
    'km': 1000.0,
    'm': 1.0,
    'cm': 0.01,
    'mm': 0.001,
    'miles': 1609.344,
    'yards': 0.9144,
    'feet': 0.3048,
    'inches': 0.0254,
  };

  static double _convertLength(double v, String from, String to) {
    final metres = v * (_lengthToMetre[from] ?? 1.0);
    return metres / (_lengthToMetre[to] ?? 1.0);
  }

  // All weight units converted to grams first
  static const _weightToGram = {
    'kg': 1000.0,
    'g': 1.0,
    'mg': 0.001,
    'lbs': 453.592,
    'oz': 28.3495,
    'tons': 1000000.0,
  };

  static double _convertWeight(double v, String from, String to) {
    final grams = v * (_weightToGram[from] ?? 1.0);
    return grams / (_weightToGram[to] ?? 1.0);
  }

  static double _convertTemperature(double v, String from, String to) {
    // First convert to Celsius
    double celsius;
    switch (from) {
      case '°C':
        celsius = v;
        break;
      case '°F':
        celsius = (v - 32) * 5 / 9;
        break;
      case 'K':
        celsius = v - 273.15;
        break;
      default:
        celsius = v;
    }
    // Then convert from Celsius to target
    switch (to) {
      case '°C':
        return celsius;
      case '°F':
        return celsius * 9 / 5 + 32;
      case 'K':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  // All area units converted to sq metres first
  static const _areaToSqMetre = {
    'sq m': 1.0,
    'sq km': 1000000.0,
    'sq ft': 0.092903,
    'acres': 4046.856,
    'hectares': 10000.0,
  };

  static double _convertArea(double v, String from, String to) {
    final sqMetres = v * (_areaToSqMetre[from] ?? 1.0);
    return sqMetres / (_areaToSqMetre[to] ?? 1.0);
  }
}

// ─── Enums & Result Classes ───────────────────────────────────────────────────

enum PercentageMode {
  percentOf,
  percentChange,
  whatPercent,
  addPercent,
  subtractPercent,
}

class PercentageResult {
  final double result;
  final String explanation;

  const PercentageResult({required this.result, required this.explanation});
}

class InflationResult {
  final double futureValue;
  final double inflationAmount;
  final double purchasingPowerLoss;

  const InflationResult({
    required this.futureValue,
    required this.inflationAmount,
    required this.purchasingPowerLoss,
  });
}

class AgeResult {
  final int years;
  final int months;
  final int days;
  final int totalDays;
  final int totalMonths;

  const AgeResult({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.totalMonths,
  });
}

class DateDiffResult {
  final int totalDays;
  final int workingDays;
  final int weekends;
  final int years;
  final int months;
  final int days;

  const DateDiffResult({
    required this.totalDays,
    required this.workingDays,
    required this.weekends,
    required this.years,
    required this.months,
    required this.days,
  });
}

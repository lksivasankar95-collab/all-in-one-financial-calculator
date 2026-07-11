import 'dart:math' as math;
import 'dart:ui' show Color;

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

  // ─── BMI ─────────────────────────────────────────────────────────────────────

  static BmiResult calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    final healthyMin = 18.5 * heightM * heightM;
    final healthyMax = 24.9 * heightM * heightM;

    String category;
    Color categoryColor;
    String risk;

    if (bmi < 18.5) {
      category = 'Underweight';
      categoryColor = const Color(0xFF40C4FF);
      risk = 'You may be at risk of nutritional deficiencies and weakened immune function.';
    } else if (bmi < 25) {
      category = 'Normal';
      categoryColor = const Color(0xFF39FF14);
      risk = 'You are at a healthy weight for your height. Keep maintaining a balanced diet!';
    } else if (bmi < 30) {
      category = 'Overweight';
      categoryColor = const Color(0xFFFFC107);
      risk = 'You may be at risk of heart disease, high blood pressure, and diabetes.';
    } else {
      category = 'Obese';
      categoryColor = const Color(0xFFFF5252);
      risk = 'You are at high risk of serious health conditions. Consult a healthcare professional.';
    }

    return BmiResult(
      bmi: bmi,
      category: category,
      categoryColor: categoryColor,
      healthyWeightMin: healthyMin,
      healthyWeightMax: healthyMax,
      risk: risk,
    );
  }

  // ─── Fuel Cost ───────────────────────────────────────────────────────────────

  static FuelCostResult calculateFuelCost({
    required double distanceKm,
    required double mileageKmpl,
    required double fuelPricePerLiter,
    required double averageSpeedKmph,
  }) {
    final fuelRequired = distanceKm / mileageKmpl;
    final totalFuelCost = fuelRequired * fuelPricePerLiter;
    final costPerKm = fuelPricePerLiter / mileageKmpl;
    final tripDuration = distanceKm / averageSpeedKmph;

    return FuelCostResult(
      distance: distanceKm,
      mileage: mileageKmpl,
      fuelPrice: fuelPricePerLiter,
      fuelRequired: fuelRequired,
      totalFuelCost: totalFuelCost,
      costPerKm: costPerKm,
      tripDuration: tripDuration,
    );
  }

  // ─── Electricity Bill ────────────────────────────────────────────────────────

  static const List<ElectricitySlab> defaultSlabs = [
    ElectricitySlab(maxUnits: 100, ratePerUnit: 3.0),
    ElectricitySlab(maxUnits: 200, ratePerUnit: 4.5),
    ElectricitySlab(maxUnits: 300, ratePerUnit: 6.0),
    ElectricitySlab(maxUnits: 500, ratePerUnit: 7.5),
    ElectricitySlab(maxUnits: 999999, ratePerUnit: 9.0),
  ];

  static ElectricityResult calculateElectricityBill({
    required int unitsConsumed,
    required List<ElectricitySlab> slabs,
    required double fixedCharges,
  }) {
    final details = <SlabDetail>[];
    int remaining = unitsConsumed;
    double totalEnergyCharges = 0;

    for (int i = 0; i < slabs.length; i++) {
      final slab = slabs[i];
      final prevMax = i > 0 ? slabs[i - 1].maxUnits : 0;
      final slabUnits = slab.maxUnits - prevMax;

      final unitsInSlab = remaining > slabUnits ? slabUnits : remaining;
      if (unitsInSlab <= 0) break;

      final amount = unitsInSlab * slab.ratePerUnit;
      final slabLabel = i == slabs.length - 1
          ? '> ${slabs[i - 1].maxUnits}'
          : '${prevMax + 1}-${slab.maxUnits}';

      details.add(SlabDetail(
        slab: slabLabel,
        units: unitsInSlab.toDouble(),
        rate: slab.ratePerUnit,
        amount: amount,
      ));

      totalEnergyCharges += amount;
      remaining -= unitsInSlab;
    }

    final totalBill = totalEnergyCharges + fixedCharges;
    final avgRate = unitsConsumed > 0
        ? totalEnergyCharges / unitsConsumed
        : 0.0;

    return ElectricityResult(
      unitsConsumed: unitsConsumed.toDouble(),
      slabDetails: details,
      fixedCharges: fixedCharges,
      totalBill: totalBill,
      averageRatePerUnit: avgRate,
    );
  }

  // ─── Tip ─────────────────────────────────────────────────────────────────────

  static TipResult calculateTip({
    required double billAmount,
    required double tipPercent,
    required int splitCount,
  }) {
    final tipAmount = billAmount * tipPercent / 100;
    final totalAmount = billAmount + tipAmount;
    final perPersonAmount = totalAmount / splitCount;

    return TipResult(
      billAmount: billAmount,
      tipPercent: tipPercent,
      tipAmount: tipAmount,
      totalAmount: totalAmount,
      perPersonAmount: perPersonAmount,
    );
  }

  // ─── Split Bill ──────────────────────────────────────────────────────────────

  static SplitBillResult calculateSplitBill({
    required double billAmount,
    required double tipPercent,
    required double taxPercent,
    required int peopleCount,
  }) {
    final tipAmount = billAmount * tipPercent / 100;
    final taxAmount = billAmount * taxPercent / 100;
    final grandTotal = billAmount + tipAmount + taxAmount;
    final perPersonAmount = grandTotal / peopleCount;

    final shares = List.generate(
      peopleCount,
      (i) => PersonShare(
        name: 'Person ${i + 1}',
        amount: perPersonAmount,
        percentage: 100.0 / peopleCount,
      ),
    );

    return SplitBillResult(
      totalAmount: billAmount,
      tipAmount: tipAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      perPersonAmount: perPersonAmount,
      shares: shares,
    );
  }

  // ─── Percent Change ──────────────────────────────────────────────────────────

  static PercentChangeResult calculatePercentChange({
    required double oldValue,
    required double newValue,
  }) {
    final change = newValue - oldValue;
    final percentChange = oldValue != 0 ? (change / oldValue) * 100 : 0.0;
    final changeType = change > 0
        ? 'increase'
        : change < 0
            ? 'decrease'
            : 'no change';

    return PercentChangeResult(
      oldValue: oldValue,
      newValue: newValue,
      change: change,
      percentChange: percentChange,
      changeType: changeType,
    );
  }

  static PercentChangeResult calculateNewValue({
    required double oldValue,
    required double percentChange,
  }) {
    final change = oldValue * percentChange / 100;
    final newValue = oldValue + change;
    final changeType = change > 0
        ? 'increase'
        : change < 0
            ? 'decrease'
            : 'no change';

    return PercentChangeResult(
      oldValue: oldValue,
      newValue: newValue,
      change: change,
      percentChange: percentChange,
      changeType: changeType,
    );
  }

  static PercentChangeResult calculateOriginalValue({
    required double newValue,
    required double percentChange,
  }) {
    final oldValue = percentChange != -100
        ? newValue / (1 + percentChange / 100)
        : 0.0;
    final change = newValue - oldValue;
    final changeType = change > 0
        ? 'increase'
        : change < 0
            ? 'decrease'
            : 'no change';

    return PercentChangeResult(
      oldValue: oldValue,
      newValue: newValue,
      change: change,
      percentChange: percentChange,
      changeType: changeType,
    );
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

// ─── BMI Calculator ───────────────────────────────────────────────────────────

class BmiResult {
  final double bmi;
  final String category;
  final Color categoryColor;
  final double healthyWeightMin;
  final double healthyWeightMax;
  final String risk;

  const BmiResult({
    required this.bmi,
    required this.category,
    required this.categoryColor,
    required this.healthyWeightMin,
    required this.healthyWeightMax,
    required this.risk,
  });
}

// ─── Fuel Cost Calculator ─────────────────────────────────────────────────────

class FuelCostResult {
  final double distance;
  final double mileage;
  final double fuelPrice;
  final double fuelRequired;
  final double totalFuelCost;
  final double costPerKm;
  final double tripDuration;

  const FuelCostResult({
    required this.distance,
    required this.mileage,
    required this.fuelPrice,
    required this.fuelRequired,
    required this.totalFuelCost,
    required this.costPerKm,
    required this.tripDuration,
  });
}

// ─── Electricity Bill Calculator ──────────────────────────────────────────────

class ElectricitySlab {
  final int maxUnits;
  final double ratePerUnit;

  const ElectricitySlab({required this.maxUnits, required this.ratePerUnit});
}

class SlabDetail {
  final String slab;
  final double units;
  final double rate;
  final double amount;

  const SlabDetail({
    required this.slab,
    required this.units,
    required this.rate,
    required this.amount,
  });
}

class ElectricityResult {
  final double unitsConsumed;
  final List<SlabDetail> slabDetails;
  final double fixedCharges;
  final double totalBill;
  final double averageRatePerUnit;

  const ElectricityResult({
    required this.unitsConsumed,
    required this.slabDetails,
    required this.fixedCharges,
    required this.totalBill,
    required this.averageRatePerUnit,
  });
}

// ─── Tip Calculator ───────────────────────────────────────────────────────────

class TipResult {
  final double billAmount;
  final double tipPercent;
  final double tipAmount;
  final double totalAmount;
  final double perPersonAmount;

  const TipResult({
    required this.billAmount,
    required this.tipPercent,
    required this.tipAmount,
    required this.totalAmount,
    required this.perPersonAmount,
  });
}

// ─── Split Bill Calculator ────────────────────────────────────────────────────

class PersonShare {
  final String name;
  final double amount;
  final double percentage;

  const PersonShare({
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

class SplitBillResult {
  final double totalAmount;
  final double tipAmount;
  final double taxAmount;
  final double grandTotal;
  final double perPersonAmount;
  final List<PersonShare> shares;

  const SplitBillResult({
    required this.totalAmount,
    required this.tipAmount,
    required this.taxAmount,
    required this.grandTotal,
    required this.perPersonAmount,
    required this.shares,
  });
}

// ─── Percent Change Calculator ────────────────────────────────────────────────

class PercentChangeResult {
  final double oldValue;
  final double newValue;
  final double change;
  final double percentChange;
  final String changeType;

  const PercentChangeResult({
    required this.oldValue,
    required this.newValue,
    required this.change,
    required this.percentChange,
    required this.changeType,
  });
}

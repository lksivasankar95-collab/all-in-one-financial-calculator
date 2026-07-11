import 'dart:math';

class RealEstateCalculators {
  RealEstateCalculators._();

  static RentVsBuyResult calculateRentVsBuy({
    required double propertyPrice,
    required double rent,
    required double downPayment,
    required double loanRate,
    required int tenureYears,
    required double propertyTaxRate,
    required double maintenanceRate,
    required double rentIncrease,
    required double appreciation,
  }) {
    final double loanAmount = propertyPrice - downPayment;
    final int n = tenureYears * 12;
    final double r = loanRate / 1200;

    double emi;
    if (r == 0) {
      emi = loanAmount / n;
    } else {
      final double factor = pow(1 + r, n).toDouble();
      emi = (loanAmount * r * factor) / (factor - 1);
    }

    double totalBuyCost = downPayment;
    double totalRentCost = 0;
    double buyAssetValue = propertyPrice;
    double currentRent = rent;

    for (int year = 1; year <= tenureYears; year++) {
      final double annualEmi = emi * 12;
      final double annualTax = propertyPrice * propertyTaxRate / 100;
      final double annualMaintenance = propertyPrice * maintenanceRate / 100;
      totalBuyCost += annualEmi + annualTax + annualMaintenance;

      totalRentCost += currentRent * 12;
      currentRent *= (1 + rentIncrease / 100);

      buyAssetValue *= (1 + appreciation / 100);
    }

    final double netBuyCost = totalBuyCost - (buyAssetValue - loanAmount);
    final double netRentCost = totalRentCost;

    return RentVsBuyResult(
      totalBuyCost: totalBuyCost,
      totalRentCost: totalRentCost,
      buyAssetValue: buyAssetValue,
      netBuyCost: netBuyCost,
      netRentCost: netRentCost,
      monthlyEmi: emi,
    );
  }

  static RentalYieldResult calculateRentalYield({
    required double propertyPrice,
    required double annualRent,
    required double expenses,
  }) {
    final double netIncome = annualRent - expenses;
    final double grossYield =
        propertyPrice > 0 ? (annualRent / propertyPrice) * 100 : 0;
    final double netYield =
        propertyPrice > 0 ? (netIncome / propertyPrice) * 100 : 0;
    return RentalYieldResult(
      grossYield: grossYield,
      netYield: netYield,
      netIncome: netIncome,
    );
  }

  static PropertyValuationResult calculatePropertyValuation({
    required double builtUpArea,
    required double ratePerSqft,
    required double floorFactor,
    required double locationFactor,
    required double ageFactor,
  }) {
    final double baseValue = builtUpArea * ratePerSqft;
    final double adjustedValue =
        baseValue * floorFactor * locationFactor * ageFactor;
    return PropertyValuationResult(
      baseValue: baseValue,
      adjustedValue: adjustedValue,
      floorFactor: floorFactor,
      locationFactor: locationFactor,
      ageFactor: ageFactor,
    );
  }

  static StampDutyResult calculateStampDuty({
    required double propertyValue,
    required double stampDutyRate,
    required double registrationRate,
  }) {
    final double stampDuty = propertyValue * stampDutyRate / 100;
    final double registration = propertyValue * registrationRate / 100;
    final double totalCost = stampDuty + registration;
    return StampDutyResult(
      stampDuty: stampDuty,
      registration: registration,
      totalCost: totalCost,
    );
  }

  static ConstructionCostResult calculateConstructionCost({
    required double builtUpArea,
    required double constructionRatePerSqft,
    required double qualityFactor,
  }) {
    final double baseCost = builtUpArea * constructionRatePerSqft;
    final double totalCost = baseCost * qualityFactor;
    final double costPerSqft =
        builtUpArea > 0 ? totalCost / builtUpArea : 0;
    return ConstructionCostResult(
      baseCost: baseCost,
      totalCost: totalCost,
      costPerSqft: costPerSqft,
    );
  }
}

class RentVsBuyResult {
  final double totalBuyCost;
  final double totalRentCost;
  final double buyAssetValue;
  final double netBuyCost;
  final double netRentCost;
  final double monthlyEmi;
  const RentVsBuyResult({
    required this.totalBuyCost,
    required this.totalRentCost,
    required this.buyAssetValue,
    required this.netBuyCost,
    required this.netRentCost,
    required this.monthlyEmi,
  });
}

class RentalYieldResult {
  final double grossYield;
  final double netYield;
  final double netIncome;
  const RentalYieldResult({
    required this.grossYield,
    required this.netYield,
    required this.netIncome,
  });
}

class PropertyValuationResult {
  final double baseValue;
  final double adjustedValue;
  final double floorFactor;
  final double locationFactor;
  final double ageFactor;
  const PropertyValuationResult({
    required this.baseValue,
    required this.adjustedValue,
    required this.floorFactor,
    required this.locationFactor,
    required this.ageFactor,
  });
}

class StampDutyResult {
  final double stampDuty;
  final double registration;
  final double totalCost;
  const StampDutyResult({
    required this.stampDuty,
    required this.registration,
    required this.totalCost,
  });
}

class ConstructionCostResult {
  final double baseCost;
  final double totalCost;
  final double costPerSqft;
  const ConstructionCostResult({
    required this.baseCost,
    required this.totalCost,
    required this.costPerSqft,
  });
}

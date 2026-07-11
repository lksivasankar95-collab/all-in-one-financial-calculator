class InsuranceCalculators {
  InsuranceCalculators._();

  static TermInsuranceResult calculateTermInsurance({
    required int age,
    required double coverageAmount,
    required int termYears,
    required bool smoking,
  }) {
    final double baseRate = 0.5 + (age - 20) * 0.08;
    final double smokingLoading = smoking ? baseRate * 0.7 : 0;
    final double annualRatePerThousand = baseRate + smokingLoading;
    final double annualPremium =
        (coverageAmount / 1000) * annualRatePerThousand;
    final double monthlyPremium = annualPremium / 12;
    final double totalPremium = annualPremium * termYears;
    return TermInsuranceResult(
      annualPremium: annualPremium,
      monthlyPremium: monthlyPremium,
      totalPremium: totalPremium,
    );
  }

  static LifeInsuranceResult calculateLifeInsurance({
    required int age,
    required double coverageAmount,
    required int termYears,
  }) {
    final double baseRate = 0.6 + (age - 20) * 0.1;
    final double annualPremium = (coverageAmount / 1000) * baseRate;
    final double monthlyPremium = annualPremium / 12;
    final double totalPremium = annualPremium * termYears;
    return LifeInsuranceResult(
      annualPremium: annualPremium,
      monthlyPremium: monthlyPremium,
      totalPremium: totalPremium,
      coverageAmount: coverageAmount,
    );
  }

  static HealthInsuranceResult calculateHealthInsurance({
    required int age,
    required int familySize,
    required String cityType,
  }) {
    final double basePremium = 3000 + (age - 20) * 100;
    final double cityFactor =
        cityType == 'metro' ? 1.5 : (cityType == 'urban' ? 1.2 : 1.0);
    final double annualPremium = basePremium * familySize * cityFactor;
    final double monthlyPremium = annualPremium / 12;
    return HealthInsuranceResult(
      annualPremium: annualPremium,
      monthlyPremium: monthlyPremium,
      coverageAmount: familySize * 500000,
    );
  }

  static CarInsuranceResult calculateCarInsurance({
    required double carValue,
    required int ageOfCar,
    required double noClaimBonus,
  }) {
    final double basePremium = carValue * 0.03;
    final double depreciationFactor =
        (1 - (ageOfCar * 0.1)).clamp(0, 0.7);
    final double ncbDiscount = 1 - (noClaimBonus / 100);
    final double annualPremium =
        basePremium * depreciationFactor * ncbDiscount;
    final double idv = carValue * depreciationFactor;
    return CarInsuranceResult(
      annualPremium: annualPremium,
      idv: idv,
      noClaimBonus: noClaimBonus,
    );
  }

  static InsuranceNeedResult calculateInsuranceNeed({
    required double annualIncome,
    required double existingCoverage,
    required int dependents,
    required double liabilities,
  }) {
    final double incomeBasedCoverage = annualIncome * 12;
    final double dependentCoverage = dependents * 500000;
    final double recommendedCoverage = incomeBasedCoverage +
        dependentCoverage +
        liabilities -
        existingCoverage;
    final double actualCoverage =
        recommendedCoverage < 0 ? 0 : recommendedCoverage;
    final double monthlyPremium = (actualCoverage / 1000) * 0.8 / 12;
    return InsuranceNeedResult(
      recommendedCoverage: actualCoverage,
      monthlyPremium: monthlyPremium,
    );
  }
}

class TermInsuranceResult {
  final double annualPremium;
  final double monthlyPremium;
  final double totalPremium;
  const TermInsuranceResult({
    required this.annualPremium,
    required this.monthlyPremium,
    required this.totalPremium,
  });
}

class LifeInsuranceResult {
  final double annualPremium;
  final double monthlyPremium;
  final double totalPremium;
  final double coverageAmount;
  const LifeInsuranceResult({
    required this.annualPremium,
    required this.monthlyPremium,
    required this.totalPremium,
    required this.coverageAmount,
  });
}

class HealthInsuranceResult {
  final double annualPremium;
  final double monthlyPremium;
  final double coverageAmount;
  const HealthInsuranceResult({
    required this.annualPremium,
    required this.monthlyPremium,
    required this.coverageAmount,
  });
}

class CarInsuranceResult {
  final double annualPremium;
  final double idv;
  final double noClaimBonus;
  const CarInsuranceResult({
    required this.annualPremium,
    required this.idv,
    required this.noClaimBonus,
  });
}

class InsuranceNeedResult {
  final double recommendedCoverage;
  final double monthlyPremium;
  const InsuranceNeedResult({
    required this.recommendedCoverage,
    required this.monthlyPremium,
  });
}

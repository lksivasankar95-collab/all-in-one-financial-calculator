import 'dart:math';

class RetirementCalculators {
  RetirementCalculators._();

  static FireResult calculateFire({
    required int currentAge,
    required int retirementAge,
    required double monthlyExpense,
    required double currentSavings,
    required double monthlySavings,
    required double expectedReturn,
    required double inflationRate,
    required double swr,
  }) {
    final double yearsToRetirement = retirementAge - currentAge;
    final double yearsInRetirement = 85 - retirementAge;

    final double inflatedExpense =
        monthlyExpense * pow(1 + inflationRate / 100, yearsToRetirement);

    final double annualExpense = inflatedExpense * 12;
    final double fireNumber = annualExpense / (swr / 100);

    final double realReturn = (expectedReturn - inflationRate) / 100;
    double corpusNeeded;
    if (realReturn <= 0) {
      corpusNeeded = annualExpense * yearsInRetirement;
    } else {
      corpusNeeded =
          annualExpense * ((1 - pow(1 + realReturn, -yearsInRetirement)) / realReturn);
    }

    final double fvCurrentSavings =
        currentSavings * pow(1 + expectedReturn / 100, yearsToRetirement);

    final double shortfall =
        (corpusNeeded - fvCurrentSavings).clamp(0, double.infinity);

    final double monthlyRate = expectedReturn / 1200;
    final int monthsToRetirement = (yearsToRetirement * 12).toInt();
    double monthlySavingsNeeded;
    if (shortfall <= 0) {
      monthlySavingsNeeded = 0;
    } else if (monthlyRate <= 0 || monthsToRetirement <= 0) {
      monthlySavingsNeeded = monthsToRetirement > 0
          ? shortfall / monthsToRetirement
          : shortfall;
    } else {
      final double fvFactor =
          ((pow(1 + monthlyRate, monthsToRetirement) - 1) / monthlyRate) *
              (1 + monthlyRate);
      monthlySavingsNeeded = shortfall / fvFactor;
    }

    double yearsToFI = 0;
    if (monthlySavings > 0 && currentSavings < corpusNeeded) {
      double tempCorpus = currentSavings;
      int months = 0;
      while (tempCorpus < corpusNeeded && months < 1200) {
        tempCorpus = tempCorpus * (1 + monthlyRate) + monthlySavings;
        months++;
      }
      yearsToFI = months / 12.0;
    }

    final bool isOnTrack = monthlySavings >= monthlySavingsNeeded;

    return FireResult(
      fireNumber: fireNumber,
      corpusNeeded: corpusNeeded,
      monthlySavingsNeeded: monthlySavingsNeeded,
      yearsToFI: yearsToFI,
      isOnTrack: isOnTrack,
    );
  }

  static RetirementCorpusResult calculateRetirementCorpus({
    required int currentAge,
    required int retirementAge,
    required int lifeExpectancy,
    required double monthlyExpense,
    required double inflation,
    required double returnRate,
    required double currentSavings,
  }) {
    final double yearsToRetirement = retirementAge - currentAge;
    final double yearsInRetirement = lifeExpectancy - retirementAge;

    final double inflatedExpense =
        monthlyExpense * pow(1 + inflation / 100, yearsToRetirement);
    final double annualExpense = inflatedExpense * 12;
    final double realReturn = (returnRate - inflation) / 100;

    double corpusNeeded;
    if (realReturn <= 0) {
      corpusNeeded = annualExpense * yearsInRetirement;
    } else {
      corpusNeeded =
          annualExpense * ((1 - pow(1 + realReturn, -yearsInRetirement)) / realReturn);
    }

    final double fvCurrentSavings =
        currentSavings * pow(1 + returnRate / 100, yearsToRetirement);
    final double monthlyRate = returnRate / 1200;
    final int monthsToRetirement = (yearsToRetirement * 12).toInt();
    final double shortfall =
        (corpusNeeded - fvCurrentSavings).clamp(0, double.infinity);

    double monthlySavingsNeeded;
    if (shortfall <= 0) {
      monthlySavingsNeeded = 0;
    } else if (monthlyRate <= 0 || monthsToRetirement <= 0) {
      monthlySavingsNeeded = monthsToRetirement > 0
          ? shortfall / monthsToRetirement
          : shortfall;
    } else {
      final double fvFactor =
          ((pow(1 + monthlyRate, monthsToRetirement) - 1) / monthlyRate) *
              (1 + monthlyRate);
      monthlySavingsNeeded = shortfall / fvFactor;
    }

    return RetirementCorpusResult(
      corpusNeeded: corpusNeeded,
      monthlySavingsNeeded: monthlySavingsNeeded,
      shortfall: shortfall,
      inflatedMonthlyExpense: inflatedExpense,
    );
  }

  static PensionResult calculatePension({
    required int currentAge,
    required int retirementAge,
    required double monthlyContribution,
    required double expectedReturn,
    required double annuityRate,
  }) {
    final int monthsToRetirement = (retirementAge - currentAge) * 12;
    final double monthlyRate = expectedReturn / 1200;

    double corpusAtRetirement;
    if (monthlyRate <= 0) {
      corpusAtRetirement = monthlyContribution * monthsToRetirement;
    } else {
      corpusAtRetirement = monthlyContribution *
          (((pow(1 + monthlyRate, monthsToRetirement) - 1) / monthlyRate) *
              (1 + monthlyRate));
    }

    final double totalContributions = monthlyContribution * monthsToRetirement;
    final double totalInterest = corpusAtRetirement - totalContributions;
    final double monthlyPension =
        corpusAtRetirement * (annuityRate / 100) / 12;

    return PensionResult(
      corpusAtRetirement: corpusAtRetirement,
      monthlyPension: monthlyPension,
      totalContributions: totalContributions,
      totalInterest: totalInterest,
    );
  }

  static AnnuityResult calculateAnnuity({
    required double corpus,
    required double annuityRate,
    required int termYears,
  }) {
    final double annualPayout = corpus * (annuityRate / 100);
    final double monthlyPayout = annualPayout / 12;
    final double totalPayout = annualPayout * termYears;
    return AnnuityResult(
      annualPayout: annualPayout,
      monthlyPayout: monthlyPayout,
      totalPayout: totalPayout,
    );
  }

  static WithdrawalResult calculateWithdrawal({
    required double corpus,
    required double annualWithdrawal,
    required double expectedReturn,
    required int years,
  }) {
    double remaining = corpus;
    double totalWithdrawn = 0;
    final List<double> yearlyBalances = [];
    final double r = expectedReturn / 100;

    for (int y = 0; y < years && remaining > 0; y++) {
      remaining = remaining * (1 + r) - annualWithdrawal;
      if (remaining < 0) remaining = 0;
      totalWithdrawn += annualWithdrawal;
      yearlyBalances.add(remaining);
    }

    final bool sustainable = remaining > 0;
    return WithdrawalResult(
      totalWithdrawn: totalWithdrawn,
      remainingCorpus: remaining < 0 ? 0 : remaining,
      sustainable: sustainable,
      yearlyBalances: yearlyBalances,
    );
  }
}

class FireResult {
  final double fireNumber;
  final double corpusNeeded;
  final double monthlySavingsNeeded;
  final double yearsToFI;
  final bool isOnTrack;
  const FireResult({
    required this.fireNumber,
    required this.corpusNeeded,
    required this.monthlySavingsNeeded,
    required this.yearsToFI,
    required this.isOnTrack,
  });
}

class RetirementCorpusResult {
  final double corpusNeeded;
  final double monthlySavingsNeeded;
  final double shortfall;
  final double inflatedMonthlyExpense;
  const RetirementCorpusResult({
    required this.corpusNeeded,
    required this.monthlySavingsNeeded,
    required this.shortfall,
    required this.inflatedMonthlyExpense,
  });
}

class PensionResult {
  final double corpusAtRetirement;
  final double monthlyPension;
  final double totalContributions;
  final double totalInterest;
  const PensionResult({
    required this.corpusAtRetirement,
    required this.monthlyPension,
    required this.totalContributions,
    required this.totalInterest,
  });
}

class AnnuityResult {
  final double annualPayout;
  final double monthlyPayout;
  final double totalPayout;
  const AnnuityResult({
    required this.annualPayout,
    required this.monthlyPayout,
    required this.totalPayout,
  });
}

class WithdrawalResult {
  final double totalWithdrawn;
  final double remainingCorpus;
  final bool sustainable;
  final List<double> yearlyBalances;
  const WithdrawalResult({
    required this.totalWithdrawn,
    required this.remainingCorpus,
    required this.sustainable,
    required this.yearlyBalances,
  });
}

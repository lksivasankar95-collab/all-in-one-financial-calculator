import 'dart:math';

class SavingsCalculators {
  SavingsCalculators._();

  // ─── Fixed Deposit ────────────────────────────────────────────────────────
  /// Compound: P * (1 + r/n)^(n*t)
  /// Simple:   P * (1 + r*t/100)
  static FdResult calculateFd({
    required double principal,
    required double annualRate,
    required int years,
    required int months,
    required int compoundingFrequency, // 0 = Simple Interest
  }) {
    final double t = years + months / 12.0;
    final double r = annualRate / 100;

    double maturityAmount;
    if (compoundingFrequency == 0) {
      // Simple Interest
      maturityAmount = principal * (1 + r * t);
    } else {
      final int n = compoundingFrequency;
      maturityAmount = principal * pow(1 + r / n, n * t);
    }

    final double interestEarned = maturityAmount - principal;

    // Effective Annual Rate
    double effectiveRate;
    if (compoundingFrequency == 0) {
      effectiveRate = annualRate;
    } else {
      effectiveRate = (pow(1 + r / compoundingFrequency, compoundingFrequency) - 1) * 100;
    }

    return FdResult(
      maturityAmount: maturityAmount,
      interestEarned: interestEarned,
      effectiveRate: effectiveRate,
    );
  }

  // ─── Recurring Deposit ────────────────────────────────────────────────────
  /// Exact formula: sum of each monthly installment compounded quarterly
  /// RD compounds quarterly in India: each installment grows for remaining quarters
  static RdResult calculateRd({
    required double monthlyDeposit,
    required double annualRate,
    required int years,
    required int months,
  }) {
    final int totalMonths = years * 12 + months;
    final double r = annualRate / 400; // quarterly rate

    double maturityAmount = 0;
    for (int i = 1; i <= totalMonths; i++) {
      // Each installment compounds for (totalMonths - i) months = (totalMonths - i)/3 quarters
      final double quartersRemaining = (totalMonths - i) / 3.0;
      maturityAmount += monthlyDeposit * pow(1 + r, quartersRemaining);
    }

    final double totalDeposited = monthlyDeposit * totalMonths;
    final double interestEarned = maturityAmount - totalDeposited;

    return RdResult(
      maturityAmount: maturityAmount,
      totalDeposited: totalDeposited,
      interestEarned: interestEarned,
    );
  }

  // ─── PPF ─────────────────────────────────────────────────────────────────
  /// PPF: yearly investment compounded annually for remaining years
  static PpfResult calculatePpf({
    required double yearlyInvestment,
    required double annualRate,
    required int years,
  }) {
    final double r = annualRate / 100;
    double maturityAmount = 0;

    for (int y = 1; y <= years; y++) {
      maturityAmount += yearlyInvestment * pow(1 + r, years - y + 1);
    }

    final double totalInvested = yearlyInvestment * years;
    final double interestEarned = maturityAmount - totalInvested;

    return PpfResult(
      maturityAmount: maturityAmount,
      totalInvested: totalInvested,
      interestEarned: interestEarned,
    );
  }

  // ─── EPF ─────────────────────────────────────────────────────────────────
  /// EPF: monthly contributions from both employee and employer, compounded monthly
  static EpfResult calculateEpf({
    required double basicSalary,
    required double employeeContrib, // percentage
    required double employerContrib, // percentage
    required double annualRate,
    required int years,
  }) {
    final double monthlyEmployee = basicSalary * employeeContrib / 100;
    final double monthlyEmployer = basicSalary * employerContrib / 100;
    final double totalMonthlyContrib = monthlyEmployee + monthlyEmployer;

    final int n = years * 12;
    final double r = annualRate / 1200;

    double maturityAmount;
    if (r == 0) {
      maturityAmount = totalMonthlyContrib * n;
    } else {
      maturityAmount = totalMonthlyContrib * (((pow(1 + r, n) - 1) / r) * (1 + r));
    }

    final double totalEmployeeContrib = monthlyEmployee * n;
    final double totalEmployerContrib = monthlyEmployer * n;
    final double totalContrib = totalEmployeeContrib + totalEmployerContrib;
    final double totalInterest = maturityAmount - totalContrib;

    return EpfResult(
      maturityAmount: maturityAmount,
      totalEmployeeContrib: totalEmployeeContrib,
      totalEmployerContrib: totalEmployerContrib,
      totalInterest: totalInterest,
    );
  }

  // ─── NPS ─────────────────────────────────────────────────────────────────
  /// NPS: monthly contribution compounded until retirement at 60
  static NpsResult calculateNps({
    required double monthlyContribution,
    required double annualRate,
    required int years, // years until retirement
    required double annuityRate, // annuity return rate %
    required double annuityPercent, // % of corpus used for annuity (40-100)
  }) {
    final int n = years * 12;
    final double r = annualRate / 1200;

    double corpusAtRetirement;
    if (r == 0) {
      corpusAtRetirement = monthlyContribution * n;
    } else {
      corpusAtRetirement = monthlyContribution * (((pow(1 + r, n) - 1) / r) * (1 + r));
    }

    final double annuityCorpus = corpusAtRetirement * annuityPercent / 100;
    final double lumpsum = corpusAtRetirement - annuityCorpus;

    // Monthly pension from annuity corpus
    final double monthlyAnnuityRate = annuityRate / 1200;
    double monthlyPension;
    if (monthlyAnnuityRate == 0) {
      monthlyPension = annuityCorpus / 240; // assume 20 years
    } else {
      monthlyPension = annuityCorpus * monthlyAnnuityRate;
    }

    return NpsResult(
      corpusAtRetirement: corpusAtRetirement,
      monthlyPension: monthlyPension,
      lumpsum: lumpsum,
    );
  }

  // ─── Retirement Corpus ───────────────────────────────────────────────────
  /// Calculates corpus needed and monthly savings required
  static RetirementResult calculateRetirement({
    required double currentAge,
    required double retirementAge,
    required double monthlyExpense,
    required double inflationRate,
    required double expectedReturn,
    required double currentSavings,
  }) {
    final double yearsToRetirement = retirementAge - currentAge;
    final double postRetirementYears = 85 - retirementAge; // assume life to 85

    // Monthly expense at retirement (inflation-adjusted)
    final double inflatedMonthlyExpense =
        monthlyExpense * pow(1 + inflationRate / 100, yearsToRetirement);

    // Real return rate (post-retirement)
    final double realReturn = (expectedReturn - inflationRate) / 100;

    // Corpus needed at retirement to sustain post-retirement expenses
    // Using Present Value of Annuity formula for post-retirement period
    double corpusNeeded;
    if (realReturn <= 0) {
      corpusNeeded = inflatedMonthlyExpense * 12 * postRetirementYears;
    } else {
      final double n = postRetirementYears;
      final double r = realReturn;
      corpusNeeded = inflatedMonthlyExpense * 12 * ((1 - pow(1 + r, -n)) / r);
    }

    // Future value of current savings
    final double fvCurrentSavings =
        currentSavings * pow(1 + expectedReturn / 100, yearsToRetirement);

    final double shortfall = (corpusNeeded - fvCurrentSavings).clamp(0, double.infinity);

    // Monthly savings needed using SIP FV formula
    final double monthlyRate = expectedReturn / 1200;
    final int monthsToRetirement = (yearsToRetirement * 12).toInt();
    double monthlySavingsNeeded;
    if (shortfall <= 0) {
      monthlySavingsNeeded = 0;
    } else if (monthlyRate == 0 || monthsToRetirement == 0) {
      monthlySavingsNeeded = monthsToRetirement > 0
          ? shortfall / monthsToRetirement
          : shortfall;
    } else {
      // FV = PMT * (((1+r)^n - 1) / r) * (1+r)
      // PMT = FV / (((1+r)^n - 1) / r) * (1+r)
      final double fvFactor =
          ((pow(1 + monthlyRate, monthsToRetirement) - 1) / monthlyRate) *
              (1 + monthlyRate);
      monthlySavingsNeeded = shortfall / fvFactor;
    }

    return RetirementResult(
      corpusNeeded: corpusNeeded,
      monthlySavingsNeeded: monthlySavingsNeeded,
      shortfall: shortfall,
    );
  }

  // ─── Emergency Fund ───────────────────────────────────────────────────────
  static EmergencyFundResult calculateEmergencyFund({
    required double monthlyExpense,
    required int months,
    required double existingSavings,
  }) {
    final double targetAmount = monthlyExpense * months;
    final double shortfall = (targetAmount - existingSavings).clamp(0, double.infinity);

    // Time to build if saving 20% of monthly expenses
    final double monthlySavingRate = monthlyExpense * 0.20;
    double monthsToAchieve;
    if (shortfall <= 0) {
      monthsToAchieve = 0;
    } else if (monthlySavingRate <= 0) {
      monthsToAchieve = double.infinity;
    } else {
      monthsToAchieve = shortfall / monthlySavingRate;
    }

    return EmergencyFundResult(
      targetAmount: targetAmount,
      shortfall: shortfall,
      monthsToAchieve: monthsToAchieve,
    );
  }

  // ─── Goal Savings ─────────────────────────────────────────────────────────
  /// PMT = (FV - PV*(1+r)^t) / (((1+r)^t - 1)/r)
  static GoalSavingsResult calculateGoalSavings({
    required double goalAmount,
    required double currentSavings,
    required double annualReturn,
    required int years,
  }) {
    final int n = years * 12;
    final double r = annualReturn / 1200;

    final double fvCurrentSavings = currentSavings * pow(1 + r, n);
    final double shortfall = (goalAmount - fvCurrentSavings).clamp(0, double.infinity);

    double monthlySavingsNeeded;
    if (shortfall <= 0 || r <= 0) {
      monthlySavingsNeeded = 0;
    } else {
      monthlySavingsNeeded = shortfall / ((pow(1 + r, n) - 1) / r);
    }

    final double totalContributions = monthlySavingsNeeded * n;
    final double totalInterest = goalAmount - currentSavings - totalContributions;

    return GoalSavingsResult(
      monthlySavingsNeeded: monthlySavingsNeeded,
      totalContributions: totalContributions,
      totalInterest: totalInterest,
      goalAmount: goalAmount,
    );
  }

  // ─── Monthly Savings ──────────────────────────────────────────────────────
  /// FV of annuity due: monthlyAmount * (((1+r)^n - 1) / r) * (1+r)
  static MonthlySavingsResult calculateMonthlySavings({
    required double monthlyAmount,
    required double annualReturn,
    required int years,
  }) {
    final int n = years * 12;
    final double r = annualReturn / 1200;

    double totalAfterYears;
    if (r <= 0) {
      totalAfterYears = monthlyAmount * n;
    } else {
      totalAfterYears = monthlyAmount * (((pow(1 + r, n) - 1) / r) * (1 + r));
    }

    final double totalContributions = monthlyAmount * n;
    final double totalInterest = totalAfterYears - totalContributions;
    final double effectiveRate = (pow(1 + r, 12) - 1) * 100;

    return MonthlySavingsResult(
      totalAfterYears: totalAfterYears,
      totalContributions: totalContributions,
      totalInterest: totalInterest,
      effectiveRate: effectiveRate,
    );
  }

  // ─── Education Savings ────────────────────────────────────────────────────
  static EducationSavingsResult calculateEducationSavings({
    required double currentCost,
    required double yearsUntilCollege,
    required double inflationRate,
    required double annualReturn,
    required double currentSavings,
  }) {
    final double futureEducationCost =
        currentCost * pow(1 + inflationRate / 100, yearsUntilCollege);

    final int n = (yearsUntilCollege * 12).toInt();
    final double r = annualReturn / 1200;

    final double fvCurrentSavings = currentSavings * pow(1 + r, n);
    final double shortfall = (futureEducationCost - fvCurrentSavings).clamp(0, double.infinity);

    double monthlySavingsNeeded;
    if (shortfall <= 0 || r <= 0) {
      monthlySavingsNeeded = 0;
    } else {
      monthlySavingsNeeded = shortfall / ((pow(1 + r, n) - 1) / r);
    }

    final double totalContributions = monthlySavingsNeeded * n;
    final double totalInterest = futureEducationCost - currentSavings - totalContributions;

    return EducationSavingsResult(
      futureEducationCost: futureEducationCost,
      monthlySavingsNeeded: monthlySavingsNeeded,
      totalContributions: totalContributions,
      totalInterest: totalInterest,
      shortfall: shortfall,
    );
  }

  // ─── Child Future Planning ────────────────────────────────────────────────
  static ChildFutureResult calculateChildFuturePlanning({
    required double goalAmount,
    required double childAge,
    required double targetAge,
    required double currentSavings,
    required double annualReturn,
  }) {
    final int years = (targetAge - childAge).toInt();
    final int n = years * 12;
    final double r = annualReturn / 1200;

    final double fvCurrentSavings = currentSavings * pow(1 + r, n);
    final double shortfall = (goalAmount - fvCurrentSavings).clamp(0, double.infinity);

    double monthlyInvestment;
    if (shortfall <= 0 || r <= 0) {
      monthlyInvestment = 0;
    } else {
      monthlyInvestment = shortfall / ((pow(1 + r, n) - 1) / r);
    }

    final double totalInvested = monthlyInvestment * n;
    final double totalInterest =
        goalAmount - currentSavings - totalInvested;
    final double futureValue = goalAmount;

    return ChildFutureResult(
      futureValue: futureValue,
      monthlyInvestment: monthlyInvestment,
      totalInvested: totalInvested,
      totalInterest: totalInterest,
    );
  }
}

// ─── Result Models ────────────────────────────────────────────────────────────

class FdResult {
  final double maturityAmount;
  final double interestEarned;
  final double effectiveRate;

  const FdResult({
    required this.maturityAmount,
    required this.interestEarned,
    required this.effectiveRate,
  });
}

class RdResult {
  final double maturityAmount;
  final double totalDeposited;
  final double interestEarned;

  const RdResult({
    required this.maturityAmount,
    required this.totalDeposited,
    required this.interestEarned,
  });
}

class PpfResult {
  final double maturityAmount;
  final double totalInvested;
  final double interestEarned;

  const PpfResult({
    required this.maturityAmount,
    required this.totalInvested,
    required this.interestEarned,
  });
}

class EpfResult {
  final double maturityAmount;
  final double totalEmployeeContrib;
  final double totalEmployerContrib;
  final double totalInterest;

  const EpfResult({
    required this.maturityAmount,
    required this.totalEmployeeContrib,
    required this.totalEmployerContrib,
    required this.totalInterest,
  });
}

class NpsResult {
  final double corpusAtRetirement;
  final double monthlyPension;
  final double lumpsum;

  const NpsResult({
    required this.corpusAtRetirement,
    required this.monthlyPension,
    required this.lumpsum,
  });
}

class RetirementResult {
  final double corpusNeeded;
  final double monthlySavingsNeeded;
  final double shortfall;

  const RetirementResult({
    required this.corpusNeeded,
    required this.monthlySavingsNeeded,
    required this.shortfall,
  });
}

class EmergencyFundResult {
  final double targetAmount;
  final double shortfall;
  final double monthsToAchieve;

  const EmergencyFundResult({
    required this.targetAmount,
    required this.shortfall,
    required this.monthsToAchieve,
  });
}

// ─── Goal Savings ──────────────────────────────────────────────────────────
class GoalSavingsResult {
  final double monthlySavingsNeeded;
  final double totalContributions;
  final double totalInterest;
  final double goalAmount;

  const GoalSavingsResult({
    required this.monthlySavingsNeeded,
    required this.totalContributions,
    required this.totalInterest,
    required this.goalAmount,
  });
}

// ─── Monthly Savings ───────────────────────────────────────────────────────
class MonthlySavingsResult {
  final double totalAfterYears;
  final double totalContributions;
  final double totalInterest;
  final double effectiveRate;

  const MonthlySavingsResult({
    required this.totalAfterYears,
    required this.totalContributions,
    required this.totalInterest,
    required this.effectiveRate,
  });
}

// ─── Education Savings ─────────────────────────────────────────────────────
class EducationSavingsResult {
  final double futureEducationCost;
  final double monthlySavingsNeeded;
  final double totalContributions;
  final double totalInterest;
  final double shortfall;

  const EducationSavingsResult({
    required this.futureEducationCost,
    required this.monthlySavingsNeeded,
    required this.totalContributions,
    required this.totalInterest,
    required this.shortfall,
  });
}

// ─── Child Future Planning ─────────────────────────────────────────────────
class ChildFutureResult {
  final double futureValue;
  final double monthlyInvestment;
  final double totalInvested;
  final double totalInterest;

  const ChildFutureResult({
    required this.futureValue,
    required this.monthlyInvestment,
    required this.totalInvested,
    required this.totalInterest,
  });
}

import 'dart:math';

class LoanCalculators {
  LoanCalculators._();

  // ─── EMI ─────────────────────────────────────────────────────────────────────
  /// P * r * (1+r)^n / ((1+r)^n - 1)
  /// where r = annualRate/1200, n = years*12
  static EmiResult calculateEmi({
    required double principal,
    required double annualRate,
    required int tenureYears,
  }) {
    final int n = tenureYears * 12;
    final double r = annualRate / 1200;

    double emi;
    if (r == 0) {
      emi = principal / n;
    } else {
      final double factor = pow(1 + r, n).toDouble();
      emi = (principal * r * factor) / (factor - 1);
    }

    final double totalAmount = emi * n;
    final double totalInterest = totalAmount - principal;

    return EmiResult(
      emi: emi,
      totalAmount: totalAmount,
      totalInterest: totalInterest,
      principalAmount: principal,
    );
  }

  // ─── Amortization Schedule ───────────────────────────────────────────────────
  static List<AmortizationRow> getAmortizationSchedule({
    required double principal,
    required double annualRate,
    required int tenureYears,
  }) {
    final int n = tenureYears * 12;
    final double r = annualRate / 1200;

    double emi;
    if (r == 0) {
      emi = principal / n;
    } else {
      final double factor = pow(1 + r, n).toDouble();
      emi = (principal * r * factor) / (factor - 1);
    }

    final List<AmortizationRow> schedule = [];
    double balance = principal;

    for (int month = 1; month <= n; month++) {
      final double interestPart = balance * r;
      final double principalPart = emi - interestPart;
      balance -= principalPart;
      if (balance < 0) balance = 0;

      schedule.add(AmortizationRow(
        month: month,
        emi: emi,
        principal: principalPart,
        interest: interestPart,
        balance: balance,
      ));
    }

    return schedule;
  }

  // ─── Loan Eligibility ────────────────────────────────────────────────────────
  /// maxEmi = (monthlyIncome - monthlyObligations) * foir
  /// maxLoan derived by inverting the EMI formula:
  ///   maxLoan = maxEmi * ((1+r)^n - 1) / (r * (1+r)^n)
  static double calculateMaxLoanEligibility({
    required double monthlyIncome,
    required double annualRate,
    required int tenureYears,
    required double foir,
  }) {
    final int n = tenureYears * 12;
    final double r = annualRate / 1200;
    final double maxEmi = monthlyIncome * foir;

    if (maxEmi <= 0) return 0;

    double maxLoan;
    if (r == 0) {
      maxLoan = maxEmi * n;
    } else {
      final double factor = pow(1 + r, n).toDouble();
      maxLoan = maxEmi * (factor - 1) / (r * factor);
    }

    return maxLoan < 0 ? 0 : maxLoan;
  }

  // ─── Prepayment ──────────────────────────────────────────────────────────────
  static PrepaymentResult calculatePrepayment({
    required double originalPrincipal,
    required double annualRate,
    required int originalTenureYears,
    required double prepaymentAmount,
    required int afterMonth,
  }) {
    final int totalMonths = originalTenureYears * 12;
    final double r = annualRate / 1200;

    double emi;
    if (r == 0) {
      emi = originalPrincipal / totalMonths;
    } else {
      final double factor = pow(1 + r, totalMonths).toDouble();
      emi = (originalPrincipal * r * factor) / (factor - 1);
    }

    // Total interest WITHOUT prepayment
    final double totalInterestWithout = (emi * totalMonths) - originalPrincipal;

    // Simulate loan to determine outstanding balance after `afterMonth` months
    double balance = originalPrincipal;
    double totalInterestPaid = 0;
    for (int m = 1; m <= afterMonth && balance > 0; m++) {
      final double interestPart = balance * r;
      final double principalPart = emi - interestPart;
      totalInterestPaid += interestPart;
      balance -= principalPart;
      if (balance < 0) balance = 0;
    }

    // Apply prepayment
    balance -= prepaymentAmount;
    if (balance < 0) balance = 0;

    // Calculate remaining interest after prepayment (same EMI, remaining months)
    double remainingInterest = 0;
    double tempBalance = balance;
    int monthsAfterPrepayment = 0;
    while (tempBalance > 0.01) {
      final double interestPart = tempBalance * r;
      final double principalPart = emi - interestPart;
      if (principalPart <= 0) break;
      remainingInterest += interestPart;
      tempBalance -= principalPart;
      monthsAfterPrepayment++;
      if (monthsAfterPrepayment > totalMonths * 2) break;
    }

    final double totalInterestWith =
        totalInterestPaid + remainingInterest;
    final double interestSaved =
        totalInterestWithout - totalInterestWith;
    final int originalRemainingMonths = totalMonths - afterMonth;
    final int monthsSaved =
        (originalRemainingMonths - monthsAfterPrepayment).clamp(0, totalMonths);

    return PrepaymentResult(
      originalEmi: emi,
      totalInterestWithout: totalInterestWithout,
      totalInterestWith: totalInterestWith < 0 ? 0 : totalInterestWith,
      interestSaved: interestSaved < 0 ? 0 : interestSaved,
      monthsSaved: monthsSaved,
    );
  }

  // ─── Balance Transfer ────────────────────────────────────────────────────────
  static BalanceTransferResult calculateBalanceTransfer({
    required double outstandingLoan,
    required double currentRate,
    required double newRate,
    required int remainingTenureYears,
  }) {
    final int n = remainingTenureYears * 12;
    final double rCurrent = currentRate / 1200;
    final double rNew = newRate / 1200;

    double currentEmi;
    if (rCurrent == 0) {
      currentEmi = outstandingLoan / n;
    } else {
      final double factor = pow(1 + rCurrent, n).toDouble();
      currentEmi = (outstandingLoan * rCurrent * factor) / (factor - 1);
    }

    double newEmi;
    if (rNew == 0) {
      newEmi = outstandingLoan / n;
    } else {
      final double factor = pow(1 + rNew, n).toDouble();
      newEmi = (outstandingLoan * rNew * factor) / (factor - 1);
    }

    final double emiSaved = currentEmi - newEmi;
    final double totalSavings = emiSaved * n;

    // Breakeven: 1% processing fee on outstanding loan / monthly savings
    final double processingFee = outstandingLoan * 0.01;
    final double processingFeeBreakeven =
        emiSaved > 0 ? processingFee / emiSaved : double.infinity;

    return BalanceTransferResult(
      currentEmi: currentEmi,
      newEmi: newEmi,
      emiSaved: emiSaved,
      totalSavings: totalSavings < 0 ? 0 : totalSavings,
      processingFeeBreakeven: processingFeeBreakeven,
    );
  }

  // ─── Mortgage Calculator ────────────────────────────────────────────────────
  static MortgageResult calculateMortgage({
    required double homePrice,
    required double downPaymentPercent,
    required double annualRate,
    required int years,
    required double annualPropertyTax,
    required double annualInsurance,
  }) {
    final double downPayment = homePrice * downPaymentPercent / 100;
    final double principal = homePrice - downPayment;
    final EmiResult emi = calculateEmi(
      principal: principal,
      annualRate: annualRate,
      tenureYears: years,
    );
    final double monthlyPropertyTax = annualPropertyTax / 12;
    final double monthlyInsurance = annualInsurance / 12;
    return MortgageResult(
      monthlyPayment: emi.emi,
      totalPayment: emi.totalAmount,
      totalInterest: emi.totalInterest,
      principalAmount: principal,
      propertyTax: monthlyPropertyTax,
      insurance: monthlyInsurance,
      totalMonthlyPayment: emi.emi + monthlyPropertyTax + monthlyInsurance,
      downPayment: downPayment,
    );
  }

  // ─── Home Loan Calculator ───────────────────────────────────────────────────
  static HomeLoanResult calculateHomeLoan({
    required double principal,
    required double annualRate,
    required int years,
    required double processingFeePercent,
  }) {
    final EmiResult emi = calculateEmi(
      principal: principal,
      annualRate: annualRate,
      tenureYears: years,
    );
    final double processingFee = principal * processingFeePercent / 100;
    final double netDisbursement = principal - processingFee;
    final List<AmortizationRow> schedule = getAmortizationSchedule(
      principal: principal,
      annualRate: annualRate,
      tenureYears: years,
    );
    return HomeLoanResult(
      emi: emi.emi,
      totalInterest: emi.totalInterest,
      totalAmount: emi.totalAmount,
      principalAmount: principal,
      processingFee: processingFee,
      netDisbursement: netDisbursement,
      schedule: schedule,
    );
  }

  // ─── Personal Loan Calculator ───────────────────────────────────────────────
  static PersonalLoanResult calculatePersonalLoan({
    required double principal,
    required double annualRate,
    required int years,
    required double processingFeePercent,
  }) {
    final EmiResult emi = calculateEmi(
      principal: principal,
      annualRate: annualRate,
      tenureYears: years,
    );
    final double processingFee = principal * processingFeePercent / 100;
    // APR approximation accounting for processing fee
    final double apr = annualRate + (processingFeePercent * 2 / years);
    return PersonalLoanResult(
      emi: emi.emi,
      totalInterest: emi.totalInterest,
      totalAmount: emi.totalAmount,
      principalAmount: principal,
      processingFee: processingFee,
      apr: apr,
    );
  }

  // ─── Car Loan Calculator ────────────────────────────────────────────────────
  static CarLoanResult calculateCarLoan({
    required double carPrice,
    required double downPaymentPercent,
    required double annualRate,
    required int years,
  }) {
    final double downPayment = carPrice * downPaymentPercent / 100;
    final double loanAmount = carPrice - downPayment;
    final EmiResult emi = calculateEmi(
      principal: loanAmount,
      annualRate: annualRate,
      tenureYears: years,
    );
    return CarLoanResult(
      emi: emi.emi,
      totalInterest: emi.totalInterest,
      totalAmount: emi.totalAmount,
      downPayment: downPayment,
      loanAmount: loanAmount,
      onRoadPrice: carPrice,
    );
  }

  // ─── Education Loan Calculator ──────────────────────────────────────────────
  static EducationLoanResult calculateEducationLoan({
    required double loanAmount,
    required double annualRate,
    required int courseYears,
    required int repaymentYears,
  }) {
    // Simple interest during moratorium (course period)
    final double moratoriumInterest =
        loanAmount * annualRate / 100 * courseYears;
    final double totalAfterMoratorium = loanAmount + moratoriumInterest;
    // EMI on total after moratorium for repayment period
    final int n = repaymentYears * 12;
    final double r = annualRate / 1200;
    double emi;
    if (r == 0) {
      emi = totalAfterMoratorium / n;
    } else {
      final double factor = pow(1 + r, n).toDouble();
      emi = (totalAfterMoratorium * r * factor) / (factor - 1);
    }
    final double totalPaid = emi * n;
    final double totalInterest = totalPaid - loanAmount;
    return EducationLoanResult(
      emi: emi,
      totalInterest: totalInterest,
      totalAmount: totalPaid,
      moratoriumInterest: moratoriumInterest,
      totalWithMoratorium: totalAfterMoratorium,
    );
  }

  // ─── Credit Card EMI Calculator ─────────────────────────────────────────────
  static CreditCardEmiResult calculateCreditCardEmi({
    required double amount,
    required double monthlyRate,
    required int months,
    required double processingFeePercent,
  }) {
    final double r = monthlyRate / 100;
    final double processingFee = amount * processingFeePercent / 100;
    double emi;
    if (r == 0) {
      emi = amount / months;
    } else {
      final double factor = pow(1 + r, months).toDouble();
      emi = (amount * r * factor) / (factor - 1);
    }
    final double totalAmount = emi * months;
    final double totalInterest = totalAmount - amount;
    // Effective annual rate
    final double effectiveRate = (pow(1 + r, 12) - 1) * 100;
    return CreditCardEmiResult(
      monthlyEmi: emi,
      totalInterest: totalInterest,
      totalAmount: totalAmount,
      processingFee: processingFee,
      effectiveRate: effectiveRate,
    );
  }

  // ─── DTI Calculator ─────────────────────────────────────────────────────────
  static DtiResult calculateDti({
    required double monthlyIncome,
    required List<double> monthlyDebts,
  }) {
    final double totalDebts = monthlyDebts.fold(0, (a, b) => a + b);
    final double dtiRatio =
        monthlyIncome > 0 ? (totalDebts / monthlyIncome) * 100 : 0;
    final bool isHealthy = dtiRatio < 36;
    final double availableForDebt = monthlyIncome * 0.43 - totalDebts;
    String status;
    if (dtiRatio < 36) {
      status = 'Healthy';
    } else if (dtiRatio <= 43) {
      status = 'Moderate';
    } else {
      status = 'Risky';
    }
    return DtiResult(
      dtiRatio: dtiRatio,
      totalMonthlyDebt: totalDebts,
      grossMonthlyIncome: monthlyIncome,
      availableForDebt: availableForDebt,
      isHealthy: isHealthy,
      status: status,
    );
  }
}

// ─── Result Models ────────────────────────────────────────────────────────────

class EmiResult {
  final double emi;
  final double totalAmount;
  final double totalInterest;
  final double principalAmount;

  const EmiResult({
    required this.emi,
    required this.totalAmount,
    required this.totalInterest,
    required this.principalAmount,
  });
}

class AmortizationRow {
  final int month;
  final double emi;
  final double principal;
  final double interest;
  final double balance;

  const AmortizationRow({
    required this.month,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

class PrepaymentResult {
  final double originalEmi;
  final double totalInterestWithout;
  final double totalInterestWith;
  final double interestSaved;
  final int monthsSaved;

  const PrepaymentResult({
    required this.originalEmi,
    required this.totalInterestWithout,
    required this.totalInterestWith,
    required this.interestSaved,
    required this.monthsSaved,
  });
}

class BalanceTransferResult {
  final double currentEmi;
  final double newEmi;
  final double emiSaved;
  final double totalSavings;
  final double processingFeeBreakeven;

  const BalanceTransferResult({
    required this.currentEmi,
    required this.newEmi,
    required this.emiSaved,
    required this.totalSavings,
    required this.processingFeeBreakeven,
  });
}

// ─── Mortgage Result ─────────────────────────────────────────────────────────
class MortgageResult {
  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;
  final double principalAmount;
  final double propertyTax;
  final double insurance;
  final double totalMonthlyPayment;
  final double downPayment;

  const MortgageResult({
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
    required this.principalAmount,
    required this.propertyTax,
    required this.insurance,
    required this.totalMonthlyPayment,
    required this.downPayment,
  });
}

// ─── Home Loan Result ────────────────────────────────────────────────────────
class HomeLoanResult {
  final double emi;
  final double totalInterest;
  final double totalAmount;
  final double principalAmount;
  final double processingFee;
  final double netDisbursement;
  final List<AmortizationRow> schedule;

  const HomeLoanResult({
    required this.emi,
    required this.totalInterest,
    required this.totalAmount,
    required this.principalAmount,
    required this.processingFee,
    required this.netDisbursement,
    required this.schedule,
  });
}

// ─── Personal Loan Result ────────────────────────────────────────────────────
class PersonalLoanResult {
  final double emi;
  final double totalInterest;
  final double totalAmount;
  final double principalAmount;
  final double processingFee;
  final double apr;

  const PersonalLoanResult({
    required this.emi,
    required this.totalInterest,
    required this.totalAmount,
    required this.principalAmount,
    required this.processingFee,
    required this.apr,
  });
}

// ─── Car Loan Result ─────────────────────────────────────────────────────────
class CarLoanResult {
  final double emi;
  final double totalInterest;
  final double totalAmount;
  final double downPayment;
  final double loanAmount;
  final double onRoadPrice;

  const CarLoanResult({
    required this.emi,
    required this.totalInterest,
    required this.totalAmount,
    required this.downPayment,
    required this.loanAmount,
    required this.onRoadPrice,
  });
}

// ─── Education Loan Result ───────────────────────────────────────────────────
class EducationLoanResult {
  final double emi;
  final double totalInterest;
  final double totalAmount;
  final double moratoriumInterest;
  final double totalWithMoratorium;

  const EducationLoanResult({
    required this.emi,
    required this.totalInterest,
    required this.totalAmount,
    required this.moratoriumInterest,
    required this.totalWithMoratorium,
  });
}

// ─── Credit Card EMI Result ──────────────────────────────────────────────────
class CreditCardEmiResult {
  final double monthlyEmi;
  final double totalInterest;
  final double totalAmount;
  final double processingFee;
  final double effectiveRate;

  const CreditCardEmiResult({
    required this.monthlyEmi,
    required this.totalInterest,
    required this.totalAmount,
    required this.processingFee,
    required this.effectiveRate,
  });
}

// ─── DTI Result ──────────────────────────────────────────────────────────────
class DtiResult {
  final double dtiRatio;
  final double totalMonthlyDebt;
  final double grossMonthlyIncome;
  final double availableForDebt;
  final bool isHealthy;
  final String status;

  const DtiResult({
    required this.dtiRatio,
    required this.totalMonthlyDebt,
    required this.grossMonthlyIncome,
    required this.availableForDebt,
    required this.isHealthy,
    required this.status,
  });
}

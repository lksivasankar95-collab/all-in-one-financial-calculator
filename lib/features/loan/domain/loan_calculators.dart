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

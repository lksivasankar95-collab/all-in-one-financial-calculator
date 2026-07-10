import 'dart:math';

class InvestmentCalculators {
  InvestmentCalculators._();

  // ─── SIP ────────────────────────────────────────────────────────────────────
  /// Monthly investment * (((1 + r)^n - 1) / r) * (1 + r)
  /// where r = annualRate / 1200, n = years * 12
  static SipResult calculateSip({
    required double monthlyInvestment,
    required double annualReturnRate,
    required int years,
  }) {
    final int n = years * 12;
    final double r = annualReturnRate / 1200;

    double totalValue;
    if (r == 0) {
      totalValue = monthlyInvestment * n;
    } else {
      totalValue =
          monthlyInvestment * (((pow(1 + r, n) - 1) / r) * (1 + r));
    }

    final double totalInvested = monthlyInvestment * n;
    final double estimatedReturns = totalValue - totalInvested;
    final double absoluteReturn =
        totalInvested > 0 ? (estimatedReturns / totalInvested) * 100 : 0;

    return SipResult(
      totalInvested: totalInvested,
      estimatedReturns: estimatedReturns,
      totalValue: totalValue,
      absoluteReturn: absoluteReturn,
    );
  }

  // ─── SWP ────────────────────────────────────────────────────────────────────
  /// Calculates how long a corpus sustains monthly withdrawals at a given return.
  static SwpResult calculateSwp({
    required double initialCorpus,
    required double monthlyWithdrawal,
    required double annualReturnRate,
  }) {
    if (monthlyWithdrawal <= 0) {
      return const SwpResult(
        monthsWithdrawalSustains: 0,
        totalWithdrawn: 0,
        remainingCorpus: 0,
      );
    }

    final double r = annualReturnRate / 1200;
    double corpus = initialCorpus;
    int months = 0;
    double totalWithdrawn = 0;

    // If withdrawal >= monthly interest and corpus is finite, limit to 1200 months
    while (corpus > 0 && months < 1200) {
      final double interest = corpus * r;
      corpus += interest;
      if (corpus <= monthlyWithdrawal) {
        totalWithdrawn += corpus;
        corpus = 0;
        months++;
        break;
      }
      corpus -= monthlyWithdrawal;
      totalWithdrawn += monthlyWithdrawal;
      months++;
    }

    return SwpResult(
      monthsWithdrawalSustains: months,
      totalWithdrawn: totalWithdrawn,
      remainingCorpus: corpus < 0 ? 0 : corpus,
    );
  }

  // ─── Lumpsum ─────────────────────────────────────────────────────────────────
  /// P * (1 + r/n)^(n*t)
  static LumpsumResult calculateLumpsum({
    required double principal,
    required double annualReturnRate,
    required int years,
    required int compoundingFrequency,
  }) {
    final double r = annualReturnRate / 100;
    final int n = compoundingFrequency;
    final int t = years;

    double totalValue;
    if (n == 0) {
      totalValue = principal * pow(1 + r, t);
    } else {
      totalValue = principal * pow(1 + r / n, n * t);
    }

    final double totalProfit = totalValue - principal;
    final double absoluteReturn =
        principal > 0 ? (totalProfit / principal) * 100 : 0;

    return LumpsumResult(
      totalValue: totalValue,
      totalProfit: totalProfit,
      absoluteReturn: absoluteReturn,
    );
  }

  // ─── CAGR ────────────────────────────────────────────────────────────────────
  /// (endValue/startValue)^(1/years) - 1
  static double calculateCagr({
    required double startValue,
    required double endValue,
    required int years,
  }) {
    if (startValue <= 0 || years <= 0) return 0;
    return (pow(endValue / startValue, 1 / years) - 1) * 100;
  }

  // ─── ROI ─────────────────────────────────────────────────────────────────────
  /// (netProfit / cost) * 100
  static double calculateRoi({
    required double investmentCost,
    required double finalValue,
  }) {
    if (investmentCost <= 0) return 0;
    return ((finalValue - investmentCost) / investmentCost) * 100;
  }

  // ─── Compound Interest ───────────────────────────────────────────────────────
  /// P*(1+r/n)^(nt) - P
  static CompoundResult calculateCompoundInterest({
    required double principal,
    required double rate,
    required int years,
    required int compoundsPerYear,
  }) {
    final double r = rate / 100;
    final int n = compoundsPerYear;
    final double maturityAmount =
        principal * pow(1 + r / n, n * years);
    final double interest = maturityAmount - principal;
    // Effective Annual Rate: (1 + r/n)^n - 1
    final double effectiveRate = (pow(1 + r / n, n) - 1) * 100;

    return CompoundResult(
      maturityAmount: maturityAmount,
      interest: interest,
      effectiveRate: effectiveRate,
    );
  }

  // ─── Simple Interest ─────────────────────────────────────────────────────────
  /// P*R*T/100
  static SimpleResult calculateSimpleInterest({
    required double principal,
    required double rate,
    required int years,
  }) {
    final double interest = (principal * rate * years) / 100;
    return SimpleResult(
      interest: interest,
      totalAmount: principal + interest,
    );
  }

  // ─── Year-by-Year Breakdown ───────────────────────────────────────────────────
  static List<YearlyData> getSipYearlyBreakdown({
    required double monthly,
    required double rate,
    required int years,
  }) {
    final List<YearlyData> data = [];
    final double r = rate / 1200;

    for (int y = 1; y <= years; y++) {
      final int n = y * 12;
      final double invested = monthly * n;
      double value;
      if (r == 0) {
        value = invested;
      } else {
        value = monthly * (((pow(1 + r, n) - 1) / r) * (1 + r));
      }
      data.add(YearlyData(year: y, invested: invested, value: value));
    }
    return data;
  }

  static List<YearlyData> getLumpsumYearlyBreakdown({
    required double principal,
    required double rate,
    required int years,
  }) {
    final List<YearlyData> data = [];
    final double r = rate / 100;

    for (int y = 1; y <= years; y++) {
      final double value = principal * pow(1 + r, y);
      data.add(YearlyData(year: y, invested: principal, value: value));
    }
    return data;
  }
}

// ─── Result Models ────────────────────────────────────────────────────────────

class SipResult {
  final double totalInvested;
  final double estimatedReturns;
  final double totalValue;
  final double absoluteReturn;

  const SipResult({
    required this.totalInvested,
    required this.estimatedReturns,
    required this.totalValue,
    required this.absoluteReturn,
  });
}

class SwpResult {
  final int monthsWithdrawalSustains;
  final double totalWithdrawn;
  final double remainingCorpus;

  const SwpResult({
    required this.monthsWithdrawalSustains,
    required this.totalWithdrawn,
    required this.remainingCorpus,
  });
}

class LumpsumResult {
  final double totalValue;
  final double totalProfit;
  final double absoluteReturn;

  const LumpsumResult({
    required this.totalValue,
    required this.totalProfit,
    required this.absoluteReturn,
  });
}

class CompoundResult {
  final double maturityAmount;
  final double interest;
  final double effectiveRate;

  const CompoundResult({
    required this.maturityAmount,
    required this.interest,
    required this.effectiveRate,
  });
}

class SimpleResult {
  final double interest;
  final double totalAmount;

  const SimpleResult({
    required this.interest,
    required this.totalAmount,
  });
}

class YearlyData {
  final int year;
  final double invested;
  final double value;

  const YearlyData({
    required this.year,
    required this.invested,
    required this.value,
  });
}

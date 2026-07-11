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

  // ─── XIRR ────────────────────────────────────────────────────────────────────
  /// Newton-Raphson method to solve for internal rate of return
  /// NPV = sum(cf_i / (1 + r)^(d_i/365)) = 0
  static XirrResult calculateXirr({
    required List<double> cashFlows,
    required List<int> days,
  }) {
    if (cashFlows.length < 2 || cashFlows.length != days.length) {
      return const XirrResult(
        xirr: 0,
        totalInvestment: 0,
        totalValue: 0,
        totalReturns: 0,
      );
    }

    double totalInvestment = 0;
    double totalValue = 0;
    for (int i = 0; i < cashFlows.length; i++) {
      if (cashFlows[i] < 0) {
        totalInvestment += cashFlows[i].abs();
      } else {
        totalValue += cashFlows[i];
      }
    }

    double r = 0.1;
    const int maxIter = 1000;
    const double tolerance = 1e-7;

    for (int iter = 0; iter < maxIter; iter++) {
      double f = 0;
      double fPrime = 0;

      for (int i = 0; i < cashFlows.length; i++) {
        final double cf = cashFlows[i];
        final double t = days[i] / 365.0;
        final double denom = pow(1 + r, t) as double;
        f += cf / denom;
        fPrime -= cf * t / (denom * (1 + r));
      }

      if (f.abs() < tolerance) break;

      if (fPrime.abs() < 1e-15) break;

      final double rNew = r - f / fPrime;

      if (rNew <= -0.9999) break;

      r = rNew;
    }

    final double xirr = r * 100;

    return XirrResult(
      xirr: xirr,
      totalInvestment: totalInvestment,
      totalValue: totalValue,
      totalReturns: totalValue - totalInvestment,
    );
  }

  // ─── Future Value ────────────────────────────────────────────────────────────
  /// FV = PV * (1+r)^t + PMT * (((1+r)^t - 1) / r)
  /// where PMT = monthlyAddition * 12, r = rate/100, t = years
  static FutureValueResult calculateFutureValue({
    required double presentValue,
    required double rate,
    required int years,
    required double monthlyAddition,
  }) {
    final double r = rate / 100;
    final double t = years.toDouble();
    final double pmt = monthlyAddition * 12;

    double futureValue;
    if (r == 0) {
      futureValue = presentValue + pmt * t;
    } else {
      final double compoundFactor = pow(1 + r, t) as double;
      futureValue = presentValue * compoundFactor + pmt * ((compoundFactor - 1) / r);
    }

    final double totalContributions = presentValue + pmt * t;
    final double totalInterest = futureValue - totalContributions;

    return FutureValueResult(
      futureValue: futureValue,
      totalContributions: totalContributions,
      totalInterest: totalInterest,
    );
  }

  // ─── Present Value ───────────────────────────────────────────────────────────
  /// PV = FV / (1+r)^t
  static PresentValueResult calculatePresentValue({
    required double futureValue,
    required double rate,
    required int years,
  }) {
    final double r = rate / 100;
    final double t = years.toDouble();

    final double discountFactor = pow(1 + r, t) as double;
    final double presentValue = futureValue / discountFactor;
    final double totalDiscount = futureValue - presentValue;

    return PresentValueResult(
      presentValue: presentValue,
      totalDiscount: totalDiscount,
    );
  }

  // ─── DCA ─────────────────────────────────────────────────────────────────────
  /// Simulates dollar-cost averaging with a price range and volatility
  static DcaResult calculateDcaSimple({
    required double monthlyInvestment,
    required double startPrice,
    required double endPrice,
    required int months,
    required double volatility,
  }) {
    double totalShares = 0;
    double totalInvested = 0;

    for (int i = 0; i < months; i++) {
      final double progress = months > 1 ? i / (months - 1) : 0;
      final double basePrice = startPrice + (endPrice - startPrice) * progress;
      final double fluctuation = volatility * startPrice * sin(2 * pi * i / 6);
      final double price = (basePrice + fluctuation).clamp(0.01, double.infinity);

      final double shares = monthlyInvestment / price;
      totalShares += shares;
      totalInvested += monthlyInvestment;
    }

    final double averageCost = totalShares > 0 ? totalInvested / totalShares : 0;
    final double currentValue = totalShares * endPrice;
    final double profitLoss = currentValue - totalInvested;
    final double profitLossPercent = totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0;

    return DcaResult(
      totalInvested: totalInvested,
      totalShares: totalShares,
      averageCost: averageCost,
      currentValue: currentValue,
      profitLoss: profitLoss,
      profitLossPercent: profitLossPercent,
    );
  }

  // ─── Rule of 72 ──────────────────────────────────────────────────────────────
  /// Years to double = 72 / rate
  static RuleOf72Result calculateRuleOf72({required double annualRate}) {
    if (annualRate <= 0) {
      return const RuleOf72Result(yearsToDouble: 0, actualYears: 0);
    }
    final double yearsToDouble = 72 / annualRate;
    final double actualYears = log(2) / log(1 + annualRate / 100);
    return RuleOf72Result(yearsToDouble: yearsToDouble, actualYears: actualYears);
  }

  // ─── Rule of 114 ─────────────────────────────────────────────────────────────
  /// Years to triple = 114 / rate
  static RuleOf114Result calculateRuleOf114({required double annualRate}) {
    if (annualRate <= 0) {
      return const RuleOf114Result(yearsToTriple: 0, actualYears: 0);
    }
    final double yearsToTriple = 114 / annualRate;
    final double actualYears = log(3) / log(1 + annualRate / 100);
    return RuleOf114Result(yearsToTriple: yearsToTriple, actualYears: actualYears);
  }

  // ─── Rule Comparison ─────────────────────────────────────────────────────────
  /// Returns both Rule of 72 and Rule of 114 results for comparison
  static (RuleOf72Result, RuleOf114Result) calculateRulesComparison({
    required double annualRate,
  }) {
    return (
      calculateRuleOf72(annualRate: annualRate),
      calculateRuleOf114(annualRate: annualRate),
    );
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

// ─── New Calculator Result Models ──────────────────────────────────────────

class XirrResult {
  final double xirr;
  final double totalInvestment;
  final double totalValue;
  final double totalReturns;

  const XirrResult({
    required this.xirr,
    required this.totalInvestment,
    required this.totalValue,
    required this.totalReturns,
  });
}

class FutureValueResult {
  final double futureValue;
  final double totalContributions;
  final double totalInterest;

  const FutureValueResult({
    required this.futureValue,
    required this.totalContributions,
    required this.totalInterest,
  });
}

class PresentValueResult {
  final double presentValue;
  final double totalDiscount;

  const PresentValueResult({
    required this.presentValue,
    required this.totalDiscount,
  });
}

class DcaResult {
  final double totalInvested;
  final double totalShares;
  final double averageCost;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercent;

  const DcaResult({
    required this.totalInvested,
    required this.totalShares,
    required this.averageCost,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercent,
  });
}

class RuleOf72Result {
  final double yearsToDouble;
  final double actualYears;

  const RuleOf72Result({
    required this.yearsToDouble,
    required this.actualYears,
  });
}

class RuleOf114Result {
  final double yearsToTriple;
  final double actualYears;

  const RuleOf114Result({
    required this.yearsToTriple,
    required this.actualYears,
  });
}

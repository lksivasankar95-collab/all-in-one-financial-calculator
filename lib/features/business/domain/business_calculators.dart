class BusinessCalculators {
  BusinessCalculators._();

  // ─── Profit Margin ────────────────────────────────────────────────────────

  static ProfitResult calculateProfitMargin({
    required double revenue,
    required double costOfGoods,
    required double operatingExpenses,
  }) {
    final grossProfit = revenue - costOfGoods;
    final grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;
    final netProfit = grossProfit - operatingExpenses;
    final netMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0.0;
    final markup = costOfGoods > 0 ? (grossProfit / costOfGoods) * 100 : 0.0;

    return ProfitResult(
      grossProfit: grossProfit,
      grossMargin: grossMargin,
      netProfit: netProfit,
      netMargin: netMargin,
      markup: markup,
    );
  }

  // ─── Discount ─────────────────────────────────────────────────────────────

  static DiscountResult calculateDiscount({
    required double originalPrice,
    required double discountPercent,
  }) {
    final discountAmount = originalPrice * discountPercent / 100;
    final finalPrice = originalPrice - discountAmount;
    final savings = discountAmount;

    return DiscountResult(
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      savings: savings,
    );
  }

  // ─── Commission ───────────────────────────────────────────────────────────

  static CommissionResult calculateCommission({
    required double saleAmount,
    required double commissionRate,
    required double baseCommission,
  }) {
    final commission = saleAmount * commissionRate / 100;
    final totalEarning = commission + baseCommission;
    final netSale = saleAmount - totalEarning;

    return CommissionResult(
      commission: commission,
      totalEarning: totalEarning,
      netSale: netSale,
    );
  }

  // ─── Break Even ───────────────────────────────────────────────────────────

  static BreakEvenResult calculateBreakEven({
    required double fixedCosts,
    required double sellingPricePerUnit,
    required double variableCostPerUnit,
  }) {
    final contributionMarginPerUnit = sellingPricePerUnit - variableCostPerUnit;
    final contributionMarginRatio = sellingPricePerUnit > 0
        ? (contributionMarginPerUnit / sellingPricePerUnit) * 100
        : 0.0;

    final breakEvenUnits = contributionMarginPerUnit > 0
        ? fixedCosts / contributionMarginPerUnit
        : 0.0;
    final breakEvenRevenue = breakEvenUnits * sellingPricePerUnit;

    return BreakEvenResult(
      breakEvenUnits: breakEvenUnits,
      breakEvenRevenue: breakEvenRevenue,
      contributionMarginPerUnit: contributionMarginPerUnit,
      contributionMarginRatio: contributionMarginRatio,
    );
  }
}

// ─── Result Classes ──────────────────────────────────────────────────────────

class ProfitResult {
  final double grossProfit;
  final double grossMargin;
  final double netProfit;
  final double netMargin;
  final double markup;

  const ProfitResult({
    required this.grossProfit,
    required this.grossMargin,
    required this.netProfit,
    required this.netMargin,
    required this.markup,
  });
}

class DiscountResult {
  final double discountAmount;
  final double finalPrice;
  final double savings;

  const DiscountResult({
    required this.discountAmount,
    required this.finalPrice,
    required this.savings,
  });
}

class CommissionResult {
  final double commission;
  final double totalEarning;
  final double netSale;

  const CommissionResult({
    required this.commission,
    required this.totalEarning,
    required this.netSale,
  });
}

class BreakEvenResult {
  final double breakEvenUnits;
  final double breakEvenRevenue;
  final double contributionMarginPerUnit;
  final double contributionMarginRatio;

  const BreakEvenResult({
    required this.breakEvenUnits,
    required this.breakEvenRevenue,
    required this.contributionMarginPerUnit,
    required this.contributionMarginRatio,
  });
}

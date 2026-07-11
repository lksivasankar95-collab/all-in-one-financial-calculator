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

  // ─── Profit & Loss (P&L) ─────────────────────────────────────────────────

  static PnLResult calculatePnL({
    required double revenue,
    required double cogs,
    required double salaries,
    required double rent,
    required double utilities,
    required double marketing,
    required double otherExpenses,
    required double otherIncome,
  }) {
    final grossProfit = revenue - cogs;
    final grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;
    final operatingExpenses =
        salaries + rent + utilities + marketing + otherExpenses;
    final operatingIncome = grossProfit - operatingExpenses;
    final netProfit = operatingIncome + otherIncome;
    final netMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0.0;
    final profitStatus = netProfit >= 0 ? 'Profit' : 'Loss';

    return PnLResult(
      revenue: revenue,
      costOfGoodsSold: cogs,
      grossProfit: grossProfit,
      grossMargin: grossMargin,
      operatingExpenses: operatingExpenses,
      operatingIncome: operatingIncome,
      otherIncome: otherIncome,
      netProfit: netProfit,
      netMargin: netMargin,
      profitStatus: profitStatus,
    );
  }

  // ─── Markup ───────────────────────────────────────────────────────────────

  static MarkupResult calculateMarkupFromCost({
    required double cost,
    required double markupPercent,
  }) {
    final sellingPrice = cost * (1 + markupPercent / 100);
    final markupAmount = sellingPrice - cost;
    final profitMargin =
        sellingPrice > 0 ? (markupAmount / sellingPrice) * 100 : 0.0;

    return MarkupResult(
      costPrice: cost,
      sellingPrice: sellingPrice,
      markupAmount: markupAmount,
      markupPercent: markupPercent,
      profitMargin: profitMargin,
    );
  }

  static MarkupResult calculateMarkupFromSelling({
    required double cost,
    required double sellingPrice,
  }) {
    final markupAmount = sellingPrice - cost;
    final markupPercent = cost > 0 ? (markupAmount / cost) * 100 : 0.0;
    final profitMargin =
        sellingPrice > 0 ? (markupAmount / sellingPrice) * 100 : 0.0;

    return MarkupResult(
      costPrice: cost,
      sellingPrice: sellingPrice,
      markupAmount: markupAmount,
      markupPercent: markupPercent,
      profitMargin: profitMargin,
    );
  }

  static MarkupResult calculateMarkupFromMargin({
    required double cost,
    required double marginPercent,
  }) {
    final sellingPrice = cost / (1 - marginPercent / 100);
    final markupAmount = sellingPrice - cost;
    final markupPercent = cost > 0 ? (markupAmount / cost) * 100 : 0.0;

    return MarkupResult(
      costPrice: cost,
      sellingPrice: sellingPrice,
      markupAmount: markupAmount,
      markupPercent: markupPercent,
      profitMargin: marginPercent,
    );
  }

  // ─── Invoice ──────────────────────────────────────────────────────────────

  static InvoiceResult calculateInvoice({
    required List<InvoiceLineItem> items,
    required double discountPercent,
    required double taxPercent,
    required double shipping,
  }) {
    final subtotal = items.fold<double>(
        0, (sum, item) => sum + item.quantity * item.unitPrice);
    final discountAmount = subtotal * discountPercent / 100;
    final taxableAmount = subtotal - discountAmount;
    final taxAmount = taxableAmount * taxPercent / 100;
    final total = taxableAmount + taxAmount + shipping;

    return InvoiceResult(
      subtotal: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      shipping: shipping,
      total: total,
      items: items,
    );
  }

  // ─── GST ──────────────────────────────────────────────────────────────────

  static GstResult calculateGstInclusive({
    required double totalAmount,
    required double gstRate,
  }) {
    final baseExclusive = totalAmount / (1 + gstRate / 100);
    final gstAmount = totalAmount - baseExclusive;

    return GstResult(
      originalAmount: totalAmount,
      gstRate: gstRate,
      gstAmount: gstAmount,
      totalInclusive: totalAmount,
      baseExclusive: baseExclusive,
      mode: 'Inclusive',
    );
  }

  static GstResult calculateGstExclusive({
    required double baseAmount,
    required double gstRate,
  }) {
    final gstAmount = baseAmount * gstRate / 100;
    final totalInclusive = baseAmount + gstAmount;

    return GstResult(
      originalAmount: baseAmount,
      gstRate: gstRate,
      gstAmount: gstAmount,
      totalInclusive: totalInclusive,
      baseExclusive: baseAmount,
      mode: 'Exclusive',
    );
  }

  // ─── Payroll ──────────────────────────────────────────────────────────────

  static PayrollResult calculatePayroll({
    required double grossSalary,
    required double basicPercent,
    required double hraPercent,
    required bool isEligibleForEsi,
    required double professionalTax,
  }) {
    final basicPay = grossSalary * basicPercent / 100;
    final hra = basicPay * hraPercent / 100;
    const conveyanceAllowance = 1600.0;
    const medicalAllowance = 1250.0;
    final specialAllowance = grossSalary -
        basicPay -
        hra -
        conveyanceAllowance -
        medicalAllowance;

    final pfEmployer = basicPay <= 15000 ? basicPay * 12 / 100 : 1800.0;
    final pfEmployee = basicPay <= 15000 ? basicPay * 12 / 100 : 1800.0;

    double esiEmployer = 0;
    double esiEmployee = 0;
    if (isEligibleForEsi && grossSalary <= 21000) {
      esiEmployer = grossSalary * 3.25 / 100;
      esiEmployee = grossSalary * 0.75 / 100;
    }

    final grossDeductions = pfEmployee + esiEmployee + professionalTax;
    final netSalary = grossSalary - grossDeductions;
    final ctc = (grossSalary + pfEmployer + esiEmployer) * 12;

    return PayrollResult(
      grossSalary: grossSalary,
      basicPay: basicPay,
      hra: hra,
      conveyanceAllowance: conveyanceAllowance,
      medicalAllowance: medicalAllowance,
      specialAllowance: specialAllowance,
      pfEmployer: pfEmployer,
      pfEmployee: pfEmployee,
      esiEmployer: esiEmployer,
      esiEmployee: esiEmployee,
      professionalTax: professionalTax,
      grossDeductions: grossDeductions,
      netSalary: netSalary,
      ctc: ctc,
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

// ─── P&L Result ─────────────────────────────────────────────────────────────

class PnLResult {
  final double revenue;
  final double costOfGoodsSold;
  final double grossProfit;
  final double grossMargin;
  final double operatingExpenses;
  final double operatingIncome;
  final double otherIncome;
  final double netProfit;
  final double netMargin;
  final String profitStatus;

  const PnLResult({
    required this.revenue,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.grossMargin,
    required this.operatingExpenses,
    required this.operatingIncome,
    required this.otherIncome,
    required this.netProfit,
    required this.netMargin,
    required this.profitStatus,
  });
}

// ─── Markup Result ──────────────────────────────────────────────────────────

class MarkupResult {
  final double costPrice;
  final double sellingPrice;
  final double markupAmount;
  final double markupPercent;
  final double profitMargin;

  const MarkupResult({
    required this.costPrice,
    required this.sellingPrice,
    required this.markupAmount,
    required this.markupPercent,
    required this.profitMargin,
  });
}

// ─── Invoice Result ─────────────────────────────────────────────────────────

class InvoiceLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class InvoiceResult {
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxableAmount;
  final double taxPercent;
  final double taxAmount;
  final double shipping;
  final double total;
  final List<InvoiceLineItem> items;

  const InvoiceResult({
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.shipping,
    required this.total,
    required this.items,
  });
}

// ─── GST Result ─────────────────────────────────────────────────────────────

class GstResult {
  final double originalAmount;
  final double gstRate;
  final double gstAmount;
  final double totalInclusive;
  final double baseExclusive;
  final String mode;

  const GstResult({
    required this.originalAmount,
    required this.gstRate,
    required this.gstAmount,
    required this.totalInclusive,
    required this.baseExclusive,
    required this.mode,
  });
}

// ─── Payroll Result ─────────────────────────────────────────────────────────

class PayrollResult {
  final double grossSalary;
  final double basicPay;
  final double hra;
  final double conveyanceAllowance;
  final double medicalAllowance;
  final double specialAllowance;
  final double pfEmployer;
  final double pfEmployee;
  final double esiEmployer;
  final double esiEmployee;
  final double professionalTax;
  final double grossDeductions;
  final double netSalary;
  final double ctc;

  const PayrollResult({
    required this.grossSalary,
    required this.basicPay,
    required this.hra,
    required this.conveyanceAllowance,
    required this.medicalAllowance,
    required this.specialAllowance,
    required this.pfEmployer,
    required this.pfEmployee,
    required this.esiEmployer,
    required this.esiEmployee,
    required this.professionalTax,
    required this.grossDeductions,
    required this.netSalary,
    required this.ctc,
  });
}

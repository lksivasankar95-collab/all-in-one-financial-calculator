class TaxCalculators {
  TaxCalculators._();

  // ─── GST ─────────────────────────────────────────────────────────────────

  static GstResult calculateGst({
    required double amount,
    required double gstRate,
    required bool isInclusive,
  }) {
    final double preTaxAmount;
    final double gstAmount;

    if (isInclusive) {
      // Remove GST from inclusive amount
      preTaxAmount = amount * 100 / (100 + gstRate);
      gstAmount = amount - preTaxAmount;
    } else {
      // Add GST to exclusive amount
      preTaxAmount = amount;
      gstAmount = amount * gstRate / 100;
    }

    final postTaxAmount = preTaxAmount + gstAmount;
    final cgst = gstAmount / 2;
    final sgst = gstAmount / 2;
    final igst = gstAmount;

    return GstResult(
      gstAmount: gstAmount,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      preTaxAmount: preTaxAmount,
      postTaxAmount: postTaxAmount,
    );
  }

  // ─── Income Tax FY 2024-25 ────────────────────────────────────────────────

  static IncomeTaxResult calculateIncomeTax({
    required double annualIncome,
    required double deductions80C,
    required double deductionsOther,
    required bool useNewRegime,
  }) {
    if (useNewRegime) {
      return _calcNewRegime(annualIncome);
    } else {
      return _calcOldRegime(annualIncome, deductions80C, deductionsOther);
    }
  }

  static IncomeTaxResult _calcNewRegime(double grossIncome) {
    const standardDeduction = 75000.0;
    final taxableIncome = (grossIncome - standardDeduction).clamp(0, double.infinity);

    double tax = 0;
    if (taxableIncome > 1500000) {
      tax += (taxableIncome - 1500000) * 0.30;
      tax += (1500000 - 1200000) * 0.20;
      tax += (1200000 - 1000000) * 0.15;
      tax += (1000000 - 700000) * 0.10;
      tax += (700000 - 300000) * 0.05;
    } else if (taxableIncome > 1200000) {
      tax += (taxableIncome - 1200000) * 0.20;
      tax += (1200000 - 1000000) * 0.15;
      tax += (1000000 - 700000) * 0.10;
      tax += (700000 - 300000) * 0.05;
    } else if (taxableIncome > 1000000) {
      tax += (taxableIncome - 1000000) * 0.15;
      tax += (1000000 - 700000) * 0.10;
      tax += (700000 - 300000) * 0.05;
    } else if (taxableIncome > 700000) {
      tax += (taxableIncome - 700000) * 0.10;
      tax += (700000 - 300000) * 0.05;
    } else if (taxableIncome > 300000) {
      tax += (taxableIncome - 300000) * 0.05;
    }

    // Section 87A rebate: full rebate if income <= 7L (taxable after std deduction)
    double rebate87A = 0;
    if (taxableIncome <= 700000) {
      rebate87A = tax;
    }

    final taxAfterRebate = (tax - rebate87A).clamp(0, double.infinity);
    final cess = taxAfterRebate * 0.04;
    final totalTax = taxAfterRebate + cess;
    final effectiveRate = grossIncome > 0 ? (totalTax / grossIncome) * 100 : 0.0;

    return IncomeTaxResult(
      taxableIncome: taxableIncome,
      taxBeforeRebate: tax,
      rebate87A: rebate87A,
      finalTax: taxAfterRebate,
      cess: cess,
      totalTaxPayable: totalTax,
      effectiveRate: effectiveRate,
      regime: 'New Regime',
    );
  }

  static IncomeTaxResult _calcOldRegime(
    double grossIncome,
    double deductions80C,
    double deductionsOther,
  ) {
    const standardDeduction = 50000.0;
    const max80C = 150000.0;
    final eff80C = deductions80C.clamp(0, max80C);
    final taxableIncome =
        (grossIncome - standardDeduction - eff80C - deductionsOther).clamp(0, double.infinity);

    double tax = 0;
    if (taxableIncome > 1000000) {
      tax += (taxableIncome - 1000000) * 0.30;
      tax += (1000000 - 500000) * 0.20;
      tax += (500000 - 250000) * 0.05;
    } else if (taxableIncome > 500000) {
      tax += (taxableIncome - 500000) * 0.20;
      tax += (500000 - 250000) * 0.05;
    } else if (taxableIncome > 250000) {
      tax += (taxableIncome - 250000) * 0.05;
    }

    // Section 87A rebate: full rebate if income <= 5L
    double rebate87A = 0;
    if (taxableIncome <= 500000) {
      rebate87A = tax;
    }

    final taxAfterRebate = (tax - rebate87A).clamp(0, double.infinity);
    final cess = taxAfterRebate * 0.04;
    final totalTax = taxAfterRebate + cess;
    final effectiveRate = grossIncome > 0 ? (totalTax / grossIncome) * 100 : 0.0;

    return IncomeTaxResult(
      taxableIncome: taxableIncome,
      taxBeforeRebate: tax,
      rebate87A: rebate87A,
      finalTax: taxAfterRebate,
      cess: cess,
      totalTaxPayable: totalTax,
      effectiveRate: effectiveRate,
      regime: 'Old Regime',
    );
  }

  // ─── HRA ─────────────────────────────────────────────────────────────────

  static HraResult calculateHra({
    required double basicSalary,
    required double hraReceived,
    required double rentPaid,
    required bool isMetroCity,
  }) {
    final annualBasic = basicSalary * 12;
    final annualHra = hraReceived * 12;
    final annualRent = rentPaid * 12;

    final conditionA = annualHra;
    final conditionB = annualBasic * (isMetroCity ? 0.50 : 0.40);
    final conditionC = (annualRent - annualBasic * 0.10).clamp(0, double.infinity);

    final exemption = [conditionA, conditionB, conditionC].reduce((a, b) => a < b ? a : b);
    final taxableHra = (annualHra - exemption).clamp(0, double.infinity);
    final annualSaving = exemption * 0.30; // Saving at 30% tax bracket

    return HraResult(
      exemption: exemption,
      taxableHra: taxableHra,
      annualSaving: annualSaving,
      conditionA: conditionA,
      conditionB: conditionB,
      conditionC: conditionC,
    );
  }

  // ─── Capital Gain ─────────────────────────────────────────────────────────

  static CapitalGainResult calculateCapitalGain({
    required double purchasePrice,
    required double salePrice,
    required bool isLongTerm,
    required bool isEquity,
    required double costInflationIndexRatio,
  }) {
    final gain = salePrice - purchasePrice;

    double indexedCost = purchasePrice;
    double taxableGain = gain;
    double taxRate = 0;

    if (isEquity) {
      if (isLongTerm) {
        // LTCG equity: 12.5% above ₹1.25L (Budget 2024)
        const exemptionLimit = 125000.0;
        taxableGain = gain > 0 ? (gain - exemptionLimit).clamp(0, double.infinity) : 0;
        taxRate = 12.5;
      } else {
        // STCG equity: 20% (Budget 2024)
        taxableGain = gain > 0 ? gain : 0;
        taxRate = 20.0;
      }
    } else {
      if (isLongTerm) {
        // LTCG debt: 20% with indexation
        indexedCost = purchasePrice * costInflationIndexRatio;
        taxableGain = (salePrice - indexedCost).clamp(0, double.infinity);
        taxRate = 20.0;
      } else {
        // STCG debt: slab rate (represented as 30% max bracket for display)
        taxableGain = gain > 0 ? gain : 0;
        taxRate = 30.0; // User's applicable slab rate
      }
    }

    final taxAmount = taxableGain * taxRate / 100;
    final effectiveRate = gain > 0 ? (taxAmount / gain) * 100 : 0.0;

    return CapitalGainResult(
      gain: gain,
      indexedCost: indexedCost,
      taxableGain: taxableGain,
      taxAmount: taxAmount,
      effectiveRate: effectiveRate,
      taxRate: taxRate,
    );
  }
}

// ─── Result Classes ──────────────────────────────────────────────────────────

class GstResult {
  final double gstAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double preTaxAmount;
  final double postTaxAmount;

  const GstResult({
    required this.gstAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.preTaxAmount,
    required this.postTaxAmount,
  });
}

class IncomeTaxResult {
  final double taxableIncome;
  final double taxBeforeRebate;
  final double rebate87A;
  final double finalTax;
  final double cess;
  final double totalTaxPayable;
  final double effectiveRate;
  final String regime;

  const IncomeTaxResult({
    required this.taxableIncome,
    required this.taxBeforeRebate,
    required this.rebate87A,
    required this.finalTax,
    required this.cess,
    required this.totalTaxPayable,
    required this.effectiveRate,
    required this.regime,
  });
}

class HraResult {
  final double exemption;
  final double taxableHra;
  final double annualSaving;
  final double conditionA;
  final double conditionB;
  final double conditionC;

  const HraResult({
    required this.exemption,
    required this.taxableHra,
    required this.annualSaving,
    required this.conditionA,
    required this.conditionB,
    required this.conditionC,
  });
}

class CapitalGainResult {
  final double gain;
  final double indexedCost;
  final double taxableGain;
  final double taxAmount;
  final double effectiveRate;
  final double taxRate;

  const CapitalGainResult({
    required this.gain,
    required this.indexedCost,
    required this.taxableGain,
    required this.taxAmount,
    required this.effectiveRate,
    required this.taxRate,
  });
}

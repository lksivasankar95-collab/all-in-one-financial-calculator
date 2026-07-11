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
    final taxableIncome = (grossIncome - standardDeduction).clamp(0, double.infinity).toDouble();

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

    final taxAfterRebate = (tax - rebate87A).clamp(0, double.infinity).toDouble();
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
    final eff80C = deductions80C.clamp(0, max80C).toDouble();
    final taxableIncome =
        (grossIncome - standardDeduction - eff80C - deductionsOther).clamp(0, double.infinity).toDouble();

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

    final taxAfterRebate = (tax - rebate87A).clamp(0, double.infinity).toDouble();
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
    final conditionC = (annualRent - annualBasic * 0.10).clamp(0, double.infinity).toDouble();

    final exemption = [conditionA, conditionB, conditionC].reduce((a, b) => a < b ? a : b);
    final taxableHra = (annualHra - exemption).clamp(0, double.infinity).toDouble();
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
        taxableGain = gain > 0 ? (gain - exemptionLimit).clamp(0, double.infinity).toDouble() : 0;
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
        taxableGain = (salePrice - indexedCost).clamp(0, double.infinity).toDouble();
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

  // ─── TDS ─────────────────────────────────────────────────────────────────

  static const Map<String, double> tdsSections = {
    '194A': 10.0,
    '194C': 1.0,
    '194H': 5.0,
    '194I': 10.0,
    '194J': 10.0,
    '194DA': 5.0,
  };

  static TdsResult calculateTds({
    required double amount,
    required String tdsSection,
    required double customRate,
  }) {
    final rate = tdsSections[tdsSection] ?? customRate;
    final tdsAmount = amount * rate / 100;
    final netAmount = amount - tdsAmount;

    return TdsResult(
      grossAmount: amount,
      tdsAmount: tdsAmount,
      netAmount: netAmount,
      tdsRate: rate,
      section: tdsSection,
    );
  }

  // ─── Salary Take Home ─────────────────────────────────────────────────────

  static SalaryResult calculateSalaryTakeHome({
    required double ctc,
    required double basicPercent,
    required double hraPercent,
    required double conveyanceAllowance,
    required double medicalAllowance,
    required double pfPercent,
    required double professionalTax,
    required bool isNewRegime,
  }) {
    final basic = ctc * basicPercent / 100;
    final hra = basic * hraPercent / 100;
    final otherAllowances = conveyanceAllowance + medicalAllowance;

    const standardDeduction = 50000.0;
    final pf = basic * pfPercent / 100;
    final grossDeductions = standardDeduction + pf + professionalTax;

    final taxableIncome = (ctc - grossDeductions).clamp(0, double.infinity).toDouble();

    double tax = 0;
    if (isNewRegime) {
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
    } else {
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
    }

    double rebate = 0;
    if (isNewRegime && taxableIncome <= 700000) {
      rebate = tax;
    } else if (!isNewRegime && taxableIncome <= 500000) {
      rebate = tax;
    }

    final taxAfterRebate = (tax - rebate).clamp(0, double.infinity).toDouble();
    final cess = taxAfterRebate * 0.04;
    final totalTax = taxAfterRebate + cess;
    final annualTakeHome = ctc - totalTax;
    final monthlyTakeHome = annualTakeHome / 12;

    return SalaryResult(
      grossAnnualSalary: ctc,
      basicPay: basic,
      hra: hra,
      otherAllowances: otherAllowances,
      grossDeductions: grossDeductions,
      taxableIncome: taxableIncome,
      taxAmount: taxAfterRebate,
      cessAmount: cess,
      totalTaxLiability: totalTax,
      monthlyTakeHome: monthlyTakeHome,
      annualTakeHome: annualTakeHome,
    );
  }

  // ─── Old vs New Tax Regime ────────────────────────────────────────────────

  static TaxRegimeResult calculateTaxRegimeComparison({
    required double grossIncome,
    required double hraExemption,
    required double section80c,
    required double section80d,
    required double nps,
    required double homeLoanInterest,
    required double otherDeductions,
  }) {
    const standardDeduction = 50000.0;
    const max80C = 150000.0;
    const max80D = 25000.0;
    const maxNps = 50000.0;
    const maxHomeLoan = 200000.0;

    final eff80C = section80c.clamp(0, max80C).toDouble();
    final eff80D = section80d.clamp(0, max80D).toDouble();
    final effNps = nps.clamp(0, maxNps).toDouble();
    final effHomeLoan = homeLoanInterest.clamp(0, maxHomeLoan).toDouble();

    final oldDeductions = standardDeduction + eff80C + eff80D + effNps + hraExemption + effHomeLoan + otherDeductions;
    final oldTaxableIncome = (grossIncome - oldDeductions).clamp(0, double.infinity).toDouble();
    final newTaxableIncome = (grossIncome - 50000).clamp(0, double.infinity).toDouble();

    double oldTax = 0;
    if (oldTaxableIncome > 1000000) {
      oldTax += (oldTaxableIncome - 1000000) * 0.30;
      oldTax += (1000000 - 500000) * 0.20;
      oldTax += (500000 - 250000) * 0.05;
    } else if (oldTaxableIncome > 500000) {
      oldTax += (oldTaxableIncome - 500000) * 0.20;
      oldTax += (500000 - 250000) * 0.05;
    } else if (oldTaxableIncome > 250000) {
      oldTax += (oldTaxableIncome - 250000) * 0.05;
    }
    if (oldTaxableIncome <= 500000) {
      oldTax = 0;
    }

    double newTax = 0;
    if (newTaxableIncome > 1500000) {
      newTax += (newTaxableIncome - 1500000) * 0.30;
      newTax += (1500000 - 1200000) * 0.20;
      newTax += (1200000 - 1000000) * 0.15;
      newTax += (1000000 - 700000) * 0.10;
      newTax += (700000 - 300000) * 0.05;
    } else if (newTaxableIncome > 1200000) {
      newTax += (newTaxableIncome - 1200000) * 0.20;
      newTax += (1200000 - 1000000) * 0.15;
      newTax += (1000000 - 700000) * 0.10;
      newTax += (700000 - 300000) * 0.05;
    } else if (newTaxableIncome > 1000000) {
      newTax += (newTaxableIncome - 1000000) * 0.15;
      newTax += (1000000 - 700000) * 0.10;
      newTax += (700000 - 300000) * 0.05;
    } else if (newTaxableIncome > 700000) {
      newTax += (newTaxableIncome - 700000) * 0.10;
      newTax += (700000 - 300000) * 0.05;
    } else if (newTaxableIncome > 300000) {
      newTax += (newTaxableIncome - 300000) * 0.05;
    }
    if (newTaxableIncome <= 700000) {
      newTax = 0;
    }

    final oldCess = oldTax * 0.04;
    final newCess = newTax * 0.04;
    final oldTotalTax = oldTax + oldCess;
    final newTotalTax = newTax + newCess;
    final savings = (oldTotalTax - newTotalTax).abs();
    final recommended = oldTotalTax <= newTotalTax ? 'Old Regime' : 'New Regime';

    return TaxRegimeResult(
      grossIncome: grossIncome,
      deductions: {
        'Standard Deduction': standardDeduction,
        'Section 80C': eff80C,
        'Section 80D': eff80D,
        'NPS (80CCD(1B))': effNps,
        'HRA Exemption': hraExemption,
        'Home Loan Interest': effHomeLoan,
        'Other Deductions': otherDeductions,
      },
      oldTaxableIncome: oldTaxableIncome,
      newTaxableIncome: newTaxableIncome,
      oldTax: oldTax,
      newTax: newTax,
      oldCess: oldCess,
      newCess: newCess,
      oldTotalTax: oldTotalTax,
      newTotalTax: newTotalTax,
      savings: savings,
      recommended: recommended,
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

// ─── TDS ────────────────────────────────────────────────────────────────────

class TdsResult {
  final double grossAmount;
  final double tdsAmount;
  final double netAmount;
  final double tdsRate;
  final String section;

  const TdsResult({
    required this.grossAmount,
    required this.tdsAmount,
    required this.netAmount,
    required this.tdsRate,
    required this.section,
  });
}

// ─── Salary Take Home ───────────────────────────────────────────────────────

class SalaryResult {
  final double grossAnnualSalary;
  final double basicPay;
  final double hra;
  final double otherAllowances;
  final double grossDeductions;
  final double taxableIncome;
  final double taxAmount;
  final double cessAmount;
  final double totalTaxLiability;
  final double monthlyTakeHome;
  final double annualTakeHome;

  const SalaryResult({
    required this.grossAnnualSalary,
    required this.basicPay,
    required this.hra,
    required this.otherAllowances,
    required this.grossDeductions,
    required this.taxableIncome,
    required this.taxAmount,
    required this.cessAmount,
    required this.totalTaxLiability,
    required this.monthlyTakeHome,
    required this.annualTakeHome,
  });
}

// ─── Old vs New Tax Regime ─────────────────────────────────────────────────

class TaxRegimeResult {
  final double grossIncome;
  final Map<String, double> deductions;
  final double oldTaxableIncome;
  final double newTaxableIncome;
  final double oldTax;
  final double newTax;
  final double oldCess;
  final double newCess;
  final double oldTotalTax;
  final double newTotalTax;
  final double savings;
  final String recommended;

  const TaxRegimeResult({
    required this.grossIncome,
    required this.deductions,
    required this.oldTaxableIncome,
    required this.newTaxableIncome,
    required this.oldTax,
    required this.newTax,
    required this.oldCess,
    required this.newCess,
    required this.oldTotalTax,
    required this.newTotalTax,
    required this.savings,
    required this.recommended,
  });
}

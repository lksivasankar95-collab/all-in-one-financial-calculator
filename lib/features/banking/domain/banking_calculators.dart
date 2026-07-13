class BankingCalculators {
  BankingCalculators._();

  static NetWorthResult calculateNetWorth({
    required List<AssetItem> assets,
    required List<LiabilityItem> liabilities,
  }) {
    final double totalAssets = assets.fold<double>(0.0, (sum, a) => sum + a.amount);
    final double totalLiabilities =
        liabilities.fold<double>(0.0, (sum, l) => sum + l.amount);
    final double netWorth = totalAssets - totalLiabilities;
    return NetWorthResult(
      netWorth: netWorth,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      assets: assets,
      liabilities: liabilities,
    );
  }

  static BankInterestResult calculateBankInterest({
    required double principal,
    required double rate,
    required int days,
  }) {
    final double interest = principal * rate * days / (365 * 100);
    final double maturityAmount = principal + interest;
    return BankInterestResult(
      interest: interest,
      maturityAmount: maturityAmount,
    );
  }

  static SavingsInterestResult calculateSavingsInterest({
    required double dailyBalance,
    required double rate,
    required int days,
  }) {
    final double interest = dailyBalance * rate * days / (365 * 100);
    final double totalBalance = dailyBalance + interest;
    return SavingsInterestResult(
      interest: interest,
      totalBalance: totalBalance,
    );
  }

  static CreditCardInterestResult calculateCreditCardInterest({
    required double outstandingBalance,
    required double annualRate,
    required int days,
  }) {
    final double dailyRate = annualRate / 365 / 100;
    final double interestCharged = outstandingBalance * dailyRate * days;
    final double totalDue = outstandingBalance + interestCharged;
    return CreditCardInterestResult(
      interestCharged: interestCharged,
      totalDue: totalDue,
    );
  }

  static CashFlowResult calculateCashFlow({
    required double income,
    required double expenses,
  }) {
    final double surplus = income - expenses;
    final double deficit = surplus < 0 ? surplus.abs() : 0;
    final double ratio =
        expenses > 0 ? income / expenses : (income > 0 ? double.infinity : 0);
    return CashFlowResult(
      surplus: surplus < 0 ? 0 : surplus,
      deficit: deficit,
      ratio: ratio,
    );
  }

  static BudgetResult calculateMonthlyBudget({
    required double income,
    required List<BudgetCategory> categories,
  }) {
    final double totalExpenses =
        categories.fold<double>(0.0, (sum, c) => sum + c.amount);
    final double surplus = income - totalExpenses;
    return BudgetResult(
      totalIncome: income,
      totalExpenses: totalExpenses,
      surplus: surplus,
      breakdown: categories,
    );
  }
}

class AssetItem {
  final String name;
  final double amount;
  const AssetItem({required this.name, required this.amount});
}

class LiabilityItem {
  final String name;
  final double amount;
  const LiabilityItem({required this.name, required this.amount});
}

class NetWorthResult {
  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final List<AssetItem> assets;
  final List<LiabilityItem> liabilities;

  const NetWorthResult({
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.assets,
    required this.liabilities,
  });
}

class BankInterestResult {
  final double interest;
  final double maturityAmount;
  const BankInterestResult({
    required this.interest,
    required this.maturityAmount,
  });
}

class SavingsInterestResult {
  final double interest;
  final double totalBalance;
  const SavingsInterestResult({
    required this.interest,
    required this.totalBalance,
  });
}

class CreditCardInterestResult {
  final double interestCharged;
  final double totalDue;
  const CreditCardInterestResult({
    required this.interestCharged,
    required this.totalDue,
  });
}

class CashFlowResult {
  final double surplus;
  final double deficit;
  final double ratio;
  const CashFlowResult({
    required this.surplus,
    required this.deficit,
    required this.ratio,
  });
}

class BudgetCategory {
  final String name;
  final double amount;
  const BudgetCategory({required this.name, required this.amount});
}

class BudgetResult {
  final double totalIncome;
  final double totalExpenses;
  final double surplus;
  final List<BudgetCategory> breakdown;

  const BudgetResult({
    required this.totalIncome,
    required this.totalExpenses,
    required this.surplus,
    required this.breakdown,
  });
}

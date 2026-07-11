import 'dart:math';

class CryptoCalculators {
  CryptoCalculators._();

  static CryptoProfitResult calculateCryptoProfit({
    required double entryPrice,
    required double exitPrice,
    required double quantity,
    required double fee,
  }) {
    final double totalEntry = entryPrice * quantity;
    final double totalExit = exitPrice * quantity;
    final double totalFees = (totalEntry + totalExit) * fee / 100;
    final double profitLoss = totalExit - totalEntry - totalFees;
    final double profitLossPercent =
        totalEntry > 0 ? (profitLoss / totalEntry) * 100 : 0;
    return CryptoProfitResult(
      totalEntry: totalEntry,
      totalExit: totalExit,
      totalFees: totalFees,
      profitLoss: profitLoss,
      profitLossPercent: profitLossPercent,
    );
  }

  static CryptoAverageResult calculateCryptoAverage({
    required List<CryptoHolding> holdings,
  }) {
    double totalQuantity = 0;
    double totalCost = 0;
    for (final h in holdings) {
      totalQuantity += h.quantity;
      totalCost += h.quantity * h.entryPrice;
    }
    final double averagePrice =
        totalQuantity > 0 ? totalCost / totalQuantity : 0;
    return CryptoAverageResult(
      averagePrice: averagePrice,
      totalQuantity: totalQuantity,
      totalCost: totalCost,
    );
  }

  static StakingResult calculateCryptoStaking({
    required double stakingAmount,
    required double apr,
    required int stakingPeriodDays,
    required int compoundingFrequency,
  }) {
    final double r = apr / 100;
    final double t = stakingPeriodDays / 365.0;

    double totalValue;
    if (compoundingFrequency <= 0) {
      totalValue = stakingAmount * (1 + r * t);
    } else {
      final int n = compoundingFrequency;
      totalValue = stakingAmount * pow(1 + r / n, n * t);
    }

    final double totalRewards = totalValue - stakingAmount;
    final double effectiveApr =
        (pow(1 + r / (365 / compoundingFrequency),
                (365 / compoundingFrequency)) -
            1) *
        100;

    return StakingResult(
      totalValue: totalValue,
      totalRewards: totalRewards,
      effectiveApr: effectiveApr,
    );
  }

  static DcaResult calculateCryptoDCA({
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
      final double basePrice =
          startPrice + (endPrice - startPrice) * progress;
      final double fluctuation =
          volatility * startPrice * sin(2 * pi * i / 6);
      final double price =
          (basePrice + fluctuation).clamp(0.01, double.infinity);

      final double shares = monthlyInvestment / price;
      totalShares += shares;
      totalInvested += monthlyInvestment;
    }

    final double averageCost =
        totalShares > 0 ? totalInvested / totalShares : 0;
    final double currentValue = totalShares * endPrice;
    final double profitLoss = currentValue - totalInvested;
    final double profitLossPercent =
        totalInvested > 0 ? (profitLoss / totalInvested) * 100 : 0;

    return DcaResult(
      totalInvested: totalInvested,
      totalShares: totalShares,
      averageCost: averageCost,
      currentValue: currentValue,
      profitLoss: profitLoss,
      profitLossPercent: profitLossPercent,
    );
  }

  static PositionSizeResult calculateCryptoPositionSize({
    required double accountSize,
    required double riskPercent,
    required double entryPrice,
    required double stopLossPercent,
  }) {
    final double riskAmount = accountSize * riskPercent / 100;
    final double stopLossPrice = entryPrice * (1 - stopLossPercent / 100);
    final double riskPerUnit = (entryPrice - stopLossPrice).abs();
    final double quantity =
        riskPerUnit > 0 ? riskAmount / riskPerUnit : 0;
    final double positionSize = quantity * entryPrice;
    return PositionSizeResult(
      quantity: quantity,
      positionSize: positionSize,
      riskAmount: riskAmount,
      stopLossPrice: stopLossPrice,
    );
  }
}

class CryptoHolding {
  final double entryPrice;
  final double quantity;
  const CryptoHolding({required this.entryPrice, required this.quantity});
}

class CryptoProfitResult {
  final double totalEntry;
  final double totalExit;
  final double totalFees;
  final double profitLoss;
  final double profitLossPercent;
  const CryptoProfitResult({
    required this.totalEntry,
    required this.totalExit,
    required this.totalFees,
    required this.profitLoss,
    required this.profitLossPercent,
  });
}

class CryptoAverageResult {
  final double averagePrice;
  final double totalQuantity;
  final double totalCost;
  const CryptoAverageResult({
    required this.averagePrice,
    required this.totalQuantity,
    required this.totalCost,
  });
}

class StakingResult {
  final double totalValue;
  final double totalRewards;
  final double effectiveApr;
  const StakingResult({
    required this.totalValue,
    required this.totalRewards,
    required this.effectiveApr,
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

class PositionSizeResult {
  final double quantity;
  final double positionSize;
  final double riskAmount;
  final double stopLossPrice;
  const PositionSizeResult({
    required this.quantity,
    required this.positionSize,
    required this.riskAmount,
    required this.stopLossPrice,
  });
}

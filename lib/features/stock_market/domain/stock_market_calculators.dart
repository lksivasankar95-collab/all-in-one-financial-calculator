class StockMarketCalculators {
  StockMarketCalculators._();

  static StockProfitResult calculateStockProfit({
    required double buyPrice,
    required double sellPrice,
    required int quantity,
    required double brokerage,
    required double taxes,
  }) {
    final double totalBuyValue = buyPrice * quantity;
    final double totalSellValue = sellPrice * quantity;
    final double totalBrokerage =
        (totalBuyValue + totalSellValue) * brokerage / 100;
    final double totalTaxes = totalSellValue * taxes / 100;
    final double profitLoss =
        totalSellValue - totalBuyValue - totalBrokerage - totalTaxes;
    final double profitLossPercent =
        totalBuyValue > 0 ? (profitLoss / totalBuyValue) * 100 : 0;
    return StockProfitResult(
      totalBuyValue: totalBuyValue,
      totalSellValue: totalSellValue,
      brokerage: totalBrokerage,
      taxes: totalTaxes,
      profitLoss: profitLoss,
      profitLossPercent: profitLossPercent,
    );
  }

  static StockAverageResult calculateStockAverage({
    required List<StockHolding> holdings,
  }) {
    double totalQuantity = 0;
    double totalCost = 0;
    for (final h in holdings) {
      totalQuantity += h.quantity;
      totalCost += h.quantity * h.buyPrice;
    }
    final double averagePrice =
        totalQuantity > 0 ? totalCost / totalQuantity : 0;
    return StockAverageResult(
      averagePrice: averagePrice,
      totalQuantity: totalQuantity,
      totalCost: totalCost,
    );
  }

  static BreakEvenPriceResult calculateBreakEvenPrice({
    required double buyPrice,
    required int quantity,
    required double brokerage,
    required double taxes,
  }) {
    final double totalBuyValue = buyPrice * quantity;
    final double totalBrokerage = totalBuyValue * brokerage / 100;
    final double totalCost = totalBuyValue + totalBrokerage;
    final double netFactor = 1 - (brokerage / 100) - (taxes / 100);
    final double breakEvenPrice =
        netFactor > 0 ? totalCost / (quantity * netFactor) : 0;
    return BreakEvenPriceResult(
      breakEvenPrice: breakEvenPrice,
      totalCost: totalCost,
    );
  }

  static PositionSizeResult calculatePositionSize({
    required double accountSize,
    required double riskPercent,
    required double entryPrice,
    required double stopLoss,
  }) {
    final double riskAmount = accountSize * riskPercent / 100;
    final double riskPerShare = (entryPrice - stopLoss).abs();
    final int quantity =
        riskPerShare > 0 ? (riskAmount / riskPerShare).floor() : 0;
    final double positionSize = quantity * entryPrice;
    final double actualRisk = quantity * riskPerShare;
    return PositionSizeResult(
      quantity: quantity,
      positionSize: positionSize,
      riskAmount: riskAmount,
      actualRisk: actualRisk,
    );
  }

  static BrokerageResult calculateBrokerage({
    required double tradeValue,
    required double brokeragePercent,
    required bool isIntraday,
  }) {
    final double rate =
        isIntraday ? brokeragePercent * 0.5 : brokeragePercent;
    final double brokerageAmount = tradeValue * rate / 100;
    final double stt = isIntraday
        ? tradeValue * 0.025 / 100
        : tradeValue * 0.1 / 100;
    final double totalCharges = brokerageAmount + stt;
    return BrokerageResult(
      brokerageAmount: brokerageAmount,
      stt: stt,
      totalCharges: totalCharges,
    );
  }
}

class StockHolding {
  final double buyPrice;
  final int quantity;
  const StockHolding({required this.buyPrice, required this.quantity});
}

class StockProfitResult {
  final double totalBuyValue;
  final double totalSellValue;
  final double brokerage;
  final double taxes;
  final double profitLoss;
  final double profitLossPercent;
  const StockProfitResult({
    required this.totalBuyValue,
    required this.totalSellValue,
    required this.brokerage,
    required this.taxes,
    required this.profitLoss,
    required this.profitLossPercent,
  });
}

class StockAverageResult {
  final double averagePrice;
  final double totalQuantity;
  final double totalCost;
  const StockAverageResult({
    required this.averagePrice,
    required this.totalQuantity,
    required this.totalCost,
  });
}

class BreakEvenPriceResult {
  final double breakEvenPrice;
  final double totalCost;
  const BreakEvenPriceResult({
    required this.breakEvenPrice,
    required this.totalCost,
  });
}

class PositionSizeResult {
  final int quantity;
  final double positionSize;
  final double riskAmount;
  final double actualRisk;
  const PositionSizeResult({
    required this.quantity,
    required this.positionSize,
    required this.riskAmount,
    required this.actualRisk,
  });
}

class BrokerageResult {
  final double brokerageAmount;
  final double stt;
  final double totalCharges;
  const BrokerageResult({
    required this.brokerageAmount,
    required this.stt,
    required this.totalCharges,
  });
}

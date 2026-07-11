import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../domain/investment_calculators.dart';

class DcaScreen extends CalculatorBaseScreen {
  const DcaScreen({super.key})
      : super(
          calculatorId: 'dca',
          calculatorName: 'DCA Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<DcaScreen> createState() => _DcaScreenState();
}

class _DcaScreenState extends CalculatorBaseState<DcaScreen> {
  final _monthlyInvestmentController = TextEditingController();
  final _startPriceController = TextEditingController();
  final _endPriceController = TextEditingController();
  double _volatility = 0.05;
  int _months = 60;
  DcaResult? _result;
  List<double> _pricePoints = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _monthlyInvestmentController.dispose();
    _startPriceController.dispose();
    _endPriceController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Investment':
            NumberFormatter.formatCurrency(_monthlyInvestment, symbol: _symbol),
        'Start Price':
            NumberFormatter.formatCurrency(_startPrice, symbol: _symbol),
        'End Price': NumberFormatter.formatCurrency(_endPrice, symbol: _symbol),
        'Months': '$_months months',
        'Volatility': NumberFormatter.formatPercent(_volatility * 100),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Total Invested':
              NumberFormatter.formatCurrency(_result!.totalInvested, symbol: _symbol),
          'Total Shares': _result!.totalShares.toStringAsFixed(4),
          'Average Cost':
              NumberFormatter.formatCurrency(_result!.averageCost, symbol: _symbol),
          'Current Value':
              NumberFormatter.formatCurrency(_result!.currentValue, symbol: _symbol),
          'Profit/Loss':
              NumberFormatter.formatCurrency(_result!.profitLoss, symbol: _symbol),
          'P&L %':
              NumberFormatter.formatPercent(_result!.profitLossPercent),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'DCA: ${NumberFormatter.formatCurrency(_result!.totalInvested, symbol: _symbol)} invested -> '
          '${NumberFormatter.formatCurrency(_result!.currentValue, symbol: _symbol)} | '
          'P&L: ${NumberFormatter.formatPercent(_result!.profitLossPercent)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _monthlyInvestment =>
      NumberFormatter.tryParse(_monthlyInvestmentController.text) ?? 0;
  double get _startPrice =>
      NumberFormatter.tryParse(_startPriceController.text) ?? 0;
  double get _endPrice =>
      NumberFormatter.tryParse(_endPriceController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculateDcaSimple(
        monthlyInvestment: _monthlyInvestment,
        startPrice: _startPrice,
        endPrice: _endPrice,
        months: _months,
        volatility: _volatility,
      );
      _generatePricePoints();
    });
  }

  void _generatePricePoints() {
    _pricePoints = [];
    for (int i = 0; i < _months; i++) {
      final progress = _months > 1 ? i / (_months - 1) : 0;
      final basePrice = _startPrice + (_endPrice - _startPrice) * progress;
      final fluctuation =
          _volatility * _startPrice * sin(3.14159 * 2 * i / 6);
      final price = (basePrice + fluctuation).clamp(0.01, double.infinity);
      _pricePoints.add(price);
    }
  }

  void _reset() {
    setState(() {
      _monthlyInvestmentController.clear();
      _startPriceController.clear();
      _endPriceController.clear();
      _volatility = 0.05;
      _months = 60;
      _result = null;
      _pricePoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    return buildCalculatorScaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Investment Details'),
                  AppTextField(
                    label: 'Monthly Investment',
                    hint: '10000',
                    controller: _monthlyInvestmentController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Starting Price',
                    hint: '100',
                    controller: _startPriceController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Ending Price',
                    hint: '150',
                    controller: _endPriceController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Number of Months',
                    value: _months.toDouble(),
                    min: 1,
                    max: 360,
                    divisions: 359,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "mo" : "mos"}',
                    onChanged: (v) {
                      setState(() {
                        _months = v.toInt();
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Price Volatility',
                    value: _volatility,
                    min: 0,
                    max: 0.5,
                    divisions: 100,
                    displayValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                    onChanged: (v) {
                      setState(() {
                        _volatility = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate',
                          icon: Icons.calculate_rounded,
                          onPressed: _calculate,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
              if (_pricePoints.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildChart(symbol),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final isProfit = r.profitLoss >= 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Total Value',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.currentValue,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Invested',
                  value: NumberFormatter.formatCurrency(r.totalInvested,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Shares',
                  value: r.totalShares.toStringAsFixed(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Avg. Cost',
                  value: NumberFormatter.formatCurrency(r.averageCost,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: isProfit ? 'Profit' : 'Loss',
                  value: NumberFormatter.formatCurrency(
                      r.profitLoss.abs(), symbol: symbol),
                  valueColor: isProfit ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Return',
            value: NumberFormatter.formatPercent(r.profitLossPercent),
            isHighlighted: true,
            valueColor: isProfit ? AppColors.success : AppColors.error,
            subtitle: 'Over $_months months of DCA investing',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Monthly Investment',
                value: NumberFormatter.formatCurrency(_monthlyInvestment,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Total Invested',
                value: NumberFormatter.formatCurrency(r.totalInvested,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Total Shares',
                value: r.totalShares.toStringAsFixed(4),
              ),
              ResultItem(
                label: 'Average Cost',
                value: NumberFormatter.formatCurrency(r.averageCost,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Current Value',
                value: NumberFormatter.formatCurrency(r.currentValue,
                    symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: isProfit ? 'Profit' : 'Loss',
                value: NumberFormatter.formatCurrency(
                    r.profitLoss.abs(), symbol: symbol),
                color: isProfit ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(String symbol) {
    final maxPrice = _pricePoints.reduce((a, b) => a > b ? a : b);
    final minPrice = _pricePoints.reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;

    // Show at most 60 points
    final step = (_pricePoints.length / 60).ceil().clamp(1, _pricePoints.length);
    final displayPoints = <int>[];
    for (int i = 0; i < _pricePoints.length; i += step) {
      displayPoints.add(i);
    }
    if (_pricePoints.isNotEmpty &&
        (_pricePoints.length - 1) % step != 0) {
      displayPoints.add(_pricePoints.length - 1);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Price Trend'),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: (minPrice - priceRange * 0.1).clamp(0, double.infinity),
                maxY: maxPrice + priceRange * 0.1,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipColor: (_) => AppColors.card,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final month = displayPoints[spot.spotIndex];
                        return LineTooltipItem(
                          'Month ${month + 1}: '
                          '${NumberFormatter.formatCurrency(_pricePoints[month], symbol: symbol)}',
                          const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormatter.formatCompact(value),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (displayPoints.length / 6)
                          .ceil()
                          .clamp(1, double.infinity)
                          .toDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= displayPoints.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'M${displayPoints[idx] + 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textHint,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: priceRange / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(displayPoints.length, (i) {
                      return FlSpot(
                        i.toDouble(),
                        _pricePoints[displayPoints[i]],
                      );
                    }),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
import '../../domain/retirement_calculators.dart';

class WithdrawalCalculatorScreen extends CalculatorBaseScreen {
  const WithdrawalCalculatorScreen({super.key})
      : super(
          calculatorId: 'withdrawal_calculator',
          calculatorName: 'Withdrawal Calculator',
          category: 'Retirement',
        );

  @override
  ConsumerState<WithdrawalCalculatorScreen> createState() => _WithdrawalCalculatorScreenState();
}

class _WithdrawalCalculatorScreenState extends CalculatorBaseState<WithdrawalCalculatorScreen> {
  final _corpusController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _withdrawalPercent = 4.0;
  double _expectedReturn = 7.0;
  int _years = 30;
  WithdrawalResult? _result;

  @override
  void dispose() {
    _corpusController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _corpusValue => NumberFormatter.tryParse(_corpusController.text) ?? 0;
  double get _annualWithdrawal => _corpusValue * _withdrawalPercent / 100;

  @override
  Map<String, dynamic> get currentInputs => {
        'Corpus': NumberFormatter.formatCurrency(_corpusValue, symbol: _symbol),
        'Withdrawal Rate': NumberFormatter.formatPercent(_withdrawalPercent),
        'Expected Return': NumberFormatter.formatPercent(_expectedReturn),
        'Years': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Total Withdrawn': NumberFormatter.formatCurrency(_result!.totalWithdrawn, symbol: _symbol),
        'Remaining Corpus': NumberFormatter.formatCurrency(_result!.remainingCorpus, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : '${_result!.sustainable ? 'Sustainable' : 'May Run Out'} | '
          'Remaining: ${NumberFormatter.formatCurrency(_result!.remainingCorpus, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_corpusValue <= 0) return;

    setState(() {
      _result = RetirementCalculators.calculateWithdrawal(
        corpus: _corpusValue,
        annualWithdrawal: _annualWithdrawal,
        expectedReturn: _expectedReturn,
        years: _years,
      );
    });
  }

  void _reset() {
    setState(() {
      _corpusController.clear();
      _withdrawalPercent = 4.0;
      _expectedReturn = 7.0;
      _years = 30;
      _result = null;
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
                  buildSectionTitle('Withdrawal Details'),
                  AppTextField(
                    label: 'Retirement Corpus',
                    hint: '10000000',
                    controller: _corpusController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Withdrawal Rate',
                    value: _withdrawalPercent,
                    min: 1, max: 15, divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}% (${NumberFormatter.formatCurrency(_corpusValue * v / 100, symbol: symbol)})',
                    onChanged: (v) => setState(() { _withdrawalPercent = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Return',
                    value: _expectedReturn,
                    min: 1, max: 10, divisions: 90,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _expectedReturn = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Retirement Duration',
                    value: _years.toDouble(),
                    min: 5, max: 50, divisions: 45,
                    displayValue: (v) => '${v.toInt()} years',
                    onChanged: (v) => setState(() { _years = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate', icon: Icons.calculate_rounded,
                          onPressed: _calculate, width: double.infinity,
                          color: AppColors.retirement,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.retirement),
                    ],
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
              const SizedBox(height: 16),
              _buildLongevityChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Withdrawal Analysis'),
          Center(
            child: Column(
              children: [
                const Text('Annual Withdrawal', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: _annualWithdrawal,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.retirement),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Total Withdrawn',
                    value: NumberFormatter.formatCurrency(r.totalWithdrawn, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Remaining Corpus',
                    value: NumberFormatter.formatCurrency(r.remainingCorpus, symbol: symbol),
                    valueColor: r.sustainable ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (r.sustainable ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (r.sustainable ? AppColors.success : AppColors.error).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(r.sustainable ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: r.sustainable ? AppColors.success : AppColors.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.sustainable
                        ? 'Your corpus will last $_years years with a safe withdrawal rate of ${_withdrawalPercent.toStringAsFixed(1)}%.'
                        : 'Your corpus may run out before $_years years. Consider a lower withdrawal rate.',
                    style: TextStyle(fontSize: 13, color: r.sustainable ? AppColors.success : AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Withdrawal Summary',
            items: [
              ResultItem(label: 'Corpus', value: NumberFormatter.formatCurrency(_corpusValue, symbol: symbol)),
              ResultItem(label: 'Annual Withdrawal', value: NumberFormatter.formatCurrency(_annualWithdrawal, symbol: symbol)),
              const ResultItem(label: 'Safe Withdrawal Rate', value: '4.00% (recommended)'),
              ResultItem(label: 'Your Rate', value: NumberFormatter.formatPercent(_withdrawalPercent),
                  color: _withdrawalPercent <= 4 ? AppColors.success : AppColors.warning),
              ResultItem(label: 'Remaining After $_years yrs', value: NumberFormatter.formatCurrency(r.remainingCorpus, symbol: symbol),
                  isHighlighted: true, color: r.sustainable ? AppColors.success : AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLongevityChart() {
    final r = _result!;
    final data = r.yearlyBalances;

    if (data.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Corpus Over Time'),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
                    color: AppColors.retirement,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.retirement.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      return Text(NumberFormatter.formatCompact(value),
                          style: const TextStyle(fontSize: 9, color: AppColors.textHint));
                    },
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 22,
                    interval: (data.length / 5).ceilToDouble().clamp(1, double.infinity),
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Yr ${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                      );
                    },
                  )),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false,
                    horizontalInterval: _corpusValue / 4,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.5)),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: _corpusValue * 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

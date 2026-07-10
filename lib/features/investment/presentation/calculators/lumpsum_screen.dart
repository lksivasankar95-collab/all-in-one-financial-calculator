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

class LumpsumScreen extends CalculatorBaseScreen {
  const LumpsumScreen({super.key})
      : super(
          calculatorId: 'lumpsum',
          calculatorName: 'Lumpsum Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<LumpsumScreen> createState() => _LumpsumScreenState();
}

class _LumpsumScreenState extends CalculatorBaseState<LumpsumScreen> {
  final _principalController = TextEditingController();
  double _annualReturn = 12.0;
  int _years = 10;
  int _compoundingFrequency = 1; // 1=Annual, 2=Semi-Annual, 4=Quarterly, 12=Monthly
  LumpsumResult? _result;
  List<YearlyData> _chartData = [];
  final _formKey = GlobalKey<FormState>();

  static const _compoundingOptions = [
    _CompoundOption(label: 'Annually', value: 1),
    _CompoundOption(label: 'Semi-Annually', value: 2),
    _CompoundOption(label: 'Quarterly', value: 4),
    _CompoundOption(label: 'Monthly', value: 12),
  ];

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Principal':
            NumberFormatter.formatCurrency(_principalValue, symbol: _symbol),
        'Annual Return Rate': NumberFormatter.formatPercent(_annualReturn),
        'Investment Period': '$_years years',
        'Compounding':
            _compoundingOptions.firstWhere((o) => o.value == _compoundingFrequency).label,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Total Value':
              NumberFormatter.formatCurrency(_result!.totalValue, symbol: _symbol),
          'Total Profit':
              NumberFormatter.formatCurrency(_result!.totalProfit, symbol: _symbol),
          'Absolute Return':
              NumberFormatter.formatPercent(_result!.absoluteReturn),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '${NumberFormatter.formatCurrency(_principalValue, symbol: _symbol)} lumpsum '
          'for $_years yrs @ ${_annualReturn.toStringAsFixed(1)}% = '
          '${NumberFormatter.formatCurrency(_result!.totalValue, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _principalValue =>
      NumberFormatter.tryParse(_principalController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculateLumpsum(
        principal: _principalValue,
        annualReturnRate: _annualReturn,
        years: _years,
        compoundingFrequency: _compoundingFrequency,
      );
      _chartData = InvestmentCalculators.getLumpsumYearlyBreakdown(
        principal: _principalValue,
        rate: _annualReturn,
        years: _years,
      );
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _annualReturn = 12.0;
      _years = 10;
      _compoundingFrequency = 1;
      _result = null;
      _chartData = [];
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
                    label: 'Principal Amount',
                    hint: '1,00,000',
                    controller: _principalController,
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
                  AppSliderField(
                    label: 'Expected Annual Return',
                    value: _annualReturn,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _annualReturn = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Investment Period',
                    value: _years.toDouble(),
                    min: 1,
                    max: 40,
                    divisions: 39,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _years = v.toInt();
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildCompoundingDropdown(),
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
              const SizedBox(height: 16),
              if (_chartData.isNotEmpty) _buildChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompoundingDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compounding Frequency',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<int>(
            value: _compoundingFrequency,
            isExpanded: true,
            dropdownColor: AppColors.card,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded,
                color: AppColors.textHint, size: 20),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            items: _compoundingOptions
                .map((o) => DropdownMenuItem(
                      value: o.value,
                      child: Text(o.label),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _compoundingFrequency = v;
                if (_result != null) _result = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
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
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalValue,
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
                  label: 'Principal Amount',
                  value: NumberFormatter.formatCurrency(_principalValue,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Est. Returns',
                  value: NumberFormatter.formatCurrency(r.totalProfit,
                      symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Absolute Return',
            value: NumberFormatter.formatPercent(r.absoluteReturn),
            isHighlighted: true,
            subtitle:
                '${_years}yr investment @ ${_annualReturn.toStringAsFixed(1)}% p.a.',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Principal Invested',
                value: NumberFormatter.formatCurrency(_principalValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Interest Earned',
                value: NumberFormatter.formatCurrency(r.totalProfit,
                    symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Total Value',
                value: NumberFormatter.formatCurrency(r.totalValue,
                    symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Absolute Return',
                value: NumberFormatter.formatPercent(r.absoluteReturn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final maxVal = _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final step = (_chartData.length / 15).ceil().clamp(1, _chartData.length);
    final displayData = [
      for (int i = 0; i < _chartData.length; i += step) _chartData[i],
      if (_chartData.isNotEmpty && (_chartData.length - 1) % step != 0)
        _chartData.last,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Year-by-Year Growth'),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.border, label: 'Principal'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.primary, label: 'Value'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.15,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipColor: (_) => AppColors.card,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = displayData[group.x];
                      return BarTooltipItem(
                        'Yr ${d.year}\n${rodIndex == 0 ? "Principal" : "Value"}: '
                        '${NumberFormatter.formatCompact(rod.toY)}',
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          NumberFormatter.formatCompact(value),
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textHint),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= displayData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Y${displayData[idx].year}',
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textHint),
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
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(displayData.length, (i) {
                  final d = displayData[i];
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: d.invested,
                        color: AppColors.border,
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: d.value,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompoundOption {
  final String label;
  final int value;
  const _CompoundOption({required this.label, required this.value});
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

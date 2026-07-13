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
import '../../domain/banking_calculators.dart';

class MonthlyBudgetScreen extends CalculatorBaseScreen {
  const MonthlyBudgetScreen({super.key})
      : super(
          calculatorId: 'monthly_budget',
          calculatorName: 'Monthly Budget Calculator',
          category: 'Banking',
        );

  @override
  ConsumerState<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends CalculatorBaseState<MonthlyBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _housingController = TextEditingController();
  final _foodController = TextEditingController();
  final _transportController = TextEditingController();
  final _utilitiesController = TextEditingController();
  final _savingsController = TextEditingController();
  final _otherController = TextEditingController();

  final Map<String, double> _recommendedPct = {
    'Housing': 30, 'Food': 15, 'Transport': 10,
    'Utilities': 10, 'Savings': 20, 'Other': 15,
  };

  BudgetResult? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    _housingController.dispose();
    _foodController.dispose();
    _transportController.dispose();
    _utilitiesController.dispose();
    _savingsController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _incomeValue => NumberFormatter.tryParse(_incomeController.text) ?? 0;
  double get _housingValue => NumberFormatter.tryParse(_housingController.text) ?? 0;
  double get _foodValue => NumberFormatter.tryParse(_foodController.text) ?? 0;
  double get _transportValue => NumberFormatter.tryParse(_transportController.text) ?? 0;
  double get _utilitiesValue => NumberFormatter.tryParse(_utilitiesController.text) ?? 0;
  double get _savingsValue => NumberFormatter.tryParse(_savingsController.text) ?? 0;
  double get _otherValue => NumberFormatter.tryParse(_otherController.text) ?? 0;
  double get _totalActual => _housingValue + _foodValue + _transportValue + _utilitiesValue + _savingsValue + _otherValue;

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Income': NumberFormatter.formatCurrency(_incomeValue, symbol: _symbol),
        'Total Budgeted': NumberFormatter.formatCurrency(_totalActual, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Total Expenses': NumberFormatter.formatCurrency(_result!.totalExpenses, symbol: _symbol),
          'Surplus': NumberFormatter.formatCurrency(_result!.surplus, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Budget: ${NumberFormatter.formatCurrency(_result!.totalExpenses, symbol: _symbol)} / '
          '${NumberFormatter.formatCurrency(_incomeValue, symbol: _symbol)} | '
          'Surplus: ${NumberFormatter.formatCurrency(_result!.surplus, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_incomeValue <= 0) return;

    setState(() {
      _result = BankingCalculators.calculateMonthlyBudget(
        income: _incomeValue,
        categories: [
          BudgetCategory(name: 'Housing', amount: _housingValue),
          BudgetCategory(name: 'Food', amount: _foodValue),
          BudgetCategory(name: 'Transport', amount: _transportValue),
          BudgetCategory(name: 'Utilities', amount: _utilitiesValue),
          BudgetCategory(name: 'Savings', amount: _savingsValue),
          BudgetCategory(name: 'Other', amount: _otherValue),
        ],
      );
    });
  }

  void _reset() {
    setState(() {
      for (final c in [
        _incomeController, _housingController, _foodController,
        _transportController, _utilitiesController, _savingsController, _otherController,
      ]) {
        c.clear();
      }
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
                  buildSectionTitle('Monthly Income'),
                  AppTextField(
                    label: 'Total Monthly Income',
                    hint: '50000',
                    controller: _incomeController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Budget Categories'),
                  _buildBudgetField('Housing', 30, _housingController, symbol),
                  const SizedBox(height: 12),
                  _buildBudgetField('Food', 15, _foodController, symbol),
                  const SizedBox(height: 12),
                  _buildBudgetField('Transport', 10, _transportController, symbol),
                  const SizedBox(height: 12),
                  _buildBudgetField('Utilities', 10, _utilitiesController, symbol),
                  const SizedBox(height: 12),
                  _buildBudgetField('Savings', 20, _savingsController, symbol),
                  const SizedBox(height: 12),
                  _buildBudgetField('Other', 15, _otherController, symbol),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Calculate', icon: Icons.calculate_rounded,
                    onPressed: _calculate, width: double.infinity,
                    color: AppColors.banking,
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.banking),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
              const SizedBox(height: 16),
              _buildBudgetComparison(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetField(String name, double recommendedPct, TextEditingController controller, String symbol) {
    final allocated = _incomeValue * recommendedPct / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            Text('Recommended: ${recommendedPct.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: 4),
        Text(NumberFormatter.formatCurrency(allocated, symbol: symbol),
            style: const TextStyle(fontSize: 11, color: AppColors.banking)),
        AppTextField(
          label: 'Actual Spent',
          hint: '0',
          controller: controller,
          prefix: symbol,
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Enter a valid amount';
            return null;
          },
          onChanged: (_) { if (_result != null) setState(() => _result = null); },
        ),
      ],
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final surplus = r.surplus;
    final isOnTrack = surplus >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Budget Overview'),
          Center(
            child: Column(
              children: [
                Text(isOnTrack ? 'Surplus' : 'Deficit',
                    style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: surplus.abs(),
                  formatter: (v) => '${isOnTrack ? '+' : '-'}${NumberFormatter.formatCurrency(v, symbol: symbol)}',
                  style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w800,
                    color: isOnTrack ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Income', value: NumberFormatter.formatCurrency(_incomeValue, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Spent', value: NumberFormatter.formatCurrency(r.totalExpenses, symbol: symbol),
                    valueColor: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Budget vs Actual',
            items: r.breakdown.map((cat) {
              final recommended = _incomeValue * (_recommendedPct[cat.name] ?? 0) / 100;
              final variance = cat.amount - recommended;
              final onTrack = cat.amount <= recommended * 1.1;
              return ResultItem(
                label: '${cat.name} - ${onTrack ? '✓' : '⚠'}',
                value: '${NumberFormatter.formatCurrency(cat.amount, symbol: symbol)} (${variance >= 0 ? '+' : ''}${NumberFormatter.formatCurrency(variance, symbol: symbol)})',
                color: onTrack ? AppColors.success : AppColors.warning,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetComparison(String symbol) {
    final r = _result!;
    final categories = r.breakdown;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Budget Allocation'),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _incomeValue * 1.1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipColor: (_) => AppColors.card,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cat = categories[group.x];
                      return BarTooltipItem(
                        '${cat.name}\n${rodIndex == 0 ? "Actual" : "Budgeted"}: ${NumberFormatter.formatCompact(rod.toY)}',
                        const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= categories.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(categories[idx].name.substring(0, 3),
                            style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                      );
                    },
                  )),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(categories.length, (i) {
                  final cat = categories[i];
                  final recommended = _incomeValue * (_recommendedPct[cat.name] ?? 0) / 100;
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: cat.amount, color: AppColors.banking, width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    BarChartRodData(toY: recommended, color: AppColors.textHint, width: 6,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ]);
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.banking, label: 'Actual'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.textHint, label: 'Budget'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

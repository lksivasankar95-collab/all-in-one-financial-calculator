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

class CashFlowScreen extends CalculatorBaseScreen {
  const CashFlowScreen({super.key})
      : super(
          calculatorId: 'cash_flow',
          calculatorName: 'Cash Flow Calculator',
          category: 'Banking',
        );

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends CalculatorBaseState<CashFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salaryController = TextEditingController();
  final _businessController = TextEditingController();
  final _investmentController = TextEditingController();
  final _otherIncomeController = TextEditingController();
  final _rentController = TextEditingController();
  final _foodController = TextEditingController();
  final _transportController = TextEditingController();
  final _otherExpenseController = TextEditingController();

  CashFlowResult? _result;
  int _touchedIndex = -1;

  @override
  void dispose() {
    _salaryController.dispose();
    _businessController.dispose();
    _investmentController.dispose();
    _otherIncomeController.dispose();
    _rentController.dispose();
    _foodController.dispose();
    _transportController.dispose();
    _otherExpenseController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);

  double get _salaryValue => NumberFormatter.tryParse(_salaryController.text) ?? 0;
  double get _businessValue => NumberFormatter.tryParse(_businessController.text) ?? 0;
  double get _investmentValue => NumberFormatter.tryParse(_investmentController.text) ?? 0;
  double get _otherIncomeValue => NumberFormatter.tryParse(_otherIncomeController.text) ?? 0;
  double get _totalIncome => _salaryValue + _businessValue + _investmentValue + _otherIncomeValue;

  double get _rentValue => NumberFormatter.tryParse(_rentController.text) ?? 0;
  double get _foodValue => NumberFormatter.tryParse(_foodController.text) ?? 0;
  double get _transportValue => NumberFormatter.tryParse(_transportController.text) ?? 0;
  double get _otherExpenseValue => NumberFormatter.tryParse(_otherExpenseController.text) ?? 0;
  double get _totalExpenses => _rentValue + _foodValue + _transportValue + _otherExpenseValue;

  @override
  Map<String, dynamic> get currentInputs => {
        'Total Income': NumberFormatter.formatCurrency(_totalIncome, symbol: _symbol),
        'Total Expenses': NumberFormatter.formatCurrency(_totalExpenses, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Cash Flow': NumberFormatter.formatCurrency(_totalIncome - _totalExpenses, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Cash Flow: ${NumberFormatter.formatCurrency(_totalIncome - _totalExpenses, symbol: _symbol)}';

  String? _validateAmount(String? v) {
    if (v == null || v.isEmpty) return null;
    if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Enter a valid amount';
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = BankingCalculators.calculateCashFlow(
        income: _totalIncome,
        expenses: _totalExpenses,
      );
    });
  }

  void _reset() {
    setState(() {
      for (final c in [
        _salaryController, _businessController, _investmentController, _otherIncomeController,
        _rentController, _foodController, _transportController, _otherExpenseController,
      ]) {
        c.clear();
      }
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    final cashFlow = _totalIncome - _totalExpenses;
    final isSurplus = cashFlow >= 0;
    final savingsRate = _totalIncome > 0 ? (cashFlow / _totalIncome) * 100 : 0.0;
    final expenseRatio = _totalIncome > 0 ? (_totalExpenses / _totalIncome) * 100 : 0.0;

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
                  buildSectionTitle('Income'),
                  AppTextField(label: 'Salary', controller: _salaryController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Business', controller: _businessController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Investment', controller: _investmentController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Other Income', controller: _otherIncomeController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Expenses'),
                  AppTextField(label: 'Rent / Mortgage', controller: _rentController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Food & Groceries', controller: _foodController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Transport', controller: _transportController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Other Expenses', controller: _otherExpenseController, prefix: symbol, validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
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
            const SizedBox(height: 16),
            _buildQuickSummary(symbol, cashFlow, isSurplus, savingsRate, expenseRatio),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol, savingsRate, expenseRatio),
              const SizedBox(height: 16),
              _buildPieChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummary(String symbol, double cashFlow, bool isSurplus, double savingsRate, double expenseRatio) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Income',
                  value: NumberFormatter.formatCurrency(_totalIncome, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Expenses',
                  value: NumberFormatter.formatCurrency(_totalExpenses, symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: isSurplus ? 'Surplus' : 'Deficit',
            value: NumberFormatter.formatCurrency(cashFlow.abs(), symbol: symbol),
            isHighlighted: true,
            valueColor: isSurplus ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(String symbol, double savingsRate, double expenseRatio) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Analysis'),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Savings Rate',
                  value: NumberFormatter.formatPercent(savingsRate),
                  valueColor: savingsRate >= 20 ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Expense Ratio',
                  value: NumberFormatter.formatPercent(expenseRatio),
                  valueColor: expenseRatio <= 80 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildHealthStatus(savingsRate),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Monthly Cash Flow',
            items: [
              ResultItem(label: 'Total Income', value: NumberFormatter.formatCurrency(_totalIncome, symbol: symbol)),
              ResultItem(label: 'Total Expenses', value: NumberFormatter.formatCurrency(_totalExpenses, symbol: symbol), color: AppColors.error),
              ResultItem(label: 'Savings Rate', value: NumberFormatter.formatPercent(savingsRate)),
              ResultItem(label: isSurplus ? 'Surplus' : 'Deficit', value: NumberFormatter.formatCurrency(_totalIncome - _totalExpenses, symbol: symbol), isHighlighted: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatus(double savingsRate) {
    String status;
    Color color;
    IconData icon;
    if (savingsRate >= 30) {
      status = 'Excellent Savings';
      color = AppColors.success;
      icon = Icons.emoji_emotions_rounded;
    } else if (savingsRate >= 20) {
      status = 'Good Savings';
      color = AppColors.success;
      icon = Icons.sentiment_satisfied_rounded;
    } else if (savingsRate >= 10) {
      status = 'Adequate';
      color = AppColors.warning;
      icon = Icons.sentiment_neutral_rounded;
    } else if (savingsRate >= 0) {
      status = 'Low Savings';
      color = AppColors.warning;
      icon = Icons.sentiment_dissatisfied_rounded;
    } else {
      status = 'Deficit';
      color = AppColors.error;
      icon = Icons.error_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            'Financial Health: $status',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Income vs Expenses'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 52,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null || response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: [
                        PieChartSectionData(
                          value: _totalIncome > 0 ? _totalIncome : 1,
                          color: AppColors.success,
                          title: _touchedIndex == 0 ? 'Income' : '',
                          radius: _touchedIndex == 0 ? 60 : 52,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: _totalExpenses > 0 ? _totalExpenses : 1,
                          color: AppColors.error.withValues(alpha: 0.75),
                          title: _touchedIndex == 1 ? 'Expenses' : '',
                          radius: _touchedIndex == 1 ? 60 : 52,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieLegend(color: AppColors.success, label: 'Income',
                      value: NumberFormatter.formatCurrency(_totalIncome)),
                    const SizedBox(height: 14),
                    _PieLegend(color: AppColors.error.withValues(alpha: 0.75), label: 'Expenses',
                      value: NumberFormatter.formatCurrency(_totalExpenses)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _PieLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ],
    );
  }
}

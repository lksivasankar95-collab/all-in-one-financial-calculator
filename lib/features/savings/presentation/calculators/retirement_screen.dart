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
import '../../domain/savings_calculators.dart';

class RetirementScreen extends CalculatorBaseScreen {
  const RetirementScreen({super.key})
      : super(
          calculatorId: 'retirement',
          calculatorName: 'Retirement Planner',
          category: 'Savings',
        );

  @override
  ConsumerState<RetirementScreen> createState() => _RetirementScreenState();
}

class _RetirementScreenState extends CalculatorBaseState<RetirementScreen> {
  final _monthlyExpenseController = TextEditingController();
  final _currentSavingsController = TextEditingController();
  double _currentAge = 30.0;
  double _retirementAge = 60.0;
  double _inflationRate = 6.0;
  double _expectedReturn = 12.0;
  RetirementResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _monthlyExpenseController.dispose();
    _currentSavingsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Age': '${_currentAge.toInt()} years',
        'Retirement Age': '${_retirementAge.toInt()} years',
        'Monthly Expenses': NumberFormatter.formatCurrency(_monthlyExpense, symbol: _symbol),
        'Inflation Rate': NumberFormatter.formatPercent(_inflationRate),
        'Expected Return': NumberFormatter.formatPercent(_expectedReturn),
        'Current Savings': NumberFormatter.formatCurrency(_currentSavings, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Corpus Needed': NumberFormatter.formatCurrency(_result!.corpusNeeded, symbol: _symbol),
          'Shortfall': NumberFormatter.formatCurrency(_result!.shortfall, symbol: _symbol),
          'Monthly Savings Needed': NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Retirement corpus needed: ${NumberFormatter.formatCurrency(_result!.corpusNeeded, symbol: _symbol)}. '
          'Save ${NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol)}/mo to retire at ${_retirementAge.toInt()}.';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _monthlyExpense => NumberFormatter.tryParse(_monthlyExpenseController.text) ?? 0;
  double get _currentSavings => NumberFormatter.tryParse(_currentSavingsController.text) ?? 0;

  int get _yearsToRetirement => (_retirementAge - _currentAge).toInt();

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_retirementAge <= _currentAge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retirement age must be greater than current age')),
      );
      return;
    }
    final expense = _monthlyExpense;
    if (expense <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateRetirement(
        currentAge: _currentAge,
        retirementAge: _retirementAge,
        monthlyExpense: expense,
        inflationRate: _inflationRate,
        expectedReturn: _expectedReturn,
        currentSavings: _currentSavings,
      );
    });
  }

  void _reset() {
    setState(() {
      _monthlyExpenseController.clear();
      _currentSavingsController.clear();
      _currentAge = 30.0;
      _retirementAge = 60.0;
      _inflationRate = 6.0;
      _expectedReturn = 12.0;
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
                  buildSectionTitle('Personal Details'),
                  AppSliderField(
                    label: 'Current Age',
                    value: _currentAge,
                    min: 20,
                    max: 59,
                    divisions: 39,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _currentAge = v;
                      if (_retirementAge <= v) _retirementAge = v + 1;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Retirement Age',
                    value: _retirementAge,
                    min: 40,
                    max: 75,
                    divisions: 35,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _retirementAge = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.savings.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.savings.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Years to Retirement',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '$_yearsToRetirement years',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Financial Details'),
                  AppTextField(
                    label: 'Current Monthly Expenses',
                    hint: '50,000',
                    controller: _monthlyExpenseController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Current Savings / Investments',
                    hint: '0',
                    controller: _currentSavingsController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Inflation Rate',
                    value: _inflationRate,
                    min: 2,
                    max: 12,
                    divisions: 100,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _inflationRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Investment Return',
                    value: _expectedReturn,
                    min: 4,
                    max: 20,
                    divisions: 160,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _expectedReturn = v;
                      _result = null;
                    }),
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
                          color: AppColors.savings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.savings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final bool isOnTrack = r.shortfall <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Retirement Plan Results'),
          // Insight Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isOnTrack
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.savings.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOnTrack
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.savings.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isOnTrack
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: isOnTrack ? AppColors.success : AppColors.savings,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnTrack ? 'You are on track!' : 'Action needed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isOnTrack ? AppColors.success : AppColors.savings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isOnTrack
                      ? 'Your current savings are sufficient to meet your retirement goal.'
                      : 'You need ${NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol)} more per month to retire comfortably at ${_retirementAge.toInt()}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'Corpus Needed at Retirement',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.corpusNeeded,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.savings,
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
                  label: 'Current Shortfall',
                  value: isOnTrack
                      ? 'On Track'
                      : NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
                  valueColor: isOnTrack ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Monthly Savings Needed',
                  value: isOnTrack
                      ? '${symbol}0'
                      : NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol),
                  valueColor: isOnTrack ? AppColors.success : AppColors.savings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Plan Summary',
            items: [
              ResultItem(
                label: 'Retirement in',
                value: '$_yearsToRetirement years',
              ),
              ResultItem(
                label: 'Monthly Expenses Today',
                value: NumberFormatter.formatCurrency(_monthlyExpense, symbol: symbol),
              ),
              ResultItem(
                label: 'Inflation-adjusted Expenses',
                value: NumberFormatter.formatCurrency(
                  _monthlyExpense * (1 + _inflationRate / 100).clamp(1, double.infinity),
                  symbol: symbol,
                ),
              ),
              ResultItem(
                label: 'Corpus Needed',
                value: NumberFormatter.formatCurrency(r.corpusNeeded, symbol: symbol),
              ),
              ResultItem(
                label: 'Shortfall',
                value: isOnTrack
                    ? 'None'
                    : NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
                color: isOnTrack ? AppColors.success : AppColors.error,
              ),
              ResultItem(
                label: 'Monthly SIP Needed',
                value: isOnTrack
                    ? '${symbol}0 (On Track)'
                    : NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

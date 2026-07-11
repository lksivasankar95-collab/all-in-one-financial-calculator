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

class ChildFutureScreen extends CalculatorBaseScreen {
  const ChildFutureScreen({super.key})
      : super(
          calculatorId: 'child_future',
          calculatorName: 'Child Future Planning',
          category: 'Savings',
        );

  @override
  ConsumerState<ChildFutureScreen> createState() => _ChildFutureScreenState();
}

class _ChildFutureScreenState extends CalculatorBaseState<ChildFutureScreen> {
  final _goalAmountController = TextEditingController();
  final _currentSavingsController = TextEditingController();
  double _childAge = 5.0;
  double _targetAge = 21.0;
  double _annualReturn = 12.0;
  String _selectedGoal = 'Education';
  ChildFutureResult? _result;
  final _formKey = GlobalKey<FormState>();

  final List<String> _goals = ['Education', 'Wedding', 'House', 'Business', 'Other'];

  final Map<String, IconData> _goalIcons = {
    'Education': Icons.school_rounded,
    'Wedding': Icons.favorite_rounded,
    'House': Icons.home_rounded,
    'Business': Icons.business_rounded,
    'Other': Icons.stars_rounded,
  };

  @override
  void dispose() {
    _goalAmountController.dispose();
    _currentSavingsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Goal Type': _selectedGoal,
        'Goal Amount': NumberFormatter.formatCurrency(_goalAmount, symbol: _symbol),
        'Child\'s Age': '${_childAge.toInt()} years',
        'Target Age': '${_targetAge.toInt()} years',
        'Current Savings': NumberFormatter.formatCurrency(_currentSavings, symbol: _symbol),
        'Expected Return': NumberFormatter.formatPercent(_annualReturn),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Future Value': NumberFormatter.formatCurrency(_result!.futureValue, symbol: _symbol),
          'Monthly Investment': NumberFormatter.formatCurrency(_result!.monthlyInvestment, symbol: _symbol),
          'Total Invested': NumberFormatter.formatCurrency(_result!.totalInvested, symbol: _symbol),
          'Total Interest': NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '$_selectedGoal goal: ${NumberFormatter.formatCurrency(_result!.futureValue, symbol: _symbol)}. '
          'Invest ${NumberFormatter.formatCurrency(_result!.monthlyInvestment, symbol: _symbol)}/mo '
          'for ${(_targetAge - _childAge).toInt()} years.';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _goalAmount => NumberFormatter.tryParse(_goalAmountController.text) ?? 0;
  double get _currentSavings => NumberFormatter.tryParse(_currentSavingsController.text) ?? 0;

  int get _yearsToTarget => (_targetAge - _childAge).toInt();

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final goal = _goalAmount;
    if (goal <= 0) return;
    if (_targetAge <= _childAge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target age must be greater than child\'s current age')),
      );
      return;
    }

    setState(() {
      _result = SavingsCalculators.calculateChildFuturePlanning(
        goalAmount: goal,
        childAge: _childAge,
        targetAge: _targetAge,
        currentSavings: _currentSavings,
        annualReturn: _annualReturn,
      );
    });
  }

  void _reset() {
    setState(() {
      _goalAmountController.clear();
      _currentSavingsController.clear();
      _childAge = 5.0;
      _targetAge = 21.0;
      _annualReturn = 12.0;
      _selectedGoal = 'Education';
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
            // Goal Selector
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Select Goal Type'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _goals.map((goal) {
                      final bool selected = _selectedGoal == goal;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedGoal = goal;
                          _result = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.savings.withValues(alpha: 0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.savings
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _goalIcons[goal] ?? Icons.stars_rounded,
                                size: 16,
                                color: selected
                                    ? AppColors.savings
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                goal,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.savings
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Child Details'),
                  AppSliderField(
                    label: 'Child\'s Current Age',
                    value: _childAge,
                    min: 0,
                    max: 18,
                    divisions: 18,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _childAge = v;
                      if (_targetAge <= v) _targetAge = v + 1;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Target Age',
                    value: _targetAge,
                    min: 18,
                    max: 30,
                    divisions: 12,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _targetAge = v;
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
                          'Years to Target',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '$_yearsToTarget years',
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
                    label: '$_selectedGoal Goal Amount',
                    hint: '50,00,000',
                    controller: _goalAmountController,
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
                    label: 'Current Savings for This Goal',
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
                    label: 'Expected Investment Return',
                    value: _annualReturn,
                    min: 8,
                    max: 15,
                    divisions: 70,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualReturn = v;
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
    final bool isAlreadyFunded = r.monthlyInvestment <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('$_selectedGoal Plan Results'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isAlreadyFunded
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.savings.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAlreadyFunded
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.savings.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAlreadyFunded
                      ? Icons.check_circle_rounded
                      : Icons.trending_up_rounded,
                  color: isAlreadyFunded ? AppColors.success : AppColors.savings,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAlreadyFunded
                        ? 'Your current savings are enough for this $_selectedGoal goal!'
                        : 'Invest ${NumberFormatter.formatCurrency(r.monthlyInvestment, symbol: symbol)} per month '
                            'to reach your $_selectedGoal goal of ${NumberFormatter.formatCurrency(r.futureValue, symbol: symbol)}.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  'Monthly Investment Needed',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.monthlyInvestment,
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
                  label: 'Future Value',
                  value: NumberFormatter.formatCurrency(r.futureValue, symbol: symbol),
                  valueColor: AppColors.savings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Invested',
                  value: NumberFormatter.formatCurrency(r.totalInvested, symbol: symbol),
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Interest',
                  value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: '$_selectedGoal Plan Summary',
            items: [
              ResultItem(
                label: 'Goal Type',
                value: _selectedGoal,
              ),
              ResultItem(
                label: 'Child\'s Current Age',
                value: '${_childAge.toInt()} years',
              ),
              ResultItem(
                label: 'Target Age',
                value: '${_targetAge.toInt()} years',
              ),
              ResultItem(
                label: 'Years to Target',
                value: '$_yearsToTarget years',
              ),
              ResultItem(
                label: 'Goal Amount',
                value: NumberFormatter.formatCurrency(_goalAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Current Savings',
                value: NumberFormatter.formatCurrency(_currentSavings, symbol: symbol),
              ),
              ResultItem(
                label: 'Expected Return',
                value: NumberFormatter.formatPercent(_annualReturn),
              ),
              ResultItem(
                label: 'Monthly Investment Needed',
                value: isAlreadyFunded
                    ? '${symbol}0'
                    : NumberFormatter.formatCurrency(r.monthlyInvestment, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

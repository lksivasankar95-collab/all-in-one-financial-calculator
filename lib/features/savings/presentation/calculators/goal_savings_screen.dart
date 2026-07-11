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

class GoalSavingsScreen extends CalculatorBaseScreen {
  const GoalSavingsScreen({super.key})
      : super(
          calculatorId: 'goal_savings',
          calculatorName: 'Goal Savings',
          category: 'Savings',
        );

  @override
  ConsumerState<GoalSavingsScreen> createState() => _GoalSavingsScreenState();
}

class _GoalSavingsScreenState extends CalculatorBaseState<GoalSavingsScreen> {
  final _goalAmountController = TextEditingController();
  final _currentSavingsController = TextEditingController();
  double _annualReturn = 10.0;
  double _years = 10.0;
  GoalSavingsResult? _result;
  final _formKey = GlobalKey<FormState>();

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
        'Goal Amount': NumberFormatter.formatCurrency(_goalAmount, symbol: _symbol),
        'Current Savings': NumberFormatter.formatCurrency(_currentSavings, symbol: _symbol),
        'Annual Return': NumberFormatter.formatPercent(_annualReturn),
        'Time Horizon': '${_years.toInt()} years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Monthly Savings Needed': NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol),
          'Total Contributions': NumberFormatter.formatCurrency(_result!.totalContributions, symbol: _symbol),
          'Total Interest Earned': NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Goal: ${NumberFormatter.formatCurrency(_result!.goalAmount, symbol: _symbol)}. '
          'Save ${NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol)}/mo for ${_years.toInt()} years.';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _goalAmount => NumberFormatter.tryParse(_goalAmountController.text) ?? 0;
  double get _currentSavings => NumberFormatter.tryParse(_currentSavingsController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final goal = _goalAmount;
    if (goal <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateGoalSavings(
        goalAmount: goal,
        currentSavings: _currentSavings,
        annualReturn: _annualReturn,
        years: _years.toInt(),
      );
    });
  }

  void _reset() {
    setState(() {
      _goalAmountController.clear();
      _currentSavingsController.clear();
      _annualReturn = 10.0;
      _years = 10.0;
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
                  buildSectionTitle('Goal Details'),
                  AppTextField(
                    label: 'Goal Amount',
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
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Current Savings',
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
                    label: 'Annual Return',
                    value: _annualReturn,
                    min: 4,
                    max: 15,
                    divisions: 110,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualReturn = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Time Horizon',
                    value: _years,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _years = v;
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
                          'Total Months',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${(_years * 12).toInt()} months',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
                    ),
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
    final bool isAlreadyFunded = r.monthlySavingsNeeded <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Goal Analysis'),
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
                        ? 'Your current savings are already enough to reach this goal!'
                        : 'You need to save ${NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol)} per month.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
                  'Monthly Savings Needed',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.monthlySavingsNeeded,
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
                  label: 'Total Contributions',
                  value: NumberFormatter.formatCurrency(r.totalContributions, symbol: symbol),
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Interest Earned',
                  value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Goal Summary',
            items: [
              ResultItem(
                label: 'Goal Amount',
                value: NumberFormatter.formatCurrency(r.goalAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Current Savings',
                value: NumberFormatter.formatCurrency(_currentSavings, symbol: symbol),
              ),
              ResultItem(
                label: 'Time Horizon',
                value: '${_years.toInt()} years',
              ),
              ResultItem(
                label: 'Expected Return',
                value: NumberFormatter.formatPercent(_annualReturn),
              ),
              ResultItem(
                label: 'Monthly Savings Needed',
                value: isAlreadyFunded
                    ? '${symbol}0'
                    : NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Total Contributions',
                value: NumberFormatter.formatCurrency(r.totalContributions, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Interest',
                value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

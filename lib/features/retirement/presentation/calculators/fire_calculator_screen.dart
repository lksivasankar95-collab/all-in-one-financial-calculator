import 'dart:math';
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

class FireCalculatorScreen extends CalculatorBaseScreen {
  const FireCalculatorScreen({super.key})
      : super(
          calculatorId: 'fire_calculator',
          calculatorName: 'FIRE Calculator',
          category: 'Retirement',
        );

  @override
  ConsumerState<FireCalculatorScreen> createState() => _FireCalculatorScreenState();
}

class _FireCalculatorScreenState extends CalculatorBaseState<FireCalculatorScreen> {
  final _expenseController = TextEditingController();
  final _savingsController = TextEditingController();
  final _monthlySavingsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentAge = 30;
  int _retirementAge = 45;
  double _expectedReturn = 12.0;
  double _inflation = 6.0;
  FireResult? _result;

  @override
  void dispose() {
    _expenseController.dispose();
    _savingsController.dispose();
    _monthlySavingsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _expenseValue => NumberFormatter.tryParse(_expenseController.text) ?? 0;
  double get _savingsValue => NumberFormatter.tryParse(_savingsController.text) ?? 0;
  double get _monthlySavingsValue => NumberFormatter.tryParse(_monthlySavingsController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Age': '$_currentAge',
        'Retirement Age': '$_retirementAge',
        'Monthly Expenses': NumberFormatter.formatCurrency(_expenseValue, symbol: _symbol),
        'Current Savings': NumberFormatter.formatCurrency(_savingsValue, symbol: _symbol),
        'Monthly Savings': NumberFormatter.formatCurrency(_monthlySavingsValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'FIRE Number': NumberFormatter.formatCurrency(_result!.fireNumber, symbol: _symbol),
        'Corpus Needed': NumberFormatter.formatCurrency(_result!.corpusNeeded, symbol: _symbol),
        'Monthly Savings Needed': NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'FIRE: ${NumberFormatter.formatCurrency(_result!.fireNumber, symbol: _symbol)} | '
          '${_result!.isOnTrack ? "On Track" : "Off Track"}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_expenseValue <= 0) return;

    setState(() {
      _result = RetirementCalculators.calculateFire(
        currentAge: _currentAge,
        retirementAge: _retirementAge,
        monthlyExpense: _expenseValue,
        currentSavings: _savingsValue,
        monthlySavings: _monthlySavingsValue,
        expectedReturn: _expectedReturn,
        inflationRate: _inflation,
        swr: 4.0,
      );
    });
  }

  void _reset() {
    setState(() {
      _expenseController.clear();
      _savingsController.clear();
      _monthlySavingsController.clear();
      _currentAge = 30;
      _retirementAge = 45;
      _expectedReturn = 12.0;
      _inflation = 6.0;
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
                  buildSectionTitle('Your Profile'),
                  Row(
                    children: [
                      Expanded(
                        child: AppSliderField(
                          label: 'Current Age',
                          value: _currentAge.toDouble(),
                          min: 18, max: 70, divisions: 52,
                          displayValue: (v) => '${v.toInt()} yrs',
                          onChanged: (v) => setState(() { _currentAge = v.toInt(); _result = null; }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppSliderField(
                          label: 'Retirement Age',
                          value: _retirementAge.toDouble(),
                          min: 30, max: 70, divisions: 40,
                          displayValue: (v) => '${v.toInt()} yrs',
                          onChanged: (v) => setState(() { _retirementAge = v.toInt(); _result = null; }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Current Monthly Expenses',
                    hint: '30000',
                    controller: _expenseController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Current Savings/Investments',
                    hint: '500000',
                    controller: _savingsController,
                    prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return null; if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Savings',
                    hint: '10000',
                    controller: _monthlySavingsController,
                    prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return null; if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Invalid'; return null; },
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
                  buildSectionTitle('Assumptions'),
                  AppSliderField(
                    label: 'Expected Return',
                    value: _expectedReturn,
                    min: 1, max: 25, divisions: 240,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _expectedReturn = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Inflation Rate',
                    value: _inflation,
                    min: 1, max: 15, divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _inflation = v; _result = null; }),
                  ),
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
                    color: AppColors.retirement,
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.retirement),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
              const SizedBox(height: 16),
              _buildProgressBar(),
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
          buildSectionTitle('FIRE Analysis'),
          Center(
            child: Column(
              children: [
                const Text('FIRE Number (4% Rule)', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.fireNumber,
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
                child: ResultCard(label: 'Corpus Needed',
                    value: NumberFormatter.formatCurrency(r.corpusNeeded, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Monthly Savings Needed',
                    value: NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol),
                    valueColor: r.isOnTrack ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Years to Financial Independence',
            value: r.yearsToFI > 0 ? '${r.yearsToFI.toStringAsFixed(1)} years' : 'Already FI!',
            isHighlighted: true,
            subtitle: r.isOnTrack ? 'You are on track!' : 'Increase savings to stay on track',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'FIRE Summary',
            items: [
              ResultItem(label: 'Target Retirement Age', value: '$_retirementAge'),
              ResultItem(label: 'Monthly Expense at Retirement',
                  value: NumberFormatter.formatCurrency(_expenseValue * pow(1 + _inflation / 100, _retirementAge - _currentAge), symbol: symbol)),
              ResultItem(label: 'FIRE Number (4% Rule)', value: NumberFormatter.formatCurrency(r.fireNumber, symbol: symbol), isHighlighted: true),
              ResultItem(label: 'Corpus Required', value: NumberFormatter.formatCurrency(r.corpusNeeded, symbol: symbol)),
              ResultItem(label: 'Monthly Savings Needed', value: NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol),
                  color: r.isOnTrack ? AppColors.success : AppColors.error),
              ResultItem(label: 'Status', value: r.isOnTrack ? '✓ On Track' : '⚠ Off Track',
                  color: r.isOnTrack ? AppColors.success : AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final r = _result!;
    final progress = r.corpusNeeded > 0 ? (_savingsValue / r.corpusNeeded).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Progress to FIRE'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.retirement),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% of FIRE target achieved',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

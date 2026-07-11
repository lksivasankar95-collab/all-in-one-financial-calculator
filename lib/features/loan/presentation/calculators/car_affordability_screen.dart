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

class CarAffordabilityScreen extends CalculatorBaseScreen {
  const CarAffordabilityScreen({super.key})
      : super(
          calculatorId: 'car_affordability',
          calculatorName: 'Car Affordability',
          category: 'Loan',
        );

  @override
  ConsumerState<CarAffordabilityScreen> createState() =>
      _CarAffordabilityScreenState();
}

class _CarAffordabilityResult {
  final double maxCarPrice;
  final double loanAmount;
  final double emi;
  final double totalInterest;
  final double totalCost;
  final double downPayment;
  final double monthlyBudget;
  final double rate;

  const _CarAffordabilityResult({
    required this.maxCarPrice,
    required this.loanAmount,
    required this.emi,
    required this.totalInterest,
    required this.totalCost,
    required this.downPayment,
    required this.monthlyBudget,
    required this.rate,
  });
}

class _CarAffordabilityScreenState
    extends CalculatorBaseState<CarAffordabilityScreen> {
  final _monthlyBudgetController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _interestRate = 8.5;
  int _tenureYears = 5;

  _CarAffordabilityResult? _result;

  @override
  void dispose() {
    _monthlyBudgetController.dispose();
    _downPaymentController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _budgetValue =>
      NumberFormatter.tryParse(_monthlyBudgetController.text) ?? 0;

  double get _downPaymentValue =>
      NumberFormatter.tryParse(_downPaymentController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Monthly Budget':
          NumberFormatter.formatCurrency(_budgetValue, symbol: symbol),
      'Interest Rate': NumberFormatter.formatPercent(_interestRate),
      'Loan Tenure': '$_tenureYears years',
      'Down Payment':
          NumberFormatter.formatCurrency(_downPaymentValue, symbol: symbol),
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Max Car Price':
          NumberFormatter.formatCurrency(_result!.maxCarPrice, symbol: symbol),
      'Loan Amount':
          NumberFormatter.formatCurrency(_result!.loanAmount, symbol: symbol),
      'Monthly EMI':
          NumberFormatter.formatCurrency(_result!.emi, symbol: symbol),
      'Total Cost':
          NumberFormatter.formatCurrency(_result!.totalCost, symbol: symbol),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'Max Car: ${NumberFormatter.formatCurrency(_result!.maxCarPrice, symbol: symbol)} | '
        'EMI: ${NumberFormatter.formatCurrency(_result!.emi, symbol: symbol)}/mo | '
        'Total: ${NumberFormatter.formatCurrency(_result!.totalCost, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final budget = _budgetValue;
    final downPayment = _downPaymentValue;
    if (budget <= 0) return;

    final int n = _tenureYears * 12;
    final double r = _interestRate / 1200;

    double maxLoan;
    if (r == 0) {
      maxLoan = budget * n;
    } else {
      final double factor = pow(1 + r, n).toDouble();
      maxLoan = budget * (factor - 1) / (r * factor);
    }

    final double maxCarPrice = maxLoan + downPayment;
    final double loanAmount = maxLoan;
    final double totalCost = budget * n + downPayment;
    final double totalInterest = budget * n - maxLoan;

    setState(() {
      _result = _CarAffordabilityResult(
        maxCarPrice: maxCarPrice,
        loanAmount: loanAmount,
        emi: budget,
        totalInterest: totalInterest > 0 ? totalInterest : 0,
        totalCost: totalCost,
        downPayment: downPayment,
        monthlyBudget: budget,
        rate: _interestRate,
      );
    });
  }

  void _reset() {
    setState(() {
      _monthlyBudgetController.clear();
      _downPaymentController.clear();
      _interestRate = 8.5;
      _tenureYears = 5;
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
                  buildSectionTitle('Your Budget'),
                  AppTextField(
                    label: 'Monthly Budget (EMI)',
                    hint: '15000',
                    controller: _monthlyBudgetController,
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
                    label: 'Down Payment',
                    hint: '100000',
                    controller: _downPaymentController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Loan Terms'),
                  AppSliderField(
                    label: 'Interest Rate',
                    value: _interestRate,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _interestRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Loan Tenure',
                    value: _tenureYears.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _tenureYears = v.toInt();
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
                          icon: Icons.directions_car_rounded,
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final double downPaymentPct = r.maxCarPrice > 0
        ? (r.downPayment / r.maxCarPrice) * 100
        : 0;

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Affordable Car Price'),
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    AnimatedResultValue(
                      value: r.maxCarPrice,
                      formatter: (v) =>
                          NumberFormatter.formatCurrency(v, symbol: symbol),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.loan,
                      ),
                    ),
                    const Text(
                      'Maximum Affordable Car Price',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Loan Amount',
                      value: NumberFormatter.formatCurrency(
                          r.loanAmount, symbol: symbol),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Down Payment',
                      value: NumberFormatter.formatCurrency(
                          r.downPayment, symbol: symbol),
                      valueColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ResultCard(
                label: 'Down Payment % of Car Price',
                value: NumberFormatter.formatPercent(downPaymentPct, decimals: 1),
                valueColor: AppColors.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Monthly Payment Breakdown'),
              const SizedBox(height: 8),
              ResultCard(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(
                    r.emi, symbol: symbol),
                isHighlighted: true,
                valueColor: AppColors.loan,
                subtitle:
                    'Over ${_tenureYears == 1 ? "1 year" : "$_tenureYears years"} @ ${r.rate.toStringAsFixed(1)}% p.a.',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Total Interest',
                      value: NumberFormatter.formatCurrency(
                          r.totalInterest, symbol: symbol),
                      valueColor: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Total Cost',
                      value: NumberFormatter.formatCurrency(
                          r.totalCost, symbol: symbol),
                      isHighlighted: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ResultSummaryCard(
                title: 'Summary',
                items: [
                  ResultItem(
                    label: 'Max Car Price',
                    value: NumberFormatter.formatCurrency(
                        r.maxCarPrice, symbol: symbol),
                    isHighlighted: true,
                    color: AppColors.loan,
                  ),
                  ResultItem(
                    label: 'Loan Amount',
                    value: NumberFormatter.formatCurrency(
                        r.loanAmount, symbol: symbol),
                  ),
                  ResultItem(
                    label: 'Down Payment',
                    value: NumberFormatter.formatCurrency(
                        r.downPayment, symbol: symbol),
                    color: AppColors.warning,
                  ),
                  ResultItem(
                    label: 'Monthly EMI',
                    value: NumberFormatter.formatCurrency(
                        r.emi, symbol: symbol),
                    isHighlighted: true,
                  ),
                  ResultItem(
                    label: 'Total Interest',
                    value: NumberFormatter.formatCurrency(
                        r.totalInterest, symbol: symbol),
                    color: AppColors.error,
                  ),
                  ResultItem(
                    label: 'Total Cost',
                    value: NumberFormatter.formatCurrency(
                        r.totalCost, symbol: symbol),
                    isHighlighted: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

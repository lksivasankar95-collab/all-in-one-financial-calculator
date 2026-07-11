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

class SavingsProjectionScreen extends CalculatorBaseScreen {
  const SavingsProjectionScreen({super.key})
      : super(
          calculatorId: 'savings_projection',
          calculatorName: 'Savings Projection',
          category: 'Savings',
        );

  @override
  ConsumerState<SavingsProjectionScreen> createState() =>
      _SavingsProjectionScreenState();
}

class _SavingsProjectionScreenState
    extends CalculatorBaseState<SavingsProjectionScreen> {
  final _currentSavingsController = TextEditingController();
  double _monthlyAddition = 10000;
  double _annualReturn = 10.0;
  double _years = 10.0;
  SavingsProjectionResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentSavingsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Savings': NumberFormatter.formatCurrency(
            _currentSavings, symbol: _symbol),
        'Monthly Addition':
            NumberFormatter.formatCurrency(_monthlyAddition, symbol: _symbol),
        'Annual Return': NumberFormatter.formatPercent(_annualReturn),
        'Projection Period': '${_years.toInt()} years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Final Amount': NumberFormatter.formatCurrency(
              _result!.finalAmount, symbol: _symbol),
          'Total Contributions': NumberFormatter.formatCurrency(
              _result!.totalContributions, symbol: _symbol),
          'Total Interest Earned': NumberFormatter.formatCurrency(
              _result!.totalInterest, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Savings projection: ${NumberFormatter.formatCurrency(_currentSavings, symbol: _symbol)} current + '
          '${NumberFormatter.formatCurrency(_monthlyAddition, symbol: _symbol)}/mo for ${_years.toInt()} years = '
          '${NumberFormatter.formatCurrency(_result!.finalAmount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _currentSavings =>
      NumberFormatter.tryParse(_currentSavingsController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final int t = _years.toInt();
    final double r = _annualReturn / 100;
    final double monthlyR = _annualReturn / 1200;
    final int n = t * 12;

    final double fvCurrent = _currentSavings * pow(1 + monthlyR, n);
    final double fvAddition = _monthlyAddition *
        (((pow(1 + monthlyR, n) - 1) / monthlyR) * (1 + monthlyR));
    final double finalAmount = fvCurrent + fvAddition;
    final double totalContributions =
        _currentSavings + (_monthlyAddition * n);
    final double totalInterest = finalAmount - totalContributions;

    final List<SavingsYearData> yearlyData = [];
    for (int y = 1; y <= t; y++) {
      final double yrEnd = _currentSavings * pow(1 + r, y) +
          _monthlyAddition *
              (((pow(1 + r, y) - 1) / r) * (1 + r));
      final double contributed =
          _currentSavings + (_monthlyAddition * 12 * y);
      final double interest = yrEnd - contributed;
      yearlyData.add(SavingsYearData(
        year: y,
        value: yrEnd,
        contributed: contributed,
        interest: interest,
      ));
    }

    setState(() {
      _result = SavingsProjectionResult(
        finalAmount: finalAmount,
        totalContributions: totalContributions,
        totalInterest: totalInterest,
        yearlyData: yearlyData,
      );
    });
  }

  void _reset() {
    setState(() {
      _currentSavingsController.clear();
      _monthlyAddition = 10000;
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
                  buildSectionTitle('Savings Details'),
                  AppTextField(
                    label: 'Current Savings',
                    hint: '50,000',
                    controller: _currentSavingsController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Monthly Addition',
                    value: _monthlyAddition,
                    min: 0,
                    max: 100000,
                    divisions: 200,
                    displayValue: (v) =>
                        NumberFormatter.formatCurrency(v, symbol: symbol),
                    onChanged: (v) => setState(() {
                      _monthlyAddition = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Return',
                    value: _annualReturn,
                    min: 1,
                    max: 15,
                    divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualReturn = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Projection Period',
                    value: _years,
                    min: 1,
                    max: 40,
                    divisions: 39,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _years = v;
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
              const SizedBox(height: 16),
              _buildYearlyTable(symbol),
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
          buildSectionTitle('Projection Results'),
          Center(
            child: Column(
              children: [
                Text(
                  'Final Amount After ${_years.toInt()} Years',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.finalAmount,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
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
                  value: NumberFormatter.formatCurrency(
                      r.totalContributions, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Interest',
                  value: NumberFormatter.formatCurrency(
                      r.totalInterest, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Projection Summary',
            items: [
              ResultItem(
                label: 'Current Savings',
                value: NumberFormatter.formatCurrency(
                    _currentSavings, symbol: symbol),
              ),
              ResultItem(
                label: 'Monthly Addition',
                value: NumberFormatter.formatCurrency(
                    _monthlyAddition, symbol: symbol),
              ),
              ResultItem(
                label: 'Expected Return',
                value: NumberFormatter.formatPercent(_annualReturn),
              ),
              ResultItem(
                label: 'Period',
                value: '${_years.toInt()} years',
              ),
              ResultItem(
                label: 'Total Contributions',
                value: NumberFormatter.formatCurrency(
                    r.totalContributions, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Interest Earned',
                value: NumberFormatter.formatCurrency(
                    r.totalInterest, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Final Amount',
                value: NumberFormatter.formatCurrency(
                    r.finalAmount, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyTable(String symbol) {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Year-by-Year Projection'),
          const SizedBox(height: 8),
          ...r.yearlyData.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Y${d.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.savings,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Value: ${NumberFormatter.formatCurrency(d.value, symbol: symbol)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Contributed: ${NumberFormatter.formatCurrency(d.contributed, symbol: symbol)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${NumberFormatter.formatCurrency(d.interest, symbol: symbol)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class SavingsProjectionResult {
  final double finalAmount;
  final double totalContributions;
  final double totalInterest;
  final List<SavingsYearData> yearlyData;

  const SavingsProjectionResult({
    required this.finalAmount,
    required this.totalContributions,
    required this.totalInterest,
    required this.yearlyData,
  });
}

class SavingsYearData {
  final int year;
  final double value;
  final double contributed;
  final double interest;

  const SavingsYearData({
    required this.year,
    required this.value,
    required this.contributed,
    required this.interest,
  });
}

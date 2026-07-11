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
import '../../domain/loan_calculators.dart';

class MortgageScreen extends CalculatorBaseScreen {
  const MortgageScreen({super.key})
      : super(
          calculatorId: 'mortgage',
          calculatorName: 'Mortgage Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<MortgageScreen> createState() => _MortgageScreenState();
}

class _MortgageScreenState extends CalculatorBaseState<MortgageScreen> {
  final _homePriceController = TextEditingController();
  final _propertyTaxController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _downPaymentPercent = 20;
  double _annualRate = 6.5;
  int _years = 30;

  MortgageResult? _result;

  @override
  void dispose() {
    _homePriceController.dispose();
    _propertyTaxController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _homePriceValue =>
      NumberFormatter.tryParse(_homePriceController.text) ?? 0;

  double get _propertyTaxValue =>
      NumberFormatter.tryParse(_propertyTaxController.text) ?? 0;

  double get _insuranceValue =>
      NumberFormatter.tryParse(_insuranceController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Home Price':
          NumberFormatter.formatCurrency(_homePriceValue, symbol: symbol),
      'Down Payment':
          NumberFormatter.formatPercent(_downPaymentPercent),
      'Interest Rate': NumberFormatter.formatPercent(_annualRate),
      'Loan Term': '$_years years',
      'Property Tax/year':
          NumberFormatter.formatCurrency(_propertyTaxValue, symbol: symbol),
      'Insurance/year':
          NumberFormatter.formatCurrency(_insuranceValue, symbol: symbol),
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Monthly P&I':
          NumberFormatter.formatCurrency(_result!.monthlyPayment, symbol: symbol),
      'Property Tax':
          NumberFormatter.formatCurrency(_result!.propertyTax, symbol: symbol),
      'Insurance':
          NumberFormatter.formatCurrency(_result!.insurance, symbol: symbol),
      'Total Monthly':
          NumberFormatter.formatCurrency(_result!.totalMonthlyPayment, symbol: symbol),
      'Total Payment':
          NumberFormatter.formatCurrency(_result!.totalPayment, symbol: symbol),
      'Total Interest':
          NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'Total Monthly: ${NumberFormatter.formatCurrency(_result!.totalMonthlyPayment, symbol: symbol)} | '
        'Total Interest: ${NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final homePrice = _homePriceValue;
    if (homePrice <= 0) return;

    setState(() {
      _result = LoanCalculators.calculateMortgage(
        homePrice: homePrice,
        downPaymentPercent: _downPaymentPercent,
        annualRate: _annualRate,
        years: _years,
        annualPropertyTax: _propertyTaxValue,
        annualInsurance: _insuranceValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _homePriceController.clear();
      _propertyTaxController.clear();
      _insuranceController.clear();
      _downPaymentPercent = 20;
      _annualRate = 6.5;
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
                  buildSectionTitle('Property & Loan Details'),
                  AppTextField(
                    label: 'Home Price',
                    hint: '5000000',
                    controller: _homePriceController,
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
                    label: 'Down Payment',
                    value: _downPaymentPercent,
                    min: 5,
                    max: 50,
                    divisions: 90,
                    displayValue: (v) =>
                        '${v.toStringAsFixed(0)}% (${NumberFormatter.formatCurrency(_homePriceValue * v / 100, symbol: symbol)})',
                    onChanged: (v) {
                      setState(() {
                        _downPaymentPercent = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Interest Rate',
                    value: _annualRate,
                    min: 1,
                    max: 20,
                    divisions: 190,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _annualRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Loan Term',
                    value: _years.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 25,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _years = v.toInt();
                        if (_result != null) _result = null;
                      });
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
                  buildSectionTitle('Additional Costs'),
                  AppTextField(
                    label: 'Annual Property Tax',
                    hint: '12000',
                    controller: _propertyTaxController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Annual Home Insurance',
                    hint: '4800',
                    controller: _insuranceController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
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
    final downPaymentValue = _homePriceValue * _downPaymentPercent / 100;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Monthly Payment Breakdown'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Total Monthly Payment',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalMonthlyPayment,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.loan,
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
                  label: 'Principal & Interest',
                  value: NumberFormatter.formatCurrency(
                      r.monthlyPayment, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Property Tax',
                  value: NumberFormatter.formatCurrency(
                      r.propertyTax, symbol: symbol),
                  valueColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Insurance',
                  value: NumberFormatter.formatCurrency(
                      r.insurance, symbol: symbol),
                  valueColor: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Down Payment',
                  value: NumberFormatter.formatCurrency(
                      downPaymentValue, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultCard(
            label: 'Total Payment (P&I + Tax + Ins)',
            value: NumberFormatter.formatCurrency(
                r.totalMonthlyPayment, symbol: symbol),
            isHighlighted: true,
            subtitle:
                'Over $_years years @ ${_annualRate.toStringAsFixed(1)}% p.a.',
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
                  label: 'Total Payment',
                  value: NumberFormatter.formatCurrency(
                      r.totalPayment, symbol: symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Home Price',
                value: NumberFormatter.formatCurrency(
                    _homePriceValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Down Payment',
                value: NumberFormatter.formatCurrency(
                    downPaymentValue, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Loan Amount',
                value: NumberFormatter.formatCurrency(
                    r.principalAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Monthly P&I',
                value: NumberFormatter.formatCurrency(
                    r.monthlyPayment, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Monthly',
                value: NumberFormatter.formatCurrency(
                    r.totalMonthlyPayment, symbol: symbol),
                isHighlighted: true,
                color: AppColors.loan,
              ),
              ResultItem(
                label: 'Total Interest',
                value: NumberFormatter.formatCurrency(
                    r.totalInterest, symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Total Payment',
                value: NumberFormatter.formatCurrency(
                    r.totalPayment, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

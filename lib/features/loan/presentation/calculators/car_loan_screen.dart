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

class CarLoanScreen extends CalculatorBaseScreen {
  const CarLoanScreen({super.key})
      : super(
          calculatorId: 'car_loan',
          calculatorName: 'Car Loan Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<CarLoanScreen> createState() => _CarLoanScreenState();
}

class _CarLoanScreenState extends CalculatorBaseState<CarLoanScreen> {
  final _carPriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _downPaymentPercent = 20;
  double _annualRate = 9.0;
  int _tenureYears = 5;

  CarLoanResult? _result;

  @override
  void dispose() {
    _carPriceController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _carPriceValue =>
      NumberFormatter.tryParse(_carPriceController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Car Price':
          NumberFormatter.formatCurrency(_carPriceValue, symbol: symbol),
      'Down Payment':
          NumberFormatter.formatPercent(_downPaymentPercent),
      'Interest Rate': NumberFormatter.formatPercent(_annualRate),
      'Tenure': '$_tenureYears years',
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Loan Amount':
          NumberFormatter.formatCurrency(_result!.loanAmount, symbol: symbol),
      'EMI':
          NumberFormatter.formatCurrency(_result!.emi, symbol: symbol),
      'Total Interest':
          NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol),
      'Total Payment':
          NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol),
      'Down Payment':
          NumberFormatter.formatCurrency(_result!.downPayment, symbol: symbol),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'EMI: ${NumberFormatter.formatCurrency(_result!.emi, symbol: symbol)}/mo | '
        'Total: ${NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol)} | '
        'Down: ${NumberFormatter.formatCurrency(_result!.downPayment, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final carPrice = _carPriceValue;
    if (carPrice <= 0) return;

    setState(() {
      _result = LoanCalculators.calculateCarLoan(
        carPrice: carPrice,
        downPaymentPercent: _downPaymentPercent,
        annualRate: _annualRate,
        years: _tenureYears,
      );
    });
  }

  void _reset() {
    setState(() {
      _carPriceController.clear();
      _downPaymentPercent = 20;
      _annualRate = 9.0;
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
                  buildSectionTitle('Car & Loan Details'),
                  AppTextField(
                    label: 'Car Price (On-Road)',
                    hint: '800000',
                    controller: _carPriceController,
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
                    min: 10,
                    max: 50,
                    divisions: 80,
                    displayValue: (v) =>
                        '${v.toStringAsFixed(0)}% (${NumberFormatter.formatCurrency(_carPriceValue * v / 100, symbol: symbol)})',
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
                    min: 7,
                    max: 24,
                    divisions: 170,
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
                    label: 'Loan Tenure',
                    value: _tenureYears.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 60,
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Monthly EMI',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.emi,
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
                  valueColor: AppColors.success,
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
                      r.totalAmount, symbol: symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'On-Road Price',
                value: NumberFormatter.formatCurrency(
                    r.onRoadPrice, symbol: symbol),
              ),
              ResultItem(
                label: 'Down Payment',
                value: NumberFormatter.formatCurrency(
                    r.downPayment, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Loan Amount',
                value: NumberFormatter.formatCurrency(
                    r.loanAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(
                    r.emi, symbol: symbol),
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
                    r.totalAmount, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

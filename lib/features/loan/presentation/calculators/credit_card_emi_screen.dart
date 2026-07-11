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

class CreditCardEmiScreen extends CalculatorBaseScreen {
  const CreditCardEmiScreen({super.key})
      : super(
          calculatorId: 'credit_card_emi',
          calculatorName: 'Credit Card EMI Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<CreditCardEmiScreen> createState() =>
      _CreditCardEmiScreenState();
}

class _CreditCardEmiScreenState
    extends CalculatorBaseState<CreditCardEmiScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _monthlyRate = 2.5;
  int _months = 6;
  double _processingFeePercent = 1.0;

  CreditCardEmiResult? _result;

  static const List<int> _monthOptions = [3, 6, 9, 12, 18, 24];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _amountValue =>
      NumberFormatter.tryParse(_amountController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Transaction Amount':
          NumberFormatter.formatCurrency(_amountValue, symbol: symbol),
      'Monthly Rate': NumberFormatter.formatPercent(_monthlyRate),
      'Tenure': '$_months months',
      'Processing Fee': NumberFormatter.formatPercent(_processingFeePercent),
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Monthly EMI':
          NumberFormatter.formatCurrency(_result!.monthlyEmi, symbol: symbol),
      'Total Interest':
          NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol),
      'Total Amount':
          NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol),
      'Processing Fee':
          NumberFormatter.formatCurrency(_result!.processingFee, symbol: symbol),
      'Effective Annual Rate':
          NumberFormatter.formatPercent(_result!.effectiveRate),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'EMI: ${NumberFormatter.formatCurrency(_result!.monthlyEmi, symbol: symbol)}/mo | '
        'Interest: ${NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol)} | '
        'Eff. Rate: ${NumberFormatter.formatPercent(_result!.effectiveRate)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amountValue;
    if (amount <= 0) return;

    setState(() {
      _result = LoanCalculators.calculateCreditCardEmi(
        amount: amount,
        monthlyRate: _monthlyRate,
        months: _months,
        processingFeePercent: _processingFeePercent,
      );
    });
  }

  void _reset() {
    setState(() {
      _amountController.clear();
      _monthlyRate = 2.5;
      _months = 6;
      _processingFeePercent = 1.0;
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
                  buildSectionTitle('Transaction Details'),
                  AppTextField(
                    label: 'Transaction Amount',
                    hint: '50000',
                    controller: _amountController,
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
                    label: 'Monthly Interest Rate',
                    value: _monthlyRate,
                    min: 1,
                    max: 4,
                    divisions: 60,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _monthlyRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Tenure (Months)',
                    value: _months.toDouble(),
                    min: 3,
                    max: 24,
                    divisions: 21,
                    displayValue: (v) {
                      final idx = (v / 3).round() - 1;
                      final months = idx >= 0 && idx < _monthOptions.length
                          ? _monthOptions[idx]
                          : v.toInt();
                      return '$months months';
                    },
                    onChanged: (v) {
                      final idx = (v / 3).round() - 1;
                      final months = idx >= 0 && idx < _monthOptions.length
                          ? _monthOptions[idx]
                          : v.toInt();
                      setState(() {
                        _months = months.clamp(3, 24);
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Processing Fee',
                    value: _processingFeePercent,
                    min: 0,
                    max: 3,
                    divisions: 60,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _processingFeePercent = v;
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
                          icon: Icons.credit_card_rounded,
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
                  value: r.monthlyEmi,
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
                  label: 'Total Interest',
                  value: NumberFormatter.formatCurrency(
                      r.totalInterest, symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Processing Fee',
                  value: NumberFormatter.formatCurrency(
                      r.processingFee, symbol: symbol),
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
                  label: 'Total Payment',
                  value: NumberFormatter.formatCurrency(
                      r.totalAmount, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Effective Annual Rate',
                  value: NumberFormatter.formatPercent(r.effectiveRate),
                  valueColor: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Transaction Amount',
                value: NumberFormatter.formatCurrency(
                    _amountValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Monthly Interest Rate',
                value: NumberFormatter.formatPercent(_monthlyRate),
              ),
              ResultItem(
                label: 'Processing Fee',
                value: NumberFormatter.formatCurrency(
                    r.processingFee, symbol: symbol),
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(
                    r.monthlyEmi, symbol: symbol),
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
              ResultItem(
                label: 'Effective Annual Rate',
                value: NumberFormatter.formatPercent(r.effectiveRate),
                isHighlighted: true,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credit card EMI uses a reducing balance method at '
                    '${_monthlyRate.toStringAsFixed(1)}% per month. The effective '
                    'annual rate of ${NumberFormatter.formatPercent(r.effectiveRate)} '
                    'reflects the compounded cost over a year.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

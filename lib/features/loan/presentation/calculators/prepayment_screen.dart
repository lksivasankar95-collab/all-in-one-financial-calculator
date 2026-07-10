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

class PrepaymentScreen extends CalculatorBaseScreen {
  const PrepaymentScreen({super.key})
      : super(
          calculatorId: 'prepayment',
          calculatorName: 'Prepayment Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<PrepaymentScreen> createState() => _PrepaymentScreenState();
}

class _PrepaymentScreenState extends CalculatorBaseState<PrepaymentScreen> {
  final _principalController = TextEditingController();
  final _prepaymentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _annualRate = 8.5;
  int _tenureYears = 20;
  int _afterMonth = 12;

  PrepaymentResult? _result;

  @override
  void dispose() {
    _principalController.dispose();
    _prepaymentController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _principalValue =>
      NumberFormatter.tryParse(_principalController.text) ?? 0;

  double get _prepaymentValue =>
      NumberFormatter.tryParse(_prepaymentController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Loan Amount':
          NumberFormatter.formatCurrency(_principalValue, symbol: symbol),
      'Interest Rate': NumberFormatter.formatPercent(_annualRate),
      'Loan Tenure': '$_tenureYears years',
      'Prepayment Amount':
          NumberFormatter.formatCurrency(_prepaymentValue, symbol: symbol),
      'After Month': '$_afterMonth months',
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Original EMI':
          NumberFormatter.formatCurrency(_result!.originalEmi, symbol: symbol),
      'Interest Without Prepayment': NumberFormatter.formatCurrency(
          _result!.totalInterestWithout,
          symbol: symbol),
      'Interest With Prepayment': NumberFormatter.formatCurrency(
          _result!.totalInterestWith,
          symbol: symbol),
      'Interest Saved':
          NumberFormatter.formatCurrency(_result!.interestSaved, symbol: symbol),
      'Months Saved': '${_result!.monthsSaved} months',
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'Interest Saved: ${NumberFormatter.formatCurrency(_result!.interestSaved, symbol: symbol)} | '
        'Months Saved: ${_result!.monthsSaved}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final principal = _principalValue;
    final prepayment = _prepaymentValue;
    if (principal <= 0 || prepayment <= 0) return;

    setState(() {
      _result = LoanCalculators.calculatePrepayment(
        originalPrincipal: principal,
        annualRate: _annualRate,
        originalTenureYears: _tenureYears,
        prepaymentAmount: prepayment,
        afterMonth: _afterMonth,
      );
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _prepaymentController.clear();
      _annualRate = 8.5;
      _tenureYears = 20;
      _afterMonth = 12;
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
                  buildSectionTitle('Loan Details'),
                  AppTextField(
                    label: 'Original Loan Amount',
                    hint: '2500000',
                    controller: _principalController,
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
                    label: 'Interest Rate',
                    value: _annualRate,
                    min: 1,
                    max: 30,
                    divisions: 290,
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
                    label: 'Original Tenure',
                    value: _tenureYears.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _tenureYears = v.toInt();
                        // Clamp afterMonth within total months
                        final maxMonth = _tenureYears * 12 - 1;
                        if (_afterMonth > maxMonth && maxMonth > 0) {
                          _afterMonth = maxMonth;
                        }
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
                  buildSectionTitle('Prepayment Details'),
                  AppTextField(
                    label: 'Prepayment Amount',
                    hint: '200000',
                    controller: _prepaymentController,
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
                    label: 'Make Prepayment After',
                    value: _afterMonth.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "month" : "months"}',
                    onChanged: (v) {
                      setState(() {
                        _afterMonth = v.toInt();
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate Savings',
                          icon: Icons.savings_rounded,
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
          buildSectionTitle('Prepayment Savings'),
          // Savings highlight
          Center(
            child: Column(
              children: [
                const Text(
                  'Interest Saved',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.interestSaved,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${r.monthsSaved} months saved',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ResultCard(
            label: 'Original EMI',
            value: NumberFormatter.formatCurrency(r.originalEmi, symbol: symbol),
            isHighlighted: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Interest Without Prepayment',
                  value: NumberFormatter.formatCurrency(
                      r.totalInterestWithout,
                      symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Interest With Prepayment',
                  value: NumberFormatter.formatCurrency(
                      r.totalInterestWith,
                      symbol: symbol),
                  valueColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(r.originalEmi,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Prepayment After',
                value: '$_afterMonth months',
              ),
              ResultItem(
                label: 'Interest Without Prepayment',
                value: NumberFormatter.formatCurrency(r.totalInterestWithout,
                    symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Interest With Prepayment',
                value: NumberFormatter.formatCurrency(r.totalInterestWith,
                    symbol: symbol),
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Interest Saved',
                value: NumberFormatter.formatCurrency(r.interestSaved,
                    symbol: symbol),
                isHighlighted: true,
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Months Saved',
                value: '${r.monthsSaved} months',
                isHighlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Making a prepayment of '
                    '${NumberFormatter.formatCurrency(_prepaymentValue, symbol: symbol)} '
                    'after $_afterMonth months will save you '
                    '${NumberFormatter.formatCurrency(r.interestSaved, symbol: symbol)} '
                    'in interest and close your loan ${r.monthsSaved} months earlier.',
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

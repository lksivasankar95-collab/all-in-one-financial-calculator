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

class PersonalLoanScreen extends CalculatorBaseScreen {
  const PersonalLoanScreen({super.key})
      : super(
          calculatorId: 'personal_loan',
          calculatorName: 'Personal Loan Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<PersonalLoanScreen> createState() => _PersonalLoanScreenState();
}

class _PersonalLoanScreenState extends CalculatorBaseState<PersonalLoanScreen> {
  final _loanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _annualRate = 12.0;
  int _tenureYears = 3;
  double _processingFeePercent = 1.5;

  PersonalLoanResult? _result;

  @override
  void dispose() {
    _loanController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _loanValue =>
      NumberFormatter.tryParse(_loanController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Loan Amount':
          NumberFormatter.formatCurrency(_loanValue, symbol: symbol),
      'Interest Rate': NumberFormatter.formatPercent(_annualRate),
      'Tenure': '$_tenureYears years',
      'Processing Fee': NumberFormatter.formatPercent(_processingFeePercent),
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'EMI':
          NumberFormatter.formatCurrency(_result!.emi, symbol: symbol),
      'Total Interest':
          NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol),
      'Total Amount':
          NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol),
      'Processing Fee':
          NumberFormatter.formatCurrency(_result!.processingFee, symbol: symbol),
      'APR':
          NumberFormatter.formatPercent(_result!.apr),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'EMI: ${NumberFormatter.formatCurrency(_result!.emi, symbol: symbol)}/mo | '
        'APR: ${NumberFormatter.formatPercent(_result!.apr)} | '
        'Interest: ${NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final loan = _loanValue;
    if (loan <= 0) return;

    setState(() {
      _result = LoanCalculators.calculatePersonalLoan(
        principal: loan,
        annualRate: _annualRate,
        years: _tenureYears,
        processingFeePercent: _processingFeePercent,
      );
    });
  }

  void _reset() {
    setState(() {
      _loanController.clear();
      _annualRate = 12.0;
      _tenureYears = 3;
      _processingFeePercent = 1.5;
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
                    label: 'Loan Amount',
                    hint: '500000',
                    controller: _loanController,
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
                    min: 8,
                    max: 36,
                    divisions: 280,
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
                  AppSliderField(
                    label: 'Processing Fee',
                    value: _processingFeePercent,
                    min: 0,
                    max: 5,
                    divisions: 100,
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
                  label: 'APR (incl. fees)',
                  value: NumberFormatter.formatPercent(r.apr),
                  valueColor: AppColors.info,
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
                label: 'Loan Amount',
                value: NumberFormatter.formatCurrency(
                    r.principalAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Processing Fee',
                value: NumberFormatter.formatCurrency(
                    r.processingFee, symbol: symbol),
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Stated Interest Rate',
                value: NumberFormatter.formatPercent(_annualRate),
              ),
              ResultItem(
                label: 'APR (incl. fees)',
                value: NumberFormatter.formatPercent(r.apr),
                isHighlighted: true,
                color: AppColors.info,
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
                    'APR (Annual Percentage Rate) includes the processing fee '
                    'to give you the true cost of the loan. '
                    'Your stated rate is ${NumberFormatter.formatPercent(_annualRate)} '
                    'but the effective APR is ${NumberFormatter.formatPercent(r.apr)}.',
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

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

class EducationLoanScreen extends CalculatorBaseScreen {
  const EducationLoanScreen({super.key})
      : super(
          calculatorId: 'education_loan',
          calculatorName: 'Education Loan Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<EducationLoanScreen> createState() =>
      _EducationLoanScreenState();
}

class _EducationLoanScreenState
    extends CalculatorBaseState<EducationLoanScreen> {
  final _loanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _annualRate = 11.0;
  int _courseYears = 4;
  int _repaymentYears = 10;

  EducationLoanResult? _result;

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
      'Course Duration': '$_courseYears years',
      'Repayment Period': '$_repaymentYears years',
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
      'Moratorium Interest':
          NumberFormatter.formatCurrency(_result!.moratoriumInterest, symbol: symbol),
      'Loan After Moratorium':
          NumberFormatter.formatCurrency(_result!.totalWithMoratorium, symbol: symbol),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'EMI: ${NumberFormatter.formatCurrency(_result!.emi, symbol: symbol)}/mo | '
        'Moratorium Interest: ${NumberFormatter.formatCurrency(_result!.moratoriumInterest, symbol: symbol)} | '
        'Total: ${NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final loan = _loanValue;
    if (loan <= 0) return;

    setState(() {
      _result = LoanCalculators.calculateEducationLoan(
        loanAmount: loan,
        annualRate: _annualRate,
        courseYears: _courseYears,
        repaymentYears: _repaymentYears,
      );
    });
  }

  void _reset() {
    setState(() {
      _loanController.clear();
      _annualRate = 11.0;
      _courseYears = 4;
      _repaymentYears = 10;
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
                    hint: '1000000',
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
                    max: 18,
                    divisions: 100,
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
                    label: 'Course Duration (Moratorium)',
                    value: _courseYears.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 40,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _courseYears = v.toInt();
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Repayment Period',
                    value: _repaymentYears.toDouble(),
                    min: 5,
                    max: 15,
                    divisions: 100,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _repaymentYears = v.toInt();
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
                          icon: Icons.school_rounded,
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
                  'Monthly EMI (after moratorium)',
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
                  label: 'Moratorium Interest',
                  value: NumberFormatter.formatCurrency(
                      r.moratoriumInterest, symbol: symbol),
                  valueColor: AppColors.warning,
                  subtitle: 'Accrued during $_courseYears yr course',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Loan After Moratorium',
                  value: NumberFormatter.formatCurrency(
                      r.totalWithMoratorium, symbol: symbol),
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
                  label: 'Total Amount',
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
                    _loanValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Moratorium Interest',
                value: NumberFormatter.formatCurrency(
                    r.moratoriumInterest, symbol: symbol),
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Loan After Moratorium',
                value: NumberFormatter.formatCurrency(
                    r.totalWithMoratorium, symbol: symbol),
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
                label: 'Total Amount',
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
                    'During your $_courseYears year course (moratorium period), '
                    'simple interest of ${NumberFormatter.formatCurrency(r.moratoriumInterest, symbol: symbol)} '
                    'accrues on your loan. Repayment begins after the course '
                    'for $_repaymentYears years on the total amount of '
                    '${NumberFormatter.formatCurrency(r.totalWithMoratorium, symbol: symbol)}.',
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

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

class LoanEligibilityScreen extends CalculatorBaseScreen {
  const LoanEligibilityScreen({super.key})
      : super(
          calculatorId: 'loan_eligibility',
          calculatorName: 'Loan Eligibility',
          category: 'Loan',
        );

  @override
  ConsumerState<LoanEligibilityScreen> createState() =>
      _LoanEligibilityScreenState();
}

class _LoanEligibilityScreenState
    extends CalculatorBaseState<LoanEligibilityScreen> {
  final _incomeController = TextEditingController();
  final _obligationsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _annualRate = 8.5;
  int _tenureYears = 20;

  // Results
  double? _maxLoan;
  double? _monthlyEmi;
  double? _foirUsed;
  bool? _isEligible;

  @override
  void dispose() {
    _incomeController.dispose();
    _obligationsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _maxLoan != null;

  double get _incomeValue =>
      NumberFormatter.tryParse(_incomeController.text) ?? 0;

  double get _obligationsValue =>
      NumberFormatter.tryParse(_obligationsController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Monthly Income':
          NumberFormatter.formatCurrency(_incomeValue, symbol: symbol),
      'Monthly Obligations':
          NumberFormatter.formatCurrency(_obligationsValue, symbol: symbol),
      'Interest Rate': NumberFormatter.formatPercent(_annualRate),
      'Loan Tenure': '$_tenureYears years',
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_maxLoan == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Maximum Loan Amount':
          NumberFormatter.formatCurrency(_maxLoan!, symbol: symbol),
      'Monthly EMI':
          NumberFormatter.formatCurrency(_monthlyEmi ?? 0, symbol: symbol),
      'FOIR Used': NumberFormatter.formatPercent((_foirUsed ?? 0) * 100),
      'Eligible': _isEligible == true ? 'Yes' : 'No',
    };
  }

  @override
  String get resultSummary {
    if (_maxLoan == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'Max Eligible Loan: ${NumberFormatter.formatCurrency(_maxLoan!, symbol: symbol)} '
        '| EMI: ${NumberFormatter.formatCurrency(_monthlyEmi ?? 0, symbol: symbol)}/mo';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final income = _incomeValue;
    if (income <= 0) return;

    final obligations = _obligationsValue;

    // FOIR = 50% of (income - existing obligations) available for EMI
    // Effective income available for new loan EMI
    final double availableIncome = income - obligations;
    if (availableIncome <= 0) {
      setState(() {
        _maxLoan = 0;
        _monthlyEmi = 0;
        _foirUsed = 0;
        _isEligible = false;
      });
      return;
    }

    // Standard FOIR = 50% of gross income but capped by obligations
    const double foir = 0.50;
    final double maxEmiByFoir = income * foir;
    // Actual max EMI = min(FOIR-based, available income after obligations)
    final double maxEmi = maxEmiByFoir > availableIncome
        ? availableIncome
        : maxEmiByFoir;

    final double maxLoan = LoanCalculators.calculateMaxLoanEligibility(
      monthlyIncome: income,
      annualRate: _annualRate,
      tenureYears: _tenureYears,
      foir: maxEmi / income,
    );

    // Compute EMI on max loan
    final emiResult = LoanCalculators.calculateEmi(
      principal: maxLoan,
      annualRate: _annualRate,
      tenureYears: _tenureYears,
    );

    final double effectiveFoir = maxEmi / income;

    setState(() {
      _maxLoan = maxLoan;
      _monthlyEmi = emiResult.emi;
      _foirUsed = effectiveFoir;
      _isEligible = maxLoan > 0;
    });
  }

  void _reset() {
    setState(() {
      _incomeController.clear();
      _obligationsController.clear();
      _annualRate = 8.5;
      _tenureYears = 20;
      _maxLoan = null;
      _monthlyEmi = null;
      _foirUsed = null;
      _isEligible = null;
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
                  buildSectionTitle('Income Details'),
                  AppTextField(
                    label: 'Monthly Income',
                    hint: '80000',
                    controller: _incomeController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid income';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_maxLoan != null) setState(() => _maxLoan = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Obligations (existing EMIs)',
                    hint: '0',
                    controller: _obligationsController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final val = NumberFormatter.tryParse(v) ?? 0;
                      if (val < 0) return 'Cannot be negative';
                      final income = _incomeValue;
                      if (income > 0 && val >= income) {
                        return 'Obligations exceed income';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_maxLoan != null) setState(() => _maxLoan = null);
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
                        if (_maxLoan != null) _maxLoan = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Loan Tenure',
                    value: _tenureYears.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _tenureYears = v.toInt();
                        if (_maxLoan != null) _maxLoan = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Check Eligibility',
                          icon: Icons.verified_rounded,
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
            if (_maxLoan != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final maxLoan = _maxLoan!;
    final monthlyEmi = _monthlyEmi ?? 0;
    final foirPct = (_foirUsed ?? 0) * 100;
    final eligible = _isEligible == true;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Eligibility Results'),
          // Eligibility badge
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: eligible
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: eligible
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    eligible
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: eligible ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    eligible ? 'Eligible for a Loan' : 'Not Eligible',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: eligible ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Max loan – animated
          Center(
            child: Column(
              children: [
                const Text(
                  'Maximum Loan Amount',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: maxLoan,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color:
                        eligible ? AppColors.loan : AppColors.textDisabled,
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
                  label: 'Monthly EMI',
                  value: NumberFormatter.formatCurrency(monthlyEmi,
                      symbol: symbol),
                  valueColor: AppColors.loan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'FOIR Used',
                  value: NumberFormatter.formatPercent(foirPct),
                  valueColor: foirPct > 60
                      ? AppColors.error
                      : AppColors.success,
                  subtitle: foirPct > 60 ? 'High obligation ratio' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Monthly Income',
                value: NumberFormatter.formatCurrency(_incomeValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Existing Obligations',
                value: NumberFormatter.formatCurrency(_obligationsValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'FOIR',
                value: NumberFormatter.formatPercent(foirPct),
              ),
              ResultItem(
                label: 'Max Loan Eligible',
                value: NumberFormatter.formatCurrency(maxLoan, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(monthlyEmi,
                    symbol: symbol),
                color: AppColors.loan,
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
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Based on 50% FOIR (Fixed Obligation to Income Ratio). '
                    'Actual eligibility may vary by lender policy.',
                    style: TextStyle(
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

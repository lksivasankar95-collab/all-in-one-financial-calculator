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
import '../../domain/savings_calculators.dart';

class EducationSavingsScreen extends CalculatorBaseScreen {
  const EducationSavingsScreen({super.key})
      : super(
          calculatorId: 'education_savings',
          calculatorName: 'Education Savings',
          category: 'Savings',
        );

  @override
  ConsumerState<EducationSavingsScreen> createState() => _EducationSavingsScreenState();
}

class _EducationSavingsScreenState extends CalculatorBaseState<EducationSavingsScreen> {
  final _currentCostController = TextEditingController();
  final _currentSavingsController = TextEditingController();
  double _yearsUntilCollege = 10.0;
  double _inflationRate = 6.0;
  double _expectedReturn = 10.0;
  EducationSavingsResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentCostController.dispose();
    _currentSavingsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Education Cost': NumberFormatter.formatCurrency(_currentCost, symbol: _symbol),
        'Years Until College': '${_yearsUntilCollege.toInt()} years',
        'Inflation Rate': NumberFormatter.formatPercent(_inflationRate),
        'Expected Return': NumberFormatter.formatPercent(_expectedReturn),
        'Current Savings': NumberFormatter.formatCurrency(_currentSavings, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Future Education Cost': NumberFormatter.formatCurrency(_result!.futureEducationCost, symbol: _symbol),
          'Monthly Savings Needed': NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol),
          'Total Contributions': NumberFormatter.formatCurrency(_result!.totalContributions, symbol: _symbol),
          'Total Interest': NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol),
          'Shortfall': NumberFormatter.formatCurrency(_result!.shortfall, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Education goal: ${NumberFormatter.formatCurrency(_result!.futureEducationCost, symbol: _symbol)}. '
          'Save ${NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol)}/mo '
          ' for ${_yearsUntilCollege.toInt()} years.';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _currentCost => NumberFormatter.tryParse(_currentCostController.text) ?? 0;
  double get _currentSavings => NumberFormatter.tryParse(_currentSavingsController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final cost = _currentCost;
    if (cost <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateEducationSavings(
        currentCost: cost,
        yearsUntilCollege: _yearsUntilCollege,
        inflationRate: _inflationRate,
        annualReturn: _expectedReturn,
        currentSavings: _currentSavings,
      );
    });
  }

  void _reset() {
    setState(() {
      _currentCostController.clear();
      _currentSavingsController.clear();
      _yearsUntilCollege = 10.0;
      _inflationRate = 6.0;
      _expectedReturn = 10.0;
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
            // Intro Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.savings.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.savings.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school_rounded, color: AppColors.savings, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Education costs rise with inflation. Start planning early to ensure you meet your child\'s educational goals.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Education Details'),
                  AppTextField(
                    label: 'Current Education Cost',
                    hint: '20,00,000',
                    controller: _currentCostController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Years Until College',
                    value: _yearsUntilCollege,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _yearsUntilCollege = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Education Inflation Rate',
                    value: _inflationRate,
                    min: 4,
                    max: 10,
                    divisions: 60,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _inflationRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Investment Return',
                    value: _expectedReturn,
                    min: 6,
                    max: 15,
                    divisions: 90,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _expectedReturn = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Current Savings for Education',
                    hint: '0',
                    controller: _currentSavingsController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final bool isAlreadyFunded = r.shortfall <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Education Plan Results'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isAlreadyFunded
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.savings.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAlreadyFunded
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.savings.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAlreadyFunded
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: isAlreadyFunded ? AppColors.success : AppColors.savings,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAlreadyFunded
                        ? 'Your current savings are sufficient to cover the future education cost!'
                        : 'You need to save ${NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol)} per month '
                            'to cover the education cost of ${NumberFormatter.formatCurrency(r.futureEducationCost, symbol: symbol)}.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'Future Education Cost',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.futureEducationCost,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
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
                  label: 'Monthly Savings Needed',
                  value: isAlreadyFunded
                      ? '${symbol}0'
                      : NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol),
                  valueColor: isAlreadyFunded ? AppColors.success : AppColors.savings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Shortfall',
                  value: isAlreadyFunded
                      ? 'None'
                      : NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
                  valueColor: isAlreadyFunded ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Contributions',
                  value: NumberFormatter.formatCurrency(r.totalContributions, symbol: symbol),
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Interest',
                  value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Education Plan Summary',
            items: [
              ResultItem(
                label: 'Current Cost Today',
                value: NumberFormatter.formatCurrency(_currentCost, symbol: symbol),
              ),
              ResultItem(
                label: 'Years Until College',
                value: '${_yearsUntilCollege.toInt()} years',
              ),
              ResultItem(
                label: 'Education Inflation',
                value: NumberFormatter.formatPercent(_inflationRate),
              ),
              ResultItem(
                label: 'Future Education Cost',
                value: NumberFormatter.formatCurrency(r.futureEducationCost, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Current Savings',
                value: NumberFormatter.formatCurrency(_currentSavings, symbol: symbol),
              ),
              ResultItem(
                label: 'Shortfall',
                value: isAlreadyFunded
                    ? 'None'
                    : NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
                color: isAlreadyFunded ? AppColors.success : AppColors.error,
              ),
              ResultItem(
                label: 'Monthly Savings Needed',
                value: isAlreadyFunded
                    ? '${symbol}0 (Funded)'
                    : NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

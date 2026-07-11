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

class MonthlySavingsScreen extends CalculatorBaseScreen {
  const MonthlySavingsScreen({super.key})
      : super(
          calculatorId: 'monthly_savings',
          calculatorName: 'Monthly Savings',
          category: 'Savings',
        );

  @override
  ConsumerState<MonthlySavingsScreen> createState() => _MonthlySavingsScreenState();
}

class _MonthlySavingsScreenState extends CalculatorBaseState<MonthlySavingsScreen> {
  final _monthlyAmountController = TextEditingController();
  double _annualReturn = 10.0;
  double _years = 10.0;
  MonthlySavingsResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _monthlyAmountController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Amount': NumberFormatter.formatCurrency(_monthlyAmount, symbol: _symbol),
        'Annual Return': NumberFormatter.formatPercent(_annualReturn),
        'Years': '${_years.toInt()} years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Total After ${_years.toInt()} Years': NumberFormatter.formatCurrency(_result!.totalAfterYears, symbol: _symbol),
          'Total Contributions': NumberFormatter.formatCurrency(_result!.totalContributions, symbol: _symbol),
          'Total Interest': NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol),
          'Effective Rate': NumberFormatter.formatPercent(_result!.effectiveRate),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Saving ${NumberFormatter.formatCurrency(_monthlyAmount, symbol: _symbol)}/mo for ${_years.toInt()} years = '
          '${NumberFormatter.formatCurrency(_result!.totalAfterYears, symbol: _symbol)}. '
          'Interest: ${NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol)}.';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _monthlyAmount => NumberFormatter.tryParse(_monthlyAmountController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _monthlyAmount;
    if (amount <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateMonthlySavings(
        monthlyAmount: amount,
        annualReturn: _annualReturn,
        years: _years.toInt(),
      );
    });
  }

  void _reset() {
    setState(() {
      _monthlyAmountController.clear();
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
                    label: 'Monthly Savings Amount',
                    hint: '10,000',
                    controller: _monthlyAmountController,
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
                    label: 'Annual Return',
                    value: _annualReturn,
                    min: 4,
                    max: 15,
                    divisions: 110,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualReturn = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Years',
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.savings.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.savings.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Months',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${(_years * 12).toInt()} months',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
                    ),
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Savings Projection'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.savings.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.savings.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_rounded, color: AppColors.savings, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your monthly investment of ${NumberFormatter.formatCurrency(_monthlyAmount, symbol: symbol)} '
                    'will grow significantly over ${_years.toInt()} years.',
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
                Text(
                  'Total After ${_years.toInt()} Years',
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalAfterYears,
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
            title: 'Projection Summary',
            items: [
              ResultItem(
                label: 'Monthly Investment',
                value: NumberFormatter.formatCurrency(_monthlyAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Investment Period',
                value: '${_years.toInt()} years',
              ),
              ResultItem(
                label: 'Expected Return',
                value: NumberFormatter.formatPercent(_annualReturn),
              ),
              ResultItem(
                label: 'Effective Annual Rate',
                value: NumberFormatter.formatPercent(r.effectiveRate),
              ),
              ResultItem(
                label: 'Total Contributions',
                value: NumberFormatter.formatCurrency(r.totalContributions, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Interest Earned',
                value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Total Corpus',
                value: NumberFormatter.formatCurrency(r.totalAfterYears, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

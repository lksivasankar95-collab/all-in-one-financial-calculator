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

class PpfScreen extends CalculatorBaseScreen {
  const PpfScreen({super.key})
      : super(
          calculatorId: 'ppf',
          calculatorName: 'PPF Calculator',
          category: 'Savings',
        );

  @override
  ConsumerState<PpfScreen> createState() => _PpfScreenState();
}

class _PpfScreenState extends CalculatorBaseState<PpfScreen> {
  final _yearlyController = TextEditingController();
  double _annualRate = 7.1;
  int _years = 15;
  PpfResult? _result;
  bool _showPpfLimitWarning = false;
  final _formKey = GlobalKey<FormState>();

  static const double _ppfMaxLimit = 150000;

  @override
  void dispose() {
    _yearlyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Yearly Investment': NumberFormatter.formatCurrency(_yearlyValue, symbol: _symbol),
        'Annual Rate': NumberFormatter.formatPercent(_annualRate),
        'Investment Period': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Maturity Amount': NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol),
          'Total Invested': NumberFormatter.formatCurrency(_result!.totalInvested, symbol: _symbol),
          'Tax-free Interest': NumberFormatter.formatCurrency(_result!.interestEarned, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'PPF of ${NumberFormatter.formatCurrency(_yearlyValue, symbol: _symbol)}/yr '
          'for $_years yrs @ ${_annualRate.toStringAsFixed(1)}% = '
          '${NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _yearlyValue => NumberFormatter.tryParse(_yearlyController.text) ?? 0;

  void _onYearlyChanged(String value) {
    final parsed = NumberFormatter.tryParse(value) ?? 0;
    setState(() {
      _showPpfLimitWarning = parsed > _ppfMaxLimit;
      if (_result != null) _result = null;
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final yearly = _yearlyValue;
    if (yearly <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculatePpf(
        yearlyInvestment: yearly.clamp(0, _ppfMaxLimit),
        annualRate: _annualRate,
        years: _years,
      );
    });
  }

  void _reset() {
    setState(() {
      _yearlyController.clear();
      _annualRate = 7.1;
      _years = 15;
      _result = null;
      _showPpfLimitWarning = false;
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
            // PPF Information Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.savings.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.savings.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.savings, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PPF minimum period is 15 years, extendable in blocks of 5 years',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
                  buildSectionTitle('Investment Details'),
                  AppTextField(
                    label: 'Yearly Investment',
                    hint: '1,50,000',
                    controller: _yearlyController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = NumberFormatter.tryParse(v) ?? 0;
                      if (val <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: _onYearlyChanged,
                  ),
                  if (_showPpfLimitWarning) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PPF maximum limit is ${NumberFormatter.formatCurrency(_ppfMaxLimit, symbol: symbol)} per year. Calculation capped at limit.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Interest Rate',
                    value: _annualRate,
                    min: 6,
                    max: 9,
                    divisions: 30,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Investment Period',
                    value: _years.toDouble(),
                    min: 15,
                    max: 25,
                    divisions: 10,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _years = v.toInt();
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final effectiveInvestment = _yearlyValue.clamp(0, _ppfMaxLimit).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          // Tax-free badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, color: AppColors.success, size: 14),
                SizedBox(width: 6),
                Text(
                  'Tax-Free under EEE Category',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
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
                  'Maturity Amount',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.maturityAmount,
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
                  label: 'Total Invested',
                  value: NumberFormatter.formatCurrency(r.totalInvested, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Tax-free Interest',
                  value: NumberFormatter.formatCurrency(r.interestEarned, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Yearly Investment',
                value: NumberFormatter.formatCurrency(effectiveInvestment, symbol: symbol),
              ),
              ResultItem(
                label: 'Interest Rate',
                value: '${_annualRate.toStringAsFixed(1)}% p.a.',
              ),
              ResultItem(
                label: 'Investment Period',
                value: '$_years years',
              ),
              ResultItem(
                label: 'Total Invested',
                value: NumberFormatter.formatCurrency(r.totalInvested, symbol: symbol),
              ),
              ResultItem(
                label: 'Tax-free Interest',
                value: NumberFormatter.formatCurrency(r.interestEarned, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Maturity Amount',
                value: NumberFormatter.formatCurrency(r.maturityAmount, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

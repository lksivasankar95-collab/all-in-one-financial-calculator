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

class NpsScreen extends CalculatorBaseScreen {
  const NpsScreen({super.key})
      : super(
          calculatorId: 'nps',
          calculatorName: 'NPS Calculator',
          category: 'Savings',
        );

  @override
  ConsumerState<NpsScreen> createState() => _NpsScreenState();
}

class _NpsScreenState extends CalculatorBaseState<NpsScreen> {
  final _monthlyController = TextEditingController();
  double _annualRate = 10.0;
  double _currentAge = 30.0;
  double _annuityRate = 6.0;
  double _annuityPercent = 40.0;
  NpsResult? _result;
  final _formKey = GlobalKey<FormState>();

  static const double _retirementAge = 60.0;

  @override
  void dispose() {
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  int get _yearsToRetirement => (_retirementAge - _currentAge).toInt();

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Contribution': NumberFormatter.formatCurrency(_monthlyValue, symbol: _symbol),
        'Expected Return': NumberFormatter.formatPercent(_annualRate),
        'Current Age': '${_currentAge.toInt()} years',
        'Years to Retirement': '$_yearsToRetirement years',
        'Annuity Rate': NumberFormatter.formatPercent(_annuityRate),
        'Annuity %': '${_annuityPercent.toStringAsFixed(0)}%',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Corpus at Retirement': NumberFormatter.formatCurrency(_result!.corpusAtRetirement, symbol: _symbol),
          'Lumpsum (${(100 - _annuityPercent).toStringAsFixed(0)}%)': NumberFormatter.formatCurrency(_result!.lumpsum, symbol: _symbol),
          'Monthly Pension': NumberFormatter.formatCurrency(_result!.monthlyPension, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'NPS corpus at 60: ${NumberFormatter.formatCurrency(_result!.corpusAtRetirement, symbol: _symbol)}, '
          'Monthly Pension: ${NumberFormatter.formatCurrency(_result!.monthlyPension, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _monthlyValue => NumberFormatter.tryParse(_monthlyController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_yearsToRetirement <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current age must be less than 60')),
      );
      return;
    }
    final monthly = _monthlyValue;
    if (monthly <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateNps(
        monthlyContribution: monthly,
        annualRate: _annualRate,
        years: _yearsToRetirement,
        annuityRate: _annuityRate,
        annuityPercent: _annuityPercent,
      );
    });
  }

  void _reset() {
    setState(() {
      _monthlyController.clear();
      _annualRate = 10.0;
      _currentAge = 30.0;
      _annuityRate = 6.0;
      _annuityPercent = 40.0;
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
                  buildSectionTitle('Contribution Details'),
                  AppTextField(
                    label: 'Monthly Contribution',
                    hint: '5,000',
                    controller: _monthlyController,
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
                    label: 'Expected Return Rate',
                    value: _annualRate,
                    min: 6,
                    max: 15,
                    divisions: 90,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Current Age',
                    value: _currentAge,
                    min: 18,
                    max: 55,
                    divisions: 37,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _currentAge = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.savings.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.savings.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Years to Retirement (at 60)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '$_yearsToRetirement yrs',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
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
                  buildSectionTitle('Annuity Settings'),
                  AppSliderField(
                    label: 'Annuity Rate',
                    value: _annuityRate,
                    min: 5,
                    max: 9,
                    divisions: 40,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annuityRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annuity Percentage of Corpus',
                    value: _annuityPercent,
                    min: 40,
                    max: 100,
                    divisions: 60,
                    displayValue: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() {
                      _annuityPercent = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.info.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.info, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lumpsum: ${(100 - _annuityPercent).toStringAsFixed(0)}% | Annuity: ${_annuityPercent.toStringAsFixed(0)}% (min 40% mandated by PFRDA)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
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
          buildSectionTitle('Results at Retirement (Age 60)'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Corpus at Retirement',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.corpusAtRetirement,
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
                  label: 'Lumpsum (${(100 - _annuityPercent).toStringAsFixed(0)}%)',
                  value: NumberFormatter.formatCurrency(r.lumpsum, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Monthly Pension',
                  value: NumberFormatter.formatCurrency(r.monthlyPension, symbol: symbol),
                  valueColor: AppColors.savings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Monthly Contribution',
                value: NumberFormatter.formatCurrency(_monthlyValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Contribution Period',
                value: '$_yearsToRetirement years',
              ),
              ResultItem(
                label: 'Expected Return',
                value: '${_annualRate.toStringAsFixed(1)}% p.a.',
              ),
              ResultItem(
                label: 'Corpus at 60',
                value: NumberFormatter.formatCurrency(r.corpusAtRetirement, symbol: symbol),
              ),
              ResultItem(
                label: 'Lumpsum (${(100 - _annuityPercent).toStringAsFixed(0)}%)',
                value: NumberFormatter.formatCurrency(r.lumpsum, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Monthly Pension',
                value: NumberFormatter.formatCurrency(r.monthlyPension, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
import '../../domain/retirement_calculators.dart';

class PensionCalculatorScreen extends CalculatorBaseScreen {
  const PensionCalculatorScreen({super.key})
      : super(
          calculatorId: 'pension_calculator',
          calculatorName: 'Pension Calculator',
          category: 'Retirement',
        );

  @override
  ConsumerState<PensionCalculatorScreen> createState() => _PensionCalculatorScreenState();
}

class _PensionCalculatorScreenState extends CalculatorBaseState<PensionCalculatorScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentAge = 30;
  int _retirementAge = 60;
  double _expectedReturn = 10.0;
  double _annuityRate = 6.0;
  PensionResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _monthlyContribution => NumberFormatter.tryParse(_controller.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Age': '$_currentAge',
        'Retirement Age': '$_retirementAge',
        'Monthly Contribution': NumberFormatter.formatCurrency(_monthlyContribution, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Corpus at Retirement': NumberFormatter.formatCurrency(_result!.corpusAtRetirement, symbol: _symbol),
        'Monthly Pension': NumberFormatter.formatCurrency(_result!.monthlyPension, symbol: _symbol),
        'Total Contributions': NumberFormatter.formatCurrency(_result!.totalContributions, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Pension: ${NumberFormatter.formatCurrency(_result!.monthlyPension, symbol: _symbol)}/mo | '
          'Corpus: ${NumberFormatter.formatCurrency(_result!.corpusAtRetirement, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_monthlyContribution <= 0) return;

    setState(() {
      _result = RetirementCalculators.calculatePension(
        currentAge: _currentAge,
        retirementAge: _retirementAge,
        monthlyContribution: _monthlyContribution,
        expectedReturn: _expectedReturn,
        annuityRate: _annuityRate,
      );
    });
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _currentAge = 30;
      _retirementAge = 60;
      _expectedReturn = 10.0;
      _annuityRate = 6.0;
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
                  buildSectionTitle('Pension Plan Details'),
                  Row(
                    children: [
                      Expanded(
                        child: AppSliderField(
                          label: 'Current Age',
                          value: _currentAge.toDouble(),
                          min: 18, max: 70, divisions: 52,
                          displayValue: (v) => '${v.toInt()} yrs',
                          onChanged: (v) => setState(() { _currentAge = v.toInt(); _result = null; }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppSliderField(
                          label: 'Retirement Age',
                          value: _retirementAge.toDouble(),
                          min: 30, max: 70, divisions: 40,
                          displayValue: (v) => '${v.toInt()} yrs',
                          onChanged: (v) => setState(() { _retirementAge = v.toInt(); _result = null; }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Monthly Contribution',
                    hint: '5000',
                    controller: _controller,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 1000) return 'Minimum ₹1,000';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Return',
                    value: _expectedReturn,
                    min: 1, max: 15, divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _expectedReturn = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annuity Rate at Retirement',
                    value: _annuityRate,
                    min: 1, max: 10, divisions: 90,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _annuityRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate', icon: Icons.calculate_rounded,
                          onPressed: _calculate, width: double.infinity,
                          color: AppColors.retirement,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.retirement),
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
          buildSectionTitle('Pension Estimate'),
          Center(
            child: Column(
              children: [
                const Text('Monthly Pension', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.monthlyPension,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.retirement),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Corpus at Retirement',
                    value: NumberFormatter.formatCurrency(r.corpusAtRetirement, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Contributions',
                    value: NumberFormatter.formatCurrency(r.totalContributions, symbol: symbol)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Total Interest Earned',
            value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
            isHighlighted: true,
            valueColor: AppColors.retirement,
            subtitle: 'Over ${_retirementAge - _currentAge} years of contributions',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Pension Summary',
            items: [
              ResultItem(label: 'Monthly Contribution', value: NumberFormatter.formatCurrency(_monthlyContribution, symbol: symbol)),
              ResultItem(label: 'Total Contributions', value: NumberFormatter.formatCurrency(r.totalContributions, symbol: symbol)),
              ResultItem(label: 'Total Interest', value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol), color: AppColors.retirement),
              ResultItem(label: 'Corpus at Retirement', value: NumberFormatter.formatCurrency(r.corpusAtRetirement, symbol: symbol), isHighlighted: true),
              ResultItem(label: 'Monthly Pension', value: NumberFormatter.formatCurrency(r.monthlyPension, symbol: symbol), isHighlighted: true, color: AppColors.retirement),
            ],
          ),
        ],
      ),
    );
  }
}

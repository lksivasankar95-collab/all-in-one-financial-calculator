import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../domain/investment_calculators.dart';

class RuleOf114Screen extends CalculatorBaseScreen {
  const RuleOf114Screen({super.key})
      : super(
          calculatorId: 'rule_of_114',
          calculatorName: 'Rule of 114',
          category: 'Investment',
        );

  @override
  ConsumerState<RuleOf114Screen> createState() => _RuleOf114ScreenState();
}

class _RuleOf114ScreenState extends CalculatorBaseState<RuleOf114Screen> {
  double _annualRate = 10.0;
  RuleOf114Result? _result;
  RuleOf72Result? _rule72Result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Annual Rate': NumberFormatter.formatPercent(_annualRate),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Rule of 114 Estimate':
              '${_result!.yearsToTriple.toStringAsFixed(2)} years',
          'Actual Years': '${_result!.actualYears.toStringAsFixed(2)} years',
          'Rule of 72 Estimate':
              '${_rule72Result!.yearsToDouble.toStringAsFixed(2)} years',
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Rule of 114: ${_result!.yearsToTriple.toStringAsFixed(2)} yrs to triple @ ${_annualRate.toStringAsFixed(1)}% | '
          'Rule of 72: ${_rule72Result!.yearsToDouble.toStringAsFixed(2)} yrs to double';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      final results = InvestmentCalculators.calculateRulesComparison(
        annualRate: _annualRate,
      );
      _rule72Result = results.$1;
      _result = results.$2;
    });
  }

  void _reset() {
    setState(() {
      _annualRate = 10.0;
      _result = null;
      _rule72Result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  buildSectionTitle('Rate of Return'),
                  const Text(
                    'The Rule of 114 estimates how long an investment takes to triple at a fixed annual rate.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Rate of Return',
                    value: _annualRate,
                    min: 1,
                    max: 50,
                    divisions: 490,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _annualRate = v;
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
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final r = _result!;
    final r72 = _rule72Result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Years to Triple',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.yearsToTriple,
                  formatter: (v) => '${v.toStringAsFixed(2)} yrs',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
                  label: 'Rule of 114 Estimate',
                  value: '${r.yearsToTriple.toStringAsFixed(2)} years',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Actual Years',
                  value: '${r.actualYears.toStringAsFixed(2)} years',
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Difference',
            value:
                '${(r.actualYears - r.yearsToTriple).abs().toStringAsFixed(2)} years',
            isHighlighted: true,
            subtitle:
                'At ${_annualRate.toStringAsFixed(1)}% annual return',
          ),
          const SizedBox(height: 16),
          const Text(
            'Comparison: Rule of 72 vs Rule of 114',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Double',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r72.yearsToDouble.toStringAsFixed(1)} yrs',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '72 / ${_annualRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Triple',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.yearsToTriple.toStringAsFixed(1)} yrs',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '114 / ${_annualRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Comparison Summary',
            items: [
              ResultItem(
                label: 'Annual Rate',
                value: NumberFormatter.formatPercent(_annualRate),
              ),
              ResultItem(
                label: 'Rule of 72 (Double)',
                value: '${r72.yearsToDouble.toStringAsFixed(2)} years',
              ),
              ResultItem(
                label: 'Actual Double',
                value: '${r72.actualYears.toStringAsFixed(2)} years',
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Rule of 114 (Triple)',
                value: '${r.yearsToTriple.toStringAsFixed(2)} years',
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Actual Triple',
                value: '${r.actualYears.toStringAsFixed(2)} years',
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

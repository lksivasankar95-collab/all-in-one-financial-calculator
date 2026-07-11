import 'dart:math';

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
import '../../domain/investment_calculators.dart';

class RuleOf72Screen extends CalculatorBaseScreen {
  const RuleOf72Screen({super.key})
      : super(
          calculatorId: 'rule_of_72',
          calculatorName: 'Rule of 72',
          category: 'Investment',
        );

  @override
  ConsumerState<RuleOf72Screen> createState() => _RuleOf72ScreenState();
}

class _RuleOf72ScreenState extends CalculatorBaseState<RuleOf72Screen> {
  double _annualRate = 10.0;
  RuleOf72Result? _result;
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
          'Rule of 72 Estimate': '${_result!.yearsToDouble.toStringAsFixed(2)} years',
          'Actual Years': '${_result!.actualYears.toStringAsFixed(2)} years',
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Rule of 72: ${_result!.yearsToDouble.toStringAsFixed(2)} yrs to double @ ${_annualRate.toStringAsFixed(1)}% | '
          'Actual: ${_result!.actualYears.toStringAsFixed(2)} yrs';

  String get _symbol => ref.read(currencySymbolProvider);

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculateRuleOf72(
        annualRate: _annualRate,
      );
    });
  }

  void _reset() {
    setState(() {
      _annualRate = 10.0;
      _result = null;
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
                    'The Rule of 72 estimates how long an investment takes to double at a fixed annual rate.',
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Years to Double',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.yearsToDouble,
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
                  label: 'Rule of 72 Estimate',
                  value: '${r.yearsToDouble.toStringAsFixed(2)} years',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Actual Calculation',
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
                '${(r.actualYears - r.yearsToDouble).abs().toStringAsFixed(2)} years',
            isHighlighted: true,
            subtitle:
                'At ${_annualRate.toStringAsFixed(1)}% annual return',
          ),
          const SizedBox(height: 12),
          _buildVerificationTable(r),
        ],
      ),
    );
  }

  Widget _buildVerificationTable(RuleOf72Result r) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compounding Verification',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(2),
            },
            children: [
              _buildTableRow('Year', 'Rate', 'Value ($_symbol 1)',
                  isHeader: true),
              for (int y = 1; y <= (r.actualYears.ceil()).clamp(1, 30); y++)
                _buildTableRow(
                  '$y',
                  '${_annualRate.toStringAsFixed(1)}%',
                  '$_symbol${(100 * pow(1 + _annualRate / 100, y)).toStringAsFixed(2)}',
                  isHighlighted: y.toDouble() >= r.yearsToDouble,
                ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    String year,
    String rate,
    String value, {
    bool isHeader = false,
    bool isHighlighted = false,
  }) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
      color: isHeader
          ? AppColors.primary
          : (isHighlighted ? AppColors.primary : AppColors.textSecondary),
    );
    return TableRow(
      decoration: isHighlighted
          ? BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
            )
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(year, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(rate, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value, style: style),
        ),
      ],
    );
  }
}

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

class CompoundGrowthScreen extends CalculatorBaseScreen {
  const CompoundGrowthScreen({super.key})
      : super(
          calculatorId: 'compound_growth',
          calculatorName: 'Compound Growth',
          category: 'Utility',
        );

  @override
  ConsumerState<CompoundGrowthScreen> createState() =>
      _CompoundGrowthScreenState();
}

class _CompoundGrowthScreenState
    extends CalculatorBaseState<CompoundGrowthScreen> {
  final _initialValueController = TextEditingController();
  final _finalValueController = TextEditingController();
  double _years = 10.0;
  final _formKey = GlobalKey<FormState>();

  CompoundGrowthResult? _result;

  @override
  void dispose() {
    _initialValueController.dispose();
    _finalValueController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _initialValue =>
      NumberFormatter.tryParse(_initialValueController.text) ?? 0;
  double get _finalValue =>
      NumberFormatter.tryParse(_finalValueController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Initial Value': _initialValueController.text,
        'Final Value': _finalValueController.text,
        'Period': '${_years.toInt()} years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'CAGR': NumberFormatter.formatPercent(_result!.cagr),
          'Total Growth %':
              NumberFormatter.formatPercent(_result!.totalGrowthPercent),
          'Growth Factor':
              _result!.growthFactor.toStringAsFixed(4),
          'Interpretation': _result!.interpretation,
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'CAGR: ${NumberFormatter.formatPercent(_result!.cagr)} over ${_years.toInt()} years | '
          'Total: ${NumberFormatter.formatPercent(_result!.totalGrowthPercent)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final initial = _initialValue;
    final finalVal = _finalValue;
    if (initial <= 0 || finalVal <= 0) return;

    final double growthFactor = finalVal / initial;
    final double totalGrowthPercent = (growthFactor - 1) * 100;
    final double cagr = (pow(growthFactor, 1 / _years) - 1) * 100;

    String interpretation;
    if (cagr < 0) {
      interpretation = 'The investment has declined in value over the period.';
    } else if (cagr < 5) {
      interpretation = 'Low growth rate. Consider reviewing your investment strategy.';
    } else if (cagr < 10) {
      interpretation = 'Moderate growth. Your investment is performing reasonably well.';
    } else if (cagr < 15) {
      interpretation = 'Good growth. Your investment is performing well above average.';
    } else if (cagr < 25) {
      interpretation = 'Excellent growth! Your investment is performing exceptionally well.';
    } else {
      interpretation = 'Outstanding growth! Your investment has delivered remarkable returns.';
    }

    setState(() {
      _result = CompoundGrowthResult(
        cagr: cagr,
        totalGrowthPercent: totalGrowthPercent,
        growthFactor: growthFactor,
        interpretation: interpretation,
      );
    });
  }

  void _reset() {
    setState(() {
      _initialValueController.clear();
      _finalValueController.clear();
      _years = 10.0;
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
                  buildSectionTitle('Growth Details'),
                  AppTextField(
                    label: 'Initial Value',
                    hint: '1,00,000',
                    controller: _initialValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a positive value';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Final Value',
                    hint: '5,00,000',
                    controller: _finalValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a positive value';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Number of Years',
                    value: _years,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _years = v;
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
                          color: AppColors.utility,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.utility,
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
    final isPositive = r.cagr >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Growth Analysis'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.utility.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.utility.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Compound Annual Growth Rate (CAGR)',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.cagr,
                  formatter: (v) => NumberFormatter.formatPercent(v),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? AppColors.utility : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Growth %',
                  value: NumberFormatter.formatPercent(r.totalGrowthPercent),
                  valueColor:
                      isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Growth Factor',
                  value: r.growthFactor.toStringAsFixed(4),
                  valueColor: AppColors.utility,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.utility : AppColors.error)
                  .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isPositive ? AppColors.utility : AppColors.error)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: isPositive ? AppColors.utility : AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.interpretation,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Growth Summary',
            items: [
              ResultItem(
                label: 'Initial Value',
                value: NumberFormatter.formatNumber(_initialValue),
              ),
              ResultItem(
                label: 'Final Value',
                value: NumberFormatter.formatNumber(_finalValue),
              ),
              ResultItem(
                label: 'Period',
                value: '${_years.toInt()} years',
              ),
              ResultItem(
                label: 'Growth Factor (FV/IV)',
                value: r.growthFactor.toStringAsFixed(4),
              ),
              ResultItem(
                label: 'Total Growth',
                value: NumberFormatter.formatPercent(r.totalGrowthPercent),
                isHighlighted: true,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              ResultItem(
                label: 'CAGR',
                value: NumberFormatter.formatPercent(r.cagr),
                isHighlighted: true,
                color: isPositive ? AppColors.utility : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompoundGrowthResult {
  final double cagr;
  final double totalGrowthPercent;
  final double growthFactor;
  final String interpretation;

  const CompoundGrowthResult({
    required this.cagr,
    required this.totalGrowthPercent,
    required this.growthFactor,
    required this.interpretation,
  });
}

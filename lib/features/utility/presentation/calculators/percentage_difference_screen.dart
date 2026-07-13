import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';

class PercentageDifferenceScreen extends CalculatorBaseScreen {
  const PercentageDifferenceScreen({super.key})
      : super(
          calculatorId: 'percentage_difference',
          calculatorName: 'Percentage Difference',
          category: 'Utility',
        );

  @override
  ConsumerState<PercentageDifferenceScreen> createState() =>
      _PercentageDifferenceScreenState();
}

class _PercentageDifferenceScreenState
    extends CalculatorBaseState<PercentageDifferenceScreen> {
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PercentageDiffResult? _result;

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _value1 =>
      NumberFormatter.tryParse(_value1Controller.text) ?? 0;
  double get _value2 =>
      NumberFormatter.tryParse(_value2Controller.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Value 1': _value1Controller.text,
        'Value 2': _value2Controller.text,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Difference':
              NumberFormatter.formatNumber(_result!.difference.abs()),
          'Average': NumberFormatter.formatNumber(_result!.average),
          'Percentage Difference':
              NumberFormatter.formatPercent(_result!.percentDifference),
          'Interpretation': _result!.interpretation,
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '|${_value1Controller.text} - ${_value2Controller.text}| / avg = '
          '${NumberFormatter.formatPercent(_result!.percentDifference)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final double diff = _value1 - _value2;
    final double avg = (_value1 + _value2) / 2;
    final double percentDiff = avg != 0 ? (diff.abs() / avg) * 100 : 0;

    String interpretation;
    if (percentDiff < 1) {
      interpretation = 'Values are nearly identical';
    } else if (percentDiff < 10) {
      interpretation = 'Values are slightly different';
    } else if (percentDiff < 25) {
      interpretation = 'Values are moderately different';
    } else if (percentDiff < 50) {
      interpretation = 'Values are significantly different';
    } else {
      interpretation = 'Values are vastly different';
    }

    setState(() {
      _result = PercentageDiffResult(
        difference: diff,
        average: avg,
        percentDifference: percentDiff,
        interpretation: interpretation,
      );
    });
  }

  void _reset() {
    setState(() {
      _value1Controller.clear();
      _value2Controller.clear();
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
                  buildSectionTitle('Values'),
                  AppTextField(
                    label: 'Value 1',
                    hint: '200',
                    controller: _value1Controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v.replaceAll(',', '')) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Value 2',
                    hint: '150',
                    controller: _value2Controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v.replaceAll(',', '')) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Percentage Difference Result'),
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
                  'Percentage Difference',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.percentDifference,
                  formatter: (v) => NumberFormatter.formatPercent(v),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.utility,
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
                  label: 'Difference',
                  value: NumberFormatter.formatNumber(r.difference.abs()),
                  valueColor: AppColors.utility,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Average',
                  value: NumberFormatter.formatNumber(r.average),
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
              color: AppColors.utility.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.utility.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.utility, size: 18),
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
            title: 'Calculation Details',
            items: [
              ResultItem(
                label: 'Value 1',
                value: NumberFormatter.formatNumber(_value1),
              ),
              ResultItem(
                label: 'Value 2',
                value: NumberFormatter.formatNumber(_value2),
              ),
              ResultItem(
                label: '|Difference|',
                value: NumberFormatter.formatNumber(r.difference.abs()),
              ),
              ResultItem(
                label: 'Average ( (V1+V2)/2 )',
                value: NumberFormatter.formatNumber(r.average),
              ),
              const ResultItem(
                label: 'Formula',
                value: '|V1-V2| / ((V1+V2)/2) × 100',
              ),
              ResultItem(
                label: 'Percentage Difference',
                value: NumberFormatter.formatPercent(r.percentDifference),
                isHighlighted: true,
                color: AppColors.utility,
              ),
              ResultItem(
                label: 'Interpretation',
                value: r.interpretation,
                color: AppColors.utility,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PercentageDiffResult {
  final double difference;
  final double average;
  final double percentDifference;
  final String interpretation;

  const PercentageDiffResult({
    required this.difference,
    required this.average,
    required this.percentDifference,
    required this.interpretation,
  });
}

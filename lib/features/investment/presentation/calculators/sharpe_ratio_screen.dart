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

class SharpeRatioScreen extends CalculatorBaseScreen {
  const SharpeRatioScreen({super.key})
      : super(
          calculatorId: 'sharpe_ratio',
          calculatorName: 'Sharpe Ratio',
          category: 'Investment',
        );

  @override
  ConsumerState<SharpeRatioScreen> createState() => _SharpeRatioScreenState();
}

class _SharpeRatioScreenState extends CalculatorBaseState<SharpeRatioScreen> {
  final _portfolioReturnController = TextEditingController();
  double _riskFreeRate = 6.0;
  double _stdDeviation = 15.0;
  double? _sharpeRatio;
  String? _interpretation;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _portfolioReturnController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _sharpeRatio != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Portfolio Return':
            NumberFormatter.formatPercent(_portfolioReturnValue),
        'Risk-Free Rate': NumberFormatter.formatPercent(_riskFreeRate),
        'Standard Deviation': NumberFormatter.formatPercent(_stdDeviation),
      };

  @override
  Map<String, dynamic> get currentResults => _sharpeRatio == null
      ? {}
      : {
          'Sharpe Ratio': _sharpeRatio!.toStringAsFixed(2),
          'Interpretation': _interpretation ?? '',
        };

  @override
  String get resultSummary => _sharpeRatio == null
      ? ''
      : 'Sharpe Ratio: ${_sharpeRatio!.toStringAsFixed(2)} - $_interpretation';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _portfolioReturnValue =>
      NumberFormatter.tryParse(_portfolioReturnController.text) ?? 0;

  String _getInterpretation(double sharpe) {
    if (sharpe >= 3) return 'Excellent';
    if (sharpe >= 2) return 'Very Good';
    if (sharpe >= 1) return 'Good';
    if (sharpe >= 0.5) return 'Fair';
    if (sharpe >= 0) return 'Poor';
    return 'Negative';
  }

  Color _getInterpretationColor(double sharpe) {
    if (sharpe >= 3) return const Color(0xFF00E676);
    if (sharpe >= 2) return AppColors.success;
    if (sharpe >= 1) return AppColors.primary;
    if (sharpe >= 0.5) return Colors.orange;
    if (sharpe >= 0) return AppColors.error;
    return const Color(0xFFD50000);
  }

  String _getRiskAssessment(double sharpe) {
    if (sharpe >= 2) return 'Excellent risk-adjusted returns';
    if (sharpe >= 1) return 'Good risk-adjusted returns';
    if (sharpe >= 0) return 'Below average risk-adjusted returns';
    return 'Negative risk-adjusted returns - consider alternative investments';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final portfolioReturn = _portfolioReturnValue;
    if (portfolioReturn <= 0) return;
    if (_stdDeviation <= 0) return;

    final sharpe = (portfolioReturn - _riskFreeRate) / _stdDeviation;

    setState(() {
      _sharpeRatio = sharpe;
      _interpretation = _getInterpretation(sharpe);
    });
  }

  void _reset() {
    setState(() {
      _portfolioReturnController.clear();
      _riskFreeRate = 6.0;
      _stdDeviation = 15.0;
      _sharpeRatio = null;
      _interpretation = null;
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
                  buildSectionTitle('Portfolio Details'),
                  AppTextField(
                    label: 'Portfolio Return (%)',
                    hint: '15',
                    controller: _portfolioReturnController,
                    suffix: '%',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid return';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_sharpeRatio != null) {
                        setState(() => _sharpeRatio = null);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Risk-Free Rate',
                    value: _riskFreeRate,
                    min: 0,
                    max: 15,
                    divisions: 150,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _riskFreeRate = v;
                        if (_sharpeRatio != null) _sharpeRatio = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Standard Deviation',
                    value: _stdDeviation,
                    min: 1,
                    max: 40,
                    divisions: 390,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _stdDeviation = v;
                        if (_sharpeRatio != null) _sharpeRatio = null;
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
            if (_sharpeRatio != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final sharpe = _sharpeRatio!;
    final interpretation = _interpretation!;
    final interpretationColor = _getInterpretationColor(sharpe);
    final riskAssessment = _getRiskAssessment(sharpe);

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Sharpe Ratio'),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Sharpe Ratio',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 6),
                    AnimatedResultValue(
                      value: sharpe,
                      formatter: (v) => v.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: interpretationColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: interpretationColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: interpretationColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        interpretation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: interpretationColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResultCard(
                label: 'Risk Assessment',
                value: riskAssessment,
                isHighlighted: true,
                valueColor: interpretationColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultSummaryCard(
          title: 'Calculation Details',
          items: [
            ResultItem(
              label: 'Portfolio Return',
              value:
                  NumberFormatter.formatPercent(_portfolioReturnValue),
            ),
            ResultItem(
              label: 'Risk-Free Rate',
              value: NumberFormatter.formatPercent(_riskFreeRate),
            ),
            ResultItem(
              label: 'Excess Return',
              value: NumberFormatter.formatPercent(
                  _portfolioReturnValue - _riskFreeRate),
              color: AppColors.success,
            ),
            ResultItem(
              label: 'Standard Deviation',
              value: NumberFormatter.formatPercent(_stdDeviation),
            ),
            ResultItem(
              label: 'Sharpe Ratio',
              value: sharpe.toStringAsFixed(2),
              isHighlighted: true,
              color: interpretationColor,
            ),
            ResultItem(
              label: 'Interpretation',
              value: interpretation,
              color: interpretationColor,
            ),
          ],
        ),
      ],
    );
  }
}

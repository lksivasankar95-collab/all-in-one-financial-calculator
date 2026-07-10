import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../domain/utility_calculators.dart';

class PercentageScreen extends CalculatorBaseScreen {
  const PercentageScreen({super.key})
      : super(
          calculatorId: 'percentage',
          calculatorName: 'Percentage Calculator',
          category: 'Utility',
        );

  @override
  ConsumerState<PercentageScreen> createState() => _PercentageScreenState();
}

class _PercentageScreenState extends CalculatorBaseState<PercentageScreen> {
  final _valueAController = TextEditingController();
  final _valueBController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PercentageMode _mode = PercentageMode.percentOf;
  PercentageResult? _result;

  static const _modes = [
    (PercentageMode.percentOf, 'X% of Y', 'Find value'),
    (PercentageMode.whatPercent, 'X is what % of Y', 'Find percent'),
    (PercentageMode.percentChange, '% Change', 'X → Y'),
    (PercentageMode.addPercent, 'Add X% to Y', 'Increase'),
    (PercentageMode.subtractPercent, 'Subtract X% from Y', 'Decrease'),
  ];

  @override
  void dispose() {
    _valueAController.dispose();
    _valueBController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _valueA => NumberFormatter.tryParse(_valueAController.text) ?? 0;
  double get _valueB => NumberFormatter.tryParse(_valueBController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Mode': _modeName,
        'Value A': _valueAController.text,
        'Value B': _valueBController.text,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Result': _fmtResult(_result!.result),
          'Explanation': _result!.explanation,
        };

  @override
  String get resultSummary =>
      _result == null ? '' : _result!.explanation;

  String get _modeName =>
      _modes.firstWhere((m) => m.$1 == _mode).$2;

  (String, String) get _labels {
    switch (_mode) {
      case PercentageMode.percentOf:
        return ('Percent (%)', 'Of Value (Y)');
      case PercentageMode.whatPercent:
        return ('X (Value)', 'Of Y (Total)');
      case PercentageMode.percentChange:
        return ('From (X)', 'To (Y)');
      case PercentageMode.addPercent:
        return ('Base Value (Y)', 'Add % (X)');
      case PercentageMode.subtractPercent:
        return ('Base Value (Y)', 'Subtract % (X)');
    }
  }

  String _fmtResult(double v) {
    if (_mode == PercentageMode.percentChange ||
        _mode == PercentageMode.whatPercent) {
      return '${v.toStringAsFixed(4)}%';
    }
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(4);
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    double value = _valueA;
    double percent = _valueB;

    // Remap values for each mode
    switch (_mode) {
      case PercentageMode.percentOf:
        // percent% of value
        value = _valueB;
        percent = _valueA;
        break;
      case PercentageMode.whatPercent:
        value = _valueA;
        percent = _valueB;
        break;
      case PercentageMode.percentChange:
        value = _valueA;
        percent = _valueB;
        break;
      case PercentageMode.addPercent:
        value = _valueA;
        percent = _valueB;
        break;
      case PercentageMode.subtractPercent:
        value = _valueA;
        percent = _valueB;
        break;
    }

    setState(() {
      _result = UtilityCalculators.calculatePercentage(
        value: value,
        percent: percent,
        mode: _mode,
      );
    });
  }

  void _reset() {
    setState(() {
      _valueAController.clear();
      _valueBController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    return buildCalculatorScaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mode selector
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Calculation Mode'),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _modes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final mode = _modes[i];
                        final selected = _mode == mode.$1;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _mode = mode.$1;
                            _result = null;
                            _valueAController.clear();
                            _valueBController.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.utility.withOpacity(0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.utility
                                    : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  mode.$2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppColors.utility
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                  buildSectionTitle(_modeName),
                  AppTextField(
                    label: labels.$1,
                    hint: '25',
                    controller: _valueAController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: labels.$2,
                    hint: '200',
                    controller: _valueBController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
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
          buildSectionTitle('Result'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.utility.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.utility.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                AnimatedResultValue(
                  value: r.result,
                  formatter: (v) => _fmtResult(v),
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.utility),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.explanation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

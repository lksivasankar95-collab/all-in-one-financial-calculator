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

enum PercentChangeMode { calculateChange, calculateNewValue, calculateOriginal }

class PercentChangeScreen extends CalculatorBaseScreen {
  const PercentChangeScreen({super.key})
      : super(
          calculatorId: 'percent_change',
          calculatorName: 'Percent Change',
          category: 'Utility',
        );

  @override
  ConsumerState<PercentChangeScreen> createState() => _PercentChangeScreenState();
}

class _PercentChangeScreenState extends CalculatorBaseState<PercentChangeScreen> {
  final _valueAController = TextEditingController();
  final _valueBController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PercentChangeResult? _result;
  PercentChangeMode _mode = PercentChangeMode.calculateChange;

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
        'Mode': _modeLabel,
        _labelA: _valueAController.text,
        _labelB: _valueBController.text,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Change': NumberFormatter.formatNumber(_result!.change),
          '% Change': NumberFormatter.formatPercent(_result!.percentChange),
          'Direction': _result!.changeType,
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '${_result!.changeType.toUpperCase()}: ${NumberFormatter.formatPercent(_result!.percentChange)}';

  String get _modeLabel {
    switch (_mode) {
      case PercentChangeMode.calculateChange:
        return 'Calculate Change';
      case PercentChangeMode.calculateNewValue:
        return 'Calculate New Value';
      case PercentChangeMode.calculateOriginal:
        return 'Calculate Original';
    }
  }

  String get _labelA {
    switch (_mode) {
      case PercentChangeMode.calculateChange:
        return 'Old Value';
      case PercentChangeMode.calculateNewValue:
        return 'Old Value';
      case PercentChangeMode.calculateOriginal:
        return 'New Value';
    }
  }

  String get _labelB {
    switch (_mode) {
      case PercentChangeMode.calculateChange:
        return 'New Value';
      case PercentChangeMode.calculateNewValue:
        return 'Change %';
      case PercentChangeMode.calculateOriginal:
        return 'Change %';
    }
  }

  String get _hintB {
    switch (_mode) {
      case PercentChangeMode.calculateChange:
        return '200';
      case PercentChangeMode.calculateNewValue:
        return '10';
      case PercentChangeMode.calculateOriginal:
        return '-10';
    }
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      switch (_mode) {
        case PercentChangeMode.calculateChange:
          _result = UtilityCalculators.calculatePercentChange(
            oldValue: _valueA,
            newValue: _valueB,
          );
        case PercentChangeMode.calculateNewValue:
          _result = UtilityCalculators.calculateNewValue(
            oldValue: _valueA,
            percentChange: _valueB,
          );
        case PercentChangeMode.calculateOriginal:
          _result = UtilityCalculators.calculateOriginalValue(
            newValue: _valueA,
            percentChange: _valueB,
          );
      }
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
                  buildSectionTitle('Mode'),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<PercentChangeMode>(
                      segments: const [
                        ButtonSegment(
                          value: PercentChangeMode.calculateChange,
                          label: Text('Change', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.swap_horiz_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: PercentChangeMode.calculateNewValue,
                          label: Text('New Value', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.arrow_forward_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: PercentChangeMode.calculateOriginal,
                          label: Text('Original', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.arrow_back_rounded, size: 16),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _mode = selected.first;
                          _result = null;
                          _valueAController.clear();
                          _valueBController.clear();
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.utility.withValues(alpha: 0.15);
                          }
                          return AppColors.surface;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.utility;
                          }
                          return AppColors.textSecondary;
                        }),
                        side: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const BorderSide(color: AppColors.utility);
                          }
                          return const BorderSide(color: AppColors.border);
                        }),
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
                  buildSectionTitle(_modeLabel),
                  AppTextField(
                    label: _labelA,
                    hint: '100',
                    controller: _valueAController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null) return 'Enter a valid number';
                      if (_mode == PercentChangeMode.calculateOriginal && val == 0) {
                        return 'Value cannot be zero';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: _labelB,
                    hint: _hintB,
                    controller: _valueBController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null) return 'Enter a valid number';
                      if (_mode == PercentChangeMode.calculateOriginal && val == -100) {
                        return 'Cannot divide by zero';
                      }
                      return null;
                    },
                    suffix: _mode != PercentChangeMode.calculateChange ? '%' : null,
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
    final isIncrease = r.changeType == 'increase';
    final isDecrease = r.changeType == 'decrease';
    final arrowIcon = isIncrease
        ? Icons.arrow_upward_rounded
        : isDecrease
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;
    final arrowColor = isIncrease
        ? AppColors.success
        : isDecrease
            ? AppColors.error
            : AppColors.textHint;

    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              buildSectionTitle('Result'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(arrowIcon, color: arrowColor, size: 32),
                  const SizedBox(width: 8),
                  AnimatedResultValue(
                    value: r.percentChange,
                    formatter: (v) => NumberFormatter.formatPercent(v),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: arrowColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                r.changeType == 'no change' ? 'No Change' : isIncrease ? 'Increase' : 'Decrease',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: arrowColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Change Amount',
                      value: NumberFormatter.formatNumber(r.change.abs()),
                      valueColor: arrowColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResultSummaryCard(
          title: 'Calculation Details',
          onCopy: copyResult,
          items: [
            ResultItem(
              label: 'Old Value',
              value: NumberFormatter.formatNumber(r.oldValue),
            ),
            ResultItem(
              label: 'New Value',
              value: NumberFormatter.formatNumber(r.newValue),
            ),
            ResultItem(
              label: 'Change Amount',
              value: NumberFormatter.formatNumber(r.change),
              color: arrowColor,
            ),
            ResultItem(
              label: 'Change %',
              value: NumberFormatter.formatPercent(r.percentChange),
              isHighlighted: true,
              color: arrowColor,
            ),
          ],
        ),
      ],
    );
  }
}

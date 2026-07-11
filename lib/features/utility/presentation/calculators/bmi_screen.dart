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

class BmiScreen extends CalculatorBaseScreen {
  const BmiScreen({super.key})
      : super(
          calculatorId: 'bmi',
          calculatorName: 'BMI Calculator',
          category: 'Utility',
        );

  @override
  ConsumerState<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends CalculatorBaseState<BmiScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  BmiResult? _result;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Weight (kg)': _weightController.text,
        'Height (cm)': _heightController.text,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'BMI': _result!.bmi.toStringAsFixed(1),
          'Category': _result!.category,
          'Healthy Weight Range':
              '${_result!.healthyWeightMin.toStringAsFixed(1)} - ${_result!.healthyWeightMax.toStringAsFixed(1)} kg',
        };

  @override
  String get resultSummary =>
      _result == null ? '' : 'BMI: ${_result!.bmi.toStringAsFixed(1)} (${_result!.category})';

  double get _weight => NumberFormatter.tryParse(_weightController.text) ?? 0;
  double get _height => NumberFormatter.tryParse(_heightController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = UtilityCalculators.calculateBmi(
        weightKg: _weight,
        heightCm: _height,
      );
    });
  }

  void _reset() {
    setState(() {
      _weightController.clear();
      _heightController.clear();
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
                  buildSectionTitle('Input'),
                  AppTextField(
                    label: 'Weight (kg)',
                    hint: '70',
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Enter a valid weight';
                      if (val > 500) return 'Weight seems too high';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                    suffix: 'kg',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Height (cm)',
                    hint: '175',
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Enter a valid height';
                      if (val > 300) return 'Height seems too high';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                    suffix: 'cm',
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
    final bmiProgress = (r.bmi / 40).clamp(0.0, 1.0);

    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              buildSectionTitle('Your BMI'),
              const SizedBox(height: 8),
              AnimatedResultValue(
                value: r.bmi,
                formatter: (v) => v.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: r.categoryColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: r.categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: r.categoryColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  r.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: r.categoryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF40C4FF),
                                  Color(0xFF39FF14),
                                  Color(0xFFFFC107),
                                  Color(0xFFFF5252),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: bmiProgress * constraints.maxWidth - 6,
                            top: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: r.categoryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: r.categoryColor.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Underweight', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
                  Text('Normal', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
                  Text('Overweight', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
                  Text('Obese', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Details'),
              const SizedBox(height: 8),
              ResultCard(
                label: 'Healthy Weight Range',
                value:
                    '${r.healthyWeightMin.toStringAsFixed(1)} - ${r.healthyWeightMax.toStringAsFixed(1)} kg',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: r.categoryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.risk,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResultSummaryCard(
          title: 'Summary',
          onCopy: copyResult,
          items: [
            ResultItem(label: 'BMI', value: r.bmi.toStringAsFixed(1), isHighlighted: true, color: r.categoryColor),
            ResultItem(label: 'Category', value: r.category, color: r.categoryColor),
            ResultItem(
              label: 'Healthy Weight Range',
              value: '${r.healthyWeightMin.toStringAsFixed(1)} - ${r.healthyWeightMax.toStringAsFixed(1)} kg',
            ),
          ],
        ),
      ],
    );
  }
}

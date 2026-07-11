import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../domain/insurance_calculators.dart';

class HealthInsuranceScreen extends CalculatorBaseScreen {
  const HealthInsuranceScreen({super.key})
      : super(
          calculatorId: 'health_insurance',
          calculatorName: 'Health Insurance Calculator',
          category: 'Insurance',
        );

  @override
  ConsumerState<HealthInsuranceScreen> createState() => _HealthInsuranceScreenState();
}

class _HealthInsuranceScreenState extends CalculatorBaseState<HealthInsuranceScreen> {
  final _formKey = GlobalKey<FormState>();
  int _age = 30;
  int _familySize = 3;
  String _cityType = 'metro';
  HealthInsuranceResult? _result;

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);

  @override
  Map<String, dynamic> get currentInputs => {
        'Age': '$_age years',
        'Family Size': '$_familySize members',
        'City Type': _cityType == 'metro' ? 'Metro' : 'Non-Metro',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Annual Premium': NumberFormatter.formatCurrency(_result!.annualPremium, symbol: _symbol),
          'Monthly Premium': NumberFormatter.formatCurrency(_result!.monthlyPremium, symbol: _symbol),
          'Coverage Amount': NumberFormatter.formatCurrency(_result!.coverageAmount, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Annual Premium: ${NumberFormatter.formatCurrency(_result!.annualPremium, symbol: _symbol)} | '
          'Coverage: ${NumberFormatter.formatCurrency(_result!.coverageAmount, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = InsuranceCalculators.calculateHealthInsurance(
        age: _age,
        familySize: _familySize,
        cityType: _cityType,
      );
    });
  }

  void _reset() {
    setState(() {
      _age = 30;
      _familySize = 3;
      _cityType = 'metro';
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
                  buildSectionTitle('Member Details'),
                  AppSliderField(
                    label: 'Your Age',
                    value: _age.toDouble(),
                    min: 18, max: 80, divisions: 62,
                    displayValue: (v) => '${v.toInt()} years',
                    onChanged: (v) => setState(() { _age = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Family Size',
                    value: _familySize.toDouble(),
                    min: 1, max: 8, divisions: 7,
                    displayValue: (v) => '${v.toInt()} ${v.toInt() == 1 ? 'member' : 'members'}',
                    onChanged: (v) => setState(() { _familySize = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  _buildCityTypeToggle(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate', icon: Icons.calculate_rounded,
                          onPressed: _calculate, width: double.infinity,
                          color: AppColors.insurance,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.insurance),
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

  Widget _buildCityTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('City Type',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleChip(label: 'Metro', selected: _cityType == 'metro',
                  onTap: () => setState(() { _cityType = 'metro'; _result = null; })),
              _ToggleChip(label: 'Non-Metro', selected: _cityType != 'metro',
                  onTap: () => setState(() { _cityType = 'non-metro'; _result = null; })),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Premium Estimate'),
          Center(
            child: Column(
              children: [
                const Text('Annual Premium', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.annualPremium,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.insurance),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Monthly Premium',
                    value: NumberFormatter.formatCurrency(r.monthlyPremium, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Coverage Amount',
                    value: NumberFormatter.formatCurrency(r.coverageAmount, symbol: symbol),
                    valueColor: AppColors.insurance),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Coverage Summary',
            items: [
              ResultItem(label: 'Member Age', value: '$_age years'),
              ResultItem(label: 'Family Size', value: '$_familySize members'),
              ResultItem(label: 'City Type', value: _cityType == 'metro' ? 'Metro' : 'Non-Metro'),
              ResultItem(label: 'Coverage Amount', value: NumberFormatter.formatCurrency(r.coverageAmount, symbol: symbol)),
              ResultItem(label: 'Annual Premium', value: NumberFormatter.formatCurrency(r.annualPremium, symbol: symbol), isHighlighted: true, color: AppColors.insurance),
              ResultItem(label: 'Monthly Premium', value: NumberFormatter.formatCurrency(r.monthlyPremium, symbol: symbol)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.insurance.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: selected ? Border.all(color: AppColors.insurance.withValues(alpha: 0.5)) : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? AppColors.insurance : AppColors.textHint,
        )),
      ),
    );
  }
}

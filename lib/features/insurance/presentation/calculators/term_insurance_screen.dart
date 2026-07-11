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
import '../../domain/insurance_calculators.dart';

class TermInsuranceScreen extends CalculatorBaseScreen {
  const TermInsuranceScreen({super.key})
      : super(
          calculatorId: 'term_insurance',
          calculatorName: 'Term Insurance Calculator',
          category: 'Insurance',
        );

  @override
  ConsumerState<TermInsuranceScreen> createState() => _TermInsuranceScreenState();
}

class _TermInsuranceScreenState extends CalculatorBaseState<TermInsuranceScreen> {
  final _coverageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _age = 30;
  int _termYears = 20;
  bool _smoker = false;
  TermInsuranceResult? _result;

  @override
  void dispose() {
    _coverageController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _coverageValue => NumberFormatter.tryParse(_coverageController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Age': '$_age years',
        'Coverage': NumberFormatter.formatCurrency(_coverageValue, symbol: _symbol),
        'Term': '$_termYears years',
        'Smoker': _smoker ? 'Yes' : 'No',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Annual Premium': NumberFormatter.formatCurrency(_result!.annualPremium, symbol: _symbol),
          'Monthly Premium': NumberFormatter.formatCurrency(_result!.monthlyPremium, symbol: _symbol),
          'Total Premium': NumberFormatter.formatCurrency(_result!.totalPremium, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Annual: ${NumberFormatter.formatCurrency(_result!.annualPremium, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.totalPremium, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_coverageValue <= 0) return;

    setState(() {
      _result = InsuranceCalculators.calculateTermInsurance(
        age: _age,
        coverageAmount: _coverageValue,
        termYears: _termYears,
        smoking: _smoker,
      );
    });
  }

  void _reset() {
    setState(() {
      _coverageController.clear();
      _age = 30;
      _termYears = 20;
      _smoker = false;
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
                  buildSectionTitle('Policy Details'),
                  AppSliderField(
                    label: 'Your Age',
                    value: _age.toDouble(),
                    min: 18, max: 65, divisions: 47,
                    displayValue: (v) => '${v.toInt()} years',
                    onChanged: (v) => setState(() { _age = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Coverage Amount',
                    hint: '10000000',
                    controller: _coverageController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Policy Term',
                    value: _termYears.toDouble(),
                    min: 5, max: 40, divisions: 35,
                    displayValue: (v) => '${v.toInt()} years',
                    onChanged: (v) => setState(() { _termYears = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  _buildSmokerToggle(),
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

  Widget _buildSmokerToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Smoker Status',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleChip(label: 'Non-Smoker', selected: !_smoker,
                  onTap: () => setState(() { _smoker = false; _result = null; }),
                  color: AppColors.insurance),
              _ToggleChip(label: 'Smoker', selected: _smoker,
                  onTap: () => setState(() { _smoker = true; _result = null; }),
                  color: AppColors.insurance),
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
                child: ResultCard(label: 'Total over Term',
                    value: NumberFormatter.formatCurrency(r.totalPremium, symbol: symbol),
                    valueColor: AppColors.insurance),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Premium Breakdown',
            items: [
              ResultItem(label: 'Sum Assured', value: NumberFormatter.formatCurrency(_coverageValue, symbol: symbol)),
              ResultItem(label: 'Annual Premium', value: NumberFormatter.formatCurrency(r.annualPremium, symbol: symbol), isHighlighted: true),
              ResultItem(label: 'Monthly Premium', value: NumberFormatter.formatCurrency(r.monthlyPremium, symbol: symbol)),
              ResultItem(label: 'Total Premium (${_termYears}yrs)', value: NumberFormatter.formatCurrency(r.totalPremium, symbol: symbol), color: AppColors.insurance),
              ResultItem(label: 'Smoker Loading', value: _smoker ? 'Applied (${_smoker ? "+70%" : "None"})' : 'None',
                  color: _smoker ? AppColors.warning : AppColors.success),
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
  final Color color;

  const _ToggleChip({required this.label, required this.selected, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: selected ? Border.all(color: color.withValues(alpha: 0.5)) : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? color : AppColors.textHint,
        )),
      ),
    );
  }
}

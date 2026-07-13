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

class InsuranceNeedScreen extends CalculatorBaseScreen {
  const InsuranceNeedScreen({super.key})
      : super(
          calculatorId: 'insurance_need',
          calculatorName: 'Insurance Need Calculator',
          category: 'Insurance',
        );

  @override
  ConsumerState<InsuranceNeedScreen> createState() => _InsuranceNeedScreenState();
}

class _InsuranceNeedScreenState extends CalculatorBaseState<InsuranceNeedScreen> {
  final _incomeController = TextEditingController();
  final _coverageController = TextEditingController();
  final _liabilitiesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _dependents = 2;
  InsuranceNeedResult? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    _coverageController.dispose();
    _liabilitiesController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _incomeValue => NumberFormatter.tryParse(_incomeController.text) ?? 0;
  double get _coverageValue => NumberFormatter.tryParse(_coverageController.text) ?? 0;
  double get _liabilitiesValue => NumberFormatter.tryParse(_liabilitiesController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Annual Income': NumberFormatter.formatCurrency(_incomeValue, symbol: _symbol),
        'Existing Coverage': NumberFormatter.formatCurrency(_coverageValue, symbol: _symbol),
        'Dependents': '$_dependents',
        'Liabilities': NumberFormatter.formatCurrency(_liabilitiesValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Recommended Coverage': NumberFormatter.formatCurrency(_result!.recommendedCoverage, symbol: _symbol),
        'Monthly Premium': NumberFormatter.formatCurrency(_result!.monthlyPremium, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Need: ${NumberFormatter.formatCurrency(_result!.recommendedCoverage, symbol: _symbol)} | '
          'Premium: ${NumberFormatter.formatCurrency(_result!.monthlyPremium, symbol: _symbol)}/mo';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = InsuranceCalculators.calculateInsuranceNeed(
        annualIncome: _incomeValue,
        existingCoverage: _coverageValue,
        dependents: _dependents,
        liabilities: _liabilitiesValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _incomeController.clear();
      _coverageController.clear();
      _liabilitiesController.clear();
      _dependents = 2;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    final gap = _result != null
        ? (_result!.recommendedCoverage - _coverageValue).clamp(0.0, double.infinity)
        : 0.0;

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
                  buildSectionTitle('Your Profile'),
                  AppTextField(
                    label: 'Annual Income',
                    hint: '600000',
                    controller: _incomeController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Number of Dependents',
                    value: _dependents.toDouble(),
                    min: 0, max: 6, divisions: 6,
                    displayValue: (v) => '${v.toInt()} ${v.toInt() == 1 ? 'dependent' : 'dependents'}',
                    onChanged: (v) => setState(() { _dependents = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Existing Life Insurance Coverage',
                    hint: '0',
                    controller: _coverageController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Outstanding Liabilities',
                    hint: '0',
                    controller: _liabilitiesController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
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
              _buildResultSection(symbol, gap),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol, double gap) {
    final r = _result!;
    final hasGap = gap > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Coverage Analysis'),
          Center(
            child: Column(
              children: [
                const Text('Recommended Coverage', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.recommendedCoverage,
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
                child: ResultCard(label: 'Existing Coverage',
                    value: NumberFormatter.formatCurrency(_coverageValue, symbol: symbol)),
              ),
            ],
          ),
          if (hasGap) ...[
            const SizedBox(height: 10),
            ResultCard(
              label: 'Coverage Gap',
              value: NumberFormatter.formatCurrency(gap, symbol: symbol),
              isHighlighted: true,
              valueColor: AppColors.error,
              subtitle: 'Additional coverage needed',
            ),
          ] else ...[
            const SizedBox(height: 10),
            const ResultCard(
              label: 'Coverage Gap',
              value: 'No gap - adequately covered!',
              isHighlighted: true,
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Need Analysis',
            items: [
              ResultItem(label: 'Annual Income', value: NumberFormatter.formatCurrency(_incomeValue, symbol: symbol)),
              ResultItem(label: '10x Income Rule', value: NumberFormatter.formatCurrency(_incomeValue * 10, symbol: symbol)),
              ResultItem(label: 'Existing Coverage', value: NumberFormatter.formatCurrency(_coverageValue, symbol: symbol)),
              ResultItem(label: 'Outstanding Liabilities', value: NumberFormatter.formatCurrency(_liabilitiesValue, symbol: symbol)),
              ResultItem(label: 'Recommended Coverage', value: NumberFormatter.formatCurrency(r.recommendedCoverage, symbol: symbol), isHighlighted: true, color: AppColors.insurance),
              ResultItem(label: 'Est. Monthly Premium', value: NumberFormatter.formatCurrency(r.monthlyPremium, symbol: symbol)),
            ],
          ),
        ],
      ),
    );
  }
}

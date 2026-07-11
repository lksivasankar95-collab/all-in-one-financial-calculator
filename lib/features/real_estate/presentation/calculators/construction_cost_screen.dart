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
import '../../domain/real_estate_calculators.dart';

class ConstructionCostScreen extends CalculatorBaseScreen {
  const ConstructionCostScreen({super.key})
      : super(
          calculatorId: 'construction_cost',
          calculatorName: 'Construction Cost Calculator',
          category: 'Real Estate',
        );

  @override
  ConsumerState<ConstructionCostScreen> createState() => _ConstructionCostScreenState();
}

class _ConstructionCostScreenState extends CalculatorBaseState<ConstructionCostScreen> {
  final _areaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _ratePerSqft = 2000;
  String _quality = 'Standard';
  ConstructionCostResult? _result;

  static const _qualityOptions = ['Economy', 'Standard', 'Premium', 'Luxury'];
  static const _qualityFactors = {'Economy': 0.8, 'Standard': 1.0, 'Premium': 1.4, 'Luxury': 1.8};

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _areaValue => NumberFormatter.tryParse(_areaController.text) ?? 0;
  double get _qualityFactor => (_qualityFactors[_quality] ?? 1.0);

  @override
  Map<String, dynamic> get currentInputs => {
        'Built-up Area': '${_areaValue.toStringAsFixed(0)} sqft',
        'Rate/sqft': NumberFormatter.formatCurrency(_ratePerSqft, symbol: _symbol),
        'Quality': _quality,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Base Cost': NumberFormatter.formatCurrency(_result!.baseCost, symbol: _symbol),
        'Total Cost': NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol),
        'Cost/sqft': NumberFormatter.formatCurrency(_result!.costPerSqft, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Total: ${NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol)} | '
          'Rate: ${NumberFormatter.formatCurrency(_result!.costPerSqft, symbol: _symbol)}/sqft';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_areaValue <= 0) return;

    setState(() {
      _result = RealEstateCalculators.calculateConstructionCost(
        builtUpArea: _areaValue,
        constructionRatePerSqft: _ratePerSqft,
        qualityFactor: _qualityFactor,
      );
    });
  }

  void _reset() {
    setState(() {
      _areaController.clear();
      _ratePerSqft = 2000;
      _quality = 'Standard';
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
                  buildSectionTitle('Construction Details'),
                  AppTextField(
                    label: 'Built-up Area (sqft)',
                    hint: '1500', controller: _areaController,
                    keyboardType: TextInputType.number,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Construction Rate per sqft',
                    value: _ratePerSqft,
                    min: 500, max: 10000, divisions: 190,
                    displayValue: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                    onChanged: (v) => setState(() { _ratePerSqft = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  _buildQualityDropdown(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Calculate', icon: Icons.calculate_rounded,
                            onPressed: _calculate, width: double.infinity, color: AppColors.realEstate),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.realEstate),
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

  Widget _buildQualityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quality / Finish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _quality, isExpanded: true, dropdownColor: AppColors.card,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.realEstate),
              items: _qualityOptions.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
              onChanged: (v) { if (v != null) setState(() { _quality = v; _result = null; }); },
            ),
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
          buildSectionTitle('Cost Estimate'),
          Center(
            child: Column(
              children: [
                const Text('Total Construction Cost', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalCost,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.realEstate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Base Cost',
                    value: NumberFormatter.formatCurrency(r.baseCost, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Cost per sqft',
                    value: NumberFormatter.formatCurrency(r.costPerSqft, symbol: symbol),
                    valueColor: AppColors.realEstate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Cost Breakdown',
            items: [
              ResultItem(label: 'Built-up Area', value: '${_areaValue.toStringAsFixed(0)} sqft'),
              ResultItem(label: 'Base Rate', value: NumberFormatter.formatCurrency(_ratePerSqft, symbol: symbol)),
              ResultItem(label: 'Quality Factor', value: '${_quality} (${_qualityFactor}x)'),
              ResultItem(label: 'Base Cost', value: NumberFormatter.formatCurrency(r.baseCost, symbol: symbol)),
              ResultItem(label: 'Quality Adjustment', value: '+${NumberFormatter.formatCurrency(r.totalCost - r.baseCost, symbol: symbol)}'),
              ResultItem(label: 'Total Cost', value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol), isHighlighted: true, color: AppColors.realEstate),
              ResultItem(label: 'Effective Rate', value: NumberFormatter.formatCurrency(r.costPerSqft, symbol: symbol)),
            ],
          ),
        ],
      ),
    );
  }
}

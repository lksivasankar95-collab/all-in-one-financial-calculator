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

class PropertyValuationScreen extends CalculatorBaseScreen {
  const PropertyValuationScreen({super.key})
      : super(
          calculatorId: 'property_valuation',
          calculatorName: 'Property Valuation Calculator',
          category: 'Real Estate',
        );

  @override
  ConsumerState<PropertyValuationScreen> createState() => _PropertyValuationScreenState();
}

class _PropertyValuationScreenState extends CalculatorBaseState<PropertyValuationScreen> {
  final _areaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _ratePerSqft = 5000;
  int _floor = 3;
  double _locationFactor = 1.0;
  int _age = 5;
  PropertyValuationResult? _result;

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _areaValue => NumberFormatter.tryParse(_areaController.text) ?? 0;

  double get _floorFactor {
    if (_floor <= 2) return 1.0;
    if (_floor <= 5) return 1.05;
    if (_floor <= 10) return 1.10;
    if (_floor <= 15) return 1.15;
    return 1.20;
  }

  double get _ageFactor => (1 - _age * 0.01).clamp(0.5, 1.0);

  @override
  Map<String, dynamic> get currentInputs => {
        'Built-up Area': '${_areaValue.toStringAsFixed(0)} sqft',
        'Rate/sqft': NumberFormatter.formatCurrency(_ratePerSqft, symbol: _symbol),
        'Floor': '$_floor',
        'Location Factor': _locationFactor.toStringAsFixed(1),
        'Age': '$_age years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Base Value': NumberFormatter.formatCurrency(_result!.baseValue, symbol: _symbol),
        'Adjusted Value': NumberFormatter.formatCurrency(_result!.adjustedValue, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Estimated: ${NumberFormatter.formatCurrency(_result!.adjustedValue, symbol: _symbol)} | '
          'Base: ${NumberFormatter.formatCurrency(_result!.baseValue, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_areaValue <= 0) return;

    setState(() {
      _result = RealEstateCalculators.calculatePropertyValuation(
        builtUpArea: _areaValue,
        ratePerSqft: _ratePerSqft,
        floorFactor: _floorFactor,
        locationFactor: _locationFactor,
        ageFactor: _ageFactor,
      );
    });
  }

  void _reset() {
    setState(() {
      _areaController.clear();
      _ratePerSqft = 5000;
      _floor = 3;
      _locationFactor = 1.0;
      _age = 5;
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
                  buildSectionTitle('Property Details'),
                  AppTextField(
                    label: 'Built-up Area (sqft)',
                    hint: '1200', controller: _areaController,
                    keyboardType: TextInputType.number,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Rate per sqft', value: _ratePerSqft,
                    min: 100, max: 50000, divisions: 499,
                    displayValue: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                    onChanged: (v) => setState(() { _ratePerSqft = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Floor Number', value: _floor.toDouble(),
                    min: 1, max: 20, divisions: 19,
                    displayValue: (v) => '${v.toInt()} ${v.toInt() == 1 ? 'st' : v.toInt() == 2 ? 'nd' : v.toInt() == 3 ? 'rd' : 'th'} Floor (x${_floorFactor}x)',
                    onChanged: (v) => setState(() { _floor = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Location Factor', value: _locationFactor,
                    min: 0.5, max: 2.0, divisions: 150,
                    displayValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() { _locationFactor = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Property Age', value: _age.toDouble(),
                    min: 0, max: 50, divisions: 50,
                    displayValue: (v) => '${v.toInt()} years (-${(v.toInt() * 1).toStringAsFixed(0)}% depreciation)',
                    onChanged: (v) => setState(() { _age = v.toInt(); _result = null; }),
                  ),
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

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Valuation Result'),
          Center(
            child: Column(
              children: [
                const Text('Estimated Property Value', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.adjustedValue,
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
                child: ResultCard(label: 'Base Value',
                    value: NumberFormatter.formatCurrency(r.baseValue, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Adjustment Factor',
                    value: '${((r.adjustedValue / r.baseValue - 1) * 100).toStringAsFixed(1)}%',
                    valueColor: r.adjustedValue >= r.baseValue ? AppColors.success : AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Adjustments Applied',
            items: [
              ResultItem(label: 'Built-up Area', value: '${_areaValue.toStringAsFixed(0)} sqft'),
              ResultItem(label: 'Base Rate', value: NumberFormatter.formatCurrency(_ratePerSqft, symbol: symbol)),
              ResultItem(label: 'Base Value', value: NumberFormatter.formatCurrency(r.baseValue, symbol: symbol)),
              ResultItem(label: 'Floor Factor', value: '${_floorFactor.toStringAsFixed(2)}x'),
              ResultItem(label: 'Location Factor', value: '${_locationFactor.toStringAsFixed(1)}x'),
              ResultItem(label: 'Age Factor', value: '${_ageFactor.toStringAsFixed(2)}x'),
              ResultItem(label: 'Adjusted Value', value: NumberFormatter.formatCurrency(r.adjustedValue, symbol: symbol), isHighlighted: true, color: AppColors.realEstate),
            ],
          ),
        ],
      ),
    );
  }
}

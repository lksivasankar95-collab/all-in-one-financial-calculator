import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';

class UnitConverterScreen extends CalculatorBaseScreen {
  const UnitConverterScreen({super.key})
      : super(
          calculatorId: 'unit_converter',
          calculatorName: 'Unit Converter',
          category: 'Utility',
        );

  @override
  ConsumerState<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends CalculatorBaseState<UnitConverterScreen> {
  final _valueCtrl = TextEditingController();

  String _category = 'Length';
  String _fromUnit = 'km';
  String _toUnit = 'm';
  double? _result;

  static const Map<String, List<String>> _units = {
    'Length': ['km', 'm', 'cm', 'mm', 'miles', 'yards', 'feet', 'inches'],
    'Weight': ['kg', 'g', 'mg', 'lbs', 'oz', 'ton'],
    'Temperature': ['°C', '°F', 'K'],
    'Area': ['sq m', 'sq km', 'sq ft', 'acres', 'hectares'],
  };

  // Conversion factors to base unit (m for length, g for weight, sq m for area)
  static const Map<String, double> _toBase = {
    // Length → meters
    'km': 1000, 'm': 1, 'cm': 0.01, 'mm': 0.001,
    'miles': 1609.344, 'yards': 0.9144, 'feet': 0.3048, 'inches': 0.0254,
    // Weight → grams
    'kg': 1000, 'g': 1, 'mg': 0.001, 'lbs': 453.592, 'oz': 28.3495, 'ton': 1000000,
    // Area → sq meters
    'sq m': 1, 'sq km': 1000000, 'sq ft': 0.092903, 'acres': 4046.86, 'hectares': 10000,
  };

  double _convert(double value, String from, String to) {
    if (from == to) return value;

    // Temperature: special case
    if (_category == 'Temperature') {
      return _convertTemperature(value, from, to);
    }

    final fromFactor = _toBase[from] ?? 1.0;
    final toFactor = _toBase[to] ?? 1.0;
    return value * fromFactor / toFactor;
  }

  double _convertTemperature(double value, String from, String to) {
    // First convert to Celsius
    double celsius;
    switch (from) {
      case '°C': celsius = value; break;
      case '°F': celsius = (value - 32) * 5 / 9; break;
      case 'K': celsius = value - 273.15; break;
      default: celsius = value;
    }
    // Then convert from Celsius to target
    switch (to) {
      case '°C': return celsius;
      case '°F': return celsius * 9 / 5 + 32;
      case 'K': return celsius + 273.15;
      default: return celsius;
    }
  }

  void _onValueChanged(String text) {
    final val = double.tryParse(text.trim());
    setState(() {
      _result = val != null ? _convert(val, _fromUnit, _toUnit) : null;
    });
  }

  void _swap() {
    setState(() {
      final tmp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = tmp;
      final val = double.tryParse(_valueCtrl.text.trim());
      _result = val != null ? _convert(val, _fromUnit, _toUnit) : null;
    });
  }

  void _onCategoryChanged(String cat) {
    setState(() {
      _category = cat;
      _fromUnit = _units[cat]!.first;
      _toUnit = _units[cat]![1];
      _result = null;
    });
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Value': _valueCtrl.text,
        'From': _fromUnit,
        'To': _toUnit,
        'Category': _category,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {'Result': '${_result!.toStringAsFixed(6)} $_toUnit'};

  @override
  String get resultSummary => _result == null
      ? ''
      : '${_valueCtrl.text} $_fromUnit = ${_result!.toStringAsFixed(4)} $_toUnit';

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = _units[_category]!;
    return buildCalculatorScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector
            buildSectionTitle('Category'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _units.keys.map((cat) {
                  final selected = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) => _onCategoryChanged(cat),
                      selectedColor: AppColors.utility.withValues(alpha: 0.2),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: selected ? AppColors.utility : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.utility : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            buildSectionTitle('Convert'),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Enter Value',
              hint: '1.0',
              controller: _valueCtrl,
              onChanged: _onValueChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _UnitDropdown(
                    label: 'From',
                    value: _fromUnit,
                    units: units,
                    onChanged: (u) {
                      setState(() {
                        _fromUnit = u!;
                        final val = double.tryParse(_valueCtrl.text.trim());
                        _result = val != null ? _convert(val, _fromUnit, _toUnit) : null;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    onPressed: _swap,
                    icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.utility),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.utility.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.utility.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _UnitDropdown(
                    label: 'To',
                    value: _toUnit,
                    units: units,
                    onChanged: (u) {
                      setState(() {
                        _toUnit = u!;
                        final val = double.tryParse(_valueCtrl.text.trim());
                        _result = val != null ? _convert(val, _fromUnit, _toUnit) : null;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.utility.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.utility.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_valueCtrl.text} $_fromUnit =',
                      style: const TextStyle(fontSize: 14, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatResult(_result!),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.utility,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _toUnit,
                      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResultSummaryCard(
                title: 'Conversion Details',
                items: [
                  ResultItem(label: 'Input', value: '${_valueCtrl.text} $_fromUnit'),
                  ResultItem(label: 'Output', value: '${_formatResult(_result!)} $_toUnit', isHighlighted: true),
                  ResultItem(label: 'Category', value: _category),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatResult(double val) {
    if (val.abs() < 0.0001 || val.abs() > 99999999) {
      return val.toStringAsExponential(4);
    }
    if (val == val.truncateToDouble()) return val.toStringAsFixed(0);
    return val.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

class _UnitDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> units;
  final void Function(String?) onChanged;

  const _UnitDropdown({
    required this.label,
    required this.value,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

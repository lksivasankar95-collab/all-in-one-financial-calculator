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

class FuelCostScreen extends CalculatorBaseScreen {
  const FuelCostScreen({super.key})
      : super(
          calculatorId: 'fuel_cost',
          calculatorName: 'Fuel Cost Calculator',
          category: 'Utility',
        );

  @override
  ConsumerState<FuelCostScreen> createState() => _FuelCostScreenState();
}

class _FuelCostScreenState extends CalculatorBaseState<FuelCostScreen> {
  final _distanceController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  FuelCostResult? _result;

  double _mileage = 15;
  double _avgSpeed = 60;

  @override
  void dispose() {
    _distanceController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Distance (km)': _distanceController.text,
        'Mileage (kmpl)': _mileage.toStringAsFixed(1),
        'Fuel Price/L': _priceController.text,
        'Avg Speed (kmph)': _avgSpeed.toStringAsFixed(0),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Fuel Required': '${_result!.fuelRequired.toStringAsFixed(2)} L',
          'Total Cost': NumberFormatter.formatCurrency(_result!.totalFuelCost),
          'Cost per km': NumberFormatter.formatCurrency(_result!.costPerKm),
          'Trip Duration': '${_result!.tripDuration.toStringAsFixed(1)} hours',
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Fuel: ${_result!.fuelRequired.toStringAsFixed(1)}L, Cost: ${NumberFormatter.formatCurrency(_result!.totalFuelCost)}';

  double get _distance => NumberFormatter.tryParse(_distanceController.text) ?? 0;
  double get _price => NumberFormatter.tryParse(_priceController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = UtilityCalculators.calculateFuelCost(
        distanceKm: _distance,
        mileageKmpl: _mileage,
        fuelPricePerLiter: _price,
        averageSpeedKmph: _avgSpeed,
      );
    });
  }

  void _reset() {
    setState(() {
      _distanceController.clear();
      _priceController.clear();
      _mileage = 15;
      _avgSpeed = 60;
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
                  buildSectionTitle('Trip Details'),
                  AppTextField(
                    label: 'Distance (km)',
                    hint: '100',
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Enter a valid distance';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                    suffix: 'km',
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Mileage',
                    value: _mileage,
                    min: 5,
                    max: 30,
                    divisions: 25,
                    displayValue: (v) => '${v.toStringAsFixed(1)} kmpl',
                    onChanged: (v) {
                      setState(() {
                        _mileage = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Fuel Price per Liter',
                    hint: '105',
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Enter a valid price';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                    suffix: '/L',
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Average Speed',
                    value: _avgSpeed,
                    min: 20,
                    max: 120,
                    divisions: 20,
                    displayValue: (v) => '${v.toStringAsFixed(0)} kmph',
                    onChanged: (v) {
                      setState(() {
                        _avgSpeed = v;
                        _result = null;
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

    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              buildSectionTitle('Fuel Cost'),
              const SizedBox(height: 8),
              AnimatedResultValue(
                value: r.totalFuelCost,
                formatter: (v) => NumberFormatter.formatCurrency(v),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.utility,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Fuel Required',
                      value: '${r.fuelRequired.toStringAsFixed(2)} L',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResultCard(
                      label: 'Cost per km',
                      value: NumberFormatter.formatCurrency(r.costPerKm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Trip Duration',
                      value: '${r.tripDuration.toStringAsFixed(1)} hrs',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResultCard(
                      label: 'Mileage',
                      value: '${r.mileage.toStringAsFixed(1)} kmpl',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResultSummaryCard(
          title: 'Breakdown',
          onCopy: copyResult,
          items: [
            ResultItem(label: 'Distance', value: '${r.distance.toStringAsFixed(1)} km'),
            ResultItem(label: 'Fuel Required', value: '${r.fuelRequired.toStringAsFixed(2)} L'),
            ResultItem(label: 'Fuel Price', value: '${NumberFormatter.formatCurrency(r.fuelPrice)}/L'),
            ResultItem(
              label: 'Total Fuel Cost',
              value: NumberFormatter.formatCurrency(r.totalFuelCost),
              isHighlighted: true,
              color: AppColors.utility,
            ),
            ResultItem(label: 'Cost per km', value: NumberFormatter.formatCurrency(r.costPerKm)),
            ResultItem(label: 'Trip Duration', value: '${r.tripDuration.toStringAsFixed(1)} hours'),
          ],
        ),
      ],
    );
  }
}

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
import '../../domain/business_calculators.dart';

class BreakEvenScreen extends CalculatorBaseScreen {
  const BreakEvenScreen({super.key})
      : super(
          calculatorId: 'break_even',
          calculatorName: 'Break-Even Analysis',
          category: 'Business',
        );

  @override
  ConsumerState<BreakEvenScreen> createState() => _BreakEvenScreenState();
}

class _BreakEvenScreenState extends CalculatorBaseState<BreakEvenScreen> {
  final _fixedCostsController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _variableCostController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  BreakEvenResult? _result;

  @override
  void dispose() {
    _fixedCostsController.dispose();
    _sellingPriceController.dispose();
    _variableCostController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _fixedCostsValue =>
      NumberFormatter.tryParse(_fixedCostsController.text) ?? 0;
  double get _sellingPriceValue =>
      NumberFormatter.tryParse(_sellingPriceController.text) ?? 0;
  double get _variableCostValue =>
      NumberFormatter.tryParse(_variableCostController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Fixed Costs':
            NumberFormatter.formatCurrency(_fixedCostsValue, symbol: _symbol),
        'Selling Price / Unit':
            NumberFormatter.formatCurrency(_sellingPriceValue, symbol: _symbol),
        'Variable Cost / Unit':
            NumberFormatter.formatCurrency(_variableCostValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Break-Even Units':
              _result!.breakEvenUnits.toStringAsFixed(0),
          'Break-Even Revenue': NumberFormatter.formatCurrency(
              _result!.breakEvenRevenue,
              symbol: _symbol),
          'Contribution Margin / Unit': NumberFormatter.formatCurrency(
              _result!.contributionMarginPerUnit,
              symbol: _symbol),
          'Contribution Margin Ratio':
              NumberFormatter.formatPercent(_result!.contributionMarginRatio),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Break-Even: ${_result!.breakEvenUnits.toStringAsFixed(0)} units = '
          '${NumberFormatter.formatCurrency(_result!.breakEvenRevenue, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_fixedCostsValue <= 0) return;

    setState(() {
      _result = BusinessCalculators.calculateBreakEven(
        fixedCosts: _fixedCostsValue,
        sellingPricePerUnit: _sellingPriceValue,
        variableCostPerUnit: _variableCostValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _fixedCostsController.clear();
      _sellingPriceController.clear();
      _variableCostController.clear();
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
                  buildSectionTitle('Cost Structure'),
                  AppTextField(
                    label: 'Fixed Costs (Total)',
                    hint: '1,00,000',
                    controller: _fixedCostsController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter valid fixed costs';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Selling Price Per Unit',
                    hint: '500',
                    controller: _sellingPriceController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = NumberFormatter.tryParse(v) ?? 0;
                      if (val <= 0) return 'Enter a valid selling price';
                      if (val <= (NumberFormatter.tryParse(
                              _variableCostController.text) ??
                          0)) {
                        return 'Must be greater than variable cost';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Variable Cost Per Unit',
                    hint: '300',
                    controller: _variableCostController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid variable cost';
                      }
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
                          color: AppColors.business,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.business,
                      ),
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
          buildSectionTitle('Break-Even Analysis'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.business.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.business.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Break-Even Units',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    AnimatedResultValue(
                      value: r.breakEvenUnits,
                      formatter: (v) => v.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.business,
                      ),
                    ),
                    const Text(
                      'units',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.border,
                ),
                Column(
                  children: [
                    const Text(
                      'Break-Even Revenue',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    AnimatedResultValue(
                      value: r.breakEvenRevenue,
                      formatter: (v) =>
                          NumberFormatter.formatCurrency(v, symbol: symbol),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.business,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Contribution / Unit',
                  value: NumberFormatter.formatCurrency(
                      r.contributionMarginPerUnit,
                      symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Contribution Ratio',
                  value: NumberFormatter.formatPercent(
                      r.contributionMarginRatio),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Analysis Breakdown',
            items: [
              ResultItem(
                label: 'Fixed Costs',
                value: NumberFormatter.formatCurrency(_fixedCostsValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Selling Price / Unit',
                value: NumberFormatter.formatCurrency(_sellingPriceValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Variable Cost / Unit',
                value: NumberFormatter.formatCurrency(_variableCostValue,
                    symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Contribution Margin / Unit',
                value: NumberFormatter.formatCurrency(
                    r.contributionMarginPerUnit,
                    symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Contribution Margin Ratio',
                value: NumberFormatter.formatPercent(r.contributionMarginRatio),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Break-Even Units',
                value: r.breakEvenUnits.toStringAsFixed(0),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Break-Even Revenue',
                value: NumberFormatter.formatCurrency(r.breakEvenRevenue,
                    symbol: symbol),
                isHighlighted: true,
                color: AppColors.business,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

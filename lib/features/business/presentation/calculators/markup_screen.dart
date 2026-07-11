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

class MarkupScreen extends CalculatorBaseScreen {
  const MarkupScreen({super.key})
      : super(
          calculatorId: 'markup',
          calculatorName: 'Markup Calculator',
          category: 'Business',
        );

  @override
  ConsumerState<MarkupScreen> createState() => _MarkupScreenState();
}

class _MarkupScreenState extends CalculatorBaseState<MarkupScreen> {
  final _costController = TextEditingController();
  final _markupPercentController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _marginPercentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _mode = 0;
  MarkupResult? _result;

  @override
  void dispose() {
    _costController.dispose();
    _markupPercentController.dispose();
    _sellingPriceController.dispose();
    _marginPercentController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _costValue =>
      NumberFormatter.tryParse(_costController.text) ?? 0;
  double get _markupPercentValue =>
      NumberFormatter.tryParse(_markupPercentController.text) ?? 0;
  double get _sellingPriceValue =>
      NumberFormatter.tryParse(_sellingPriceController.text) ?? 0;
  double get _marginPercentValue =>
      NumberFormatter.tryParse(_marginPercentController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Cost Price':
            NumberFormatter.formatCurrency(_costValue, symbol: _symbol),
        if (_mode == 0)
          'Markup %': NumberFormatter.formatPercent(_markupPercentValue)
        else if (_mode == 1)
          'Selling Price':
              NumberFormatter.formatCurrency(_sellingPriceValue, symbol: _symbol)
        else
          'Margin %': NumberFormatter.formatPercent(_marginPercentValue),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Selling Price':
              NumberFormatter.formatCurrency(_result!.sellingPrice, symbol: _symbol),
          'Markup Amount':
              NumberFormatter.formatCurrency(_result!.markupAmount, symbol: _symbol),
          'Markup %': NumberFormatter.formatPercent(_result!.markupPercent),
          'Profit Margin %': NumberFormatter.formatPercent(_result!.profitMargin),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Cost: ${NumberFormatter.formatCurrency(_costValue, symbol: _symbol)} | '
          'Sell: ${NumberFormatter.formatCurrency(_result!.sellingPrice, symbol: _symbol)} | '
          'Markup: ${NumberFormatter.formatPercent(_result!.markupPercent)} | '
          'Margin: ${NumberFormatter.formatPercent(_result!.profitMargin)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_costValue <= 0) return;

    setState(() {
      switch (_mode) {
        case 0:
          _result = BusinessCalculators.calculateMarkupFromCost(
            cost: _costValue,
            markupPercent: _markupPercentValue,
          );
        case 1:
          _result = BusinessCalculators.calculateMarkupFromSelling(
            cost: _costValue,
            sellingPrice: _sellingPriceValue,
          );
        case 2:
          _result = BusinessCalculators.calculateMarkupFromMargin(
            cost: _costValue,
            marginPercent: _marginPercentValue,
          );
      }
    });
  }

  void _reset() {
    setState(() {
      _costController.clear();
      _markupPercentController.clear();
      _sellingPriceController.clear();
      _marginPercentController.clear();
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
                  buildSectionTitle('Calculation Mode'),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Cost +\nMarkup %',
                            style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Cost +\nSell Price',
                            style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: 2,
                        label: Text('Cost +\nMargin %',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (Set<int> selected) {
                      setState(() {
                        _mode = selected.first;
                        _result = null;
                      });
                    },
                    showSelectedIcon: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Input Values'),
                  AppTextField(
                    label: 'Cost Price',
                    hint: '1,000',
                    controller: _costController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter valid cost price';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_mode == 0) ...[
                    AppTextField(
                      label: 'Markup Percentage',
                      hint: '25',
                      suffix: '%',
                      controller: _markupPercentController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                          return 'Enter a valid markup %';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        if (_result != null) setState(() => _result = null);
                      },
                    ),
                  ] else if (_mode == 1) ...[
                    AppTextField(
                      label: 'Selling Price',
                      hint: '1,250',
                      controller: _sellingPriceController,
                      prefix: symbol,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = NumberFormatter.tryParse(v) ?? 0;
                        if (val <= 0) return 'Enter valid selling price';
                        if (val <= _costValue) {
                          return 'Must be > cost price';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        if (_result != null) setState(() => _result = null);
                      },
                    ),
                  ] else ...[
                    AppTextField(
                      label: 'Desired Margin %',
                      hint: '20',
                      suffix: '%',
                      controller: _marginPercentController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = NumberFormatter.tryParse(v) ?? 0;
                        if (val <= 0 || val >= 100) {
                          return 'Enter margin between 1-99%';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        if (_result != null) setState(() => _result = null);
                      },
                    ),
                  ],
                ],
              ),
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
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(
                  label: 'Reset',
                  isOutlined: true,
                  onPressed: _reset,
                ),
              ],
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
      borderColor: AppColors.business.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Markup Results'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Selling Price',
                  value: NumberFormatter.formatCurrency(
                      r.sellingPrice, symbol: symbol),
                  valueColor: AppColors.success,
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Profit Margin',
                  value: NumberFormatter.formatPercent(r.profitMargin),
                  valueColor: AppColors.business,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResultSummaryCard(
            title: 'Markup Breakdown',
            items: [
              ResultItem(
                label: 'Cost Price',
                value:
                    NumberFormatter.formatCurrency(r.costPrice, symbol: symbol),
              ),
              ResultItem(
                label: 'Markup Amount',
                value: NumberFormatter.formatCurrency(
                    r.markupAmount, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Markup %',
                value: NumberFormatter.formatPercent(r.markupPercent),
                color: AppColors.business,
              ),
              ResultItem(
                label: 'Selling Price',
                value: NumberFormatter.formatCurrency(
                    r.sellingPrice, symbol: symbol),
                isHighlighted: true,
                color: AppColors.primary,
              ),
              ResultItem(
                label: 'Profit Margin %',
                value: NumberFormatter.formatPercent(r.profitMargin),
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

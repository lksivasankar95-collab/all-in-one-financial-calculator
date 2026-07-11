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
import '../../domain/stock_market_calculators.dart';

class BreakEvenPriceScreen extends CalculatorBaseScreen {
  const BreakEvenPriceScreen({super.key})
      : super(
          calculatorId: 'break_even_price',
          calculatorName: 'Break-Even Price Calculator',
          category: 'Stock Market',
        );

  @override
  ConsumerState<BreakEvenPriceScreen> createState() => _BreakEvenPriceScreenState();
}

class _BreakEvenPriceScreenState extends CalculatorBaseState<BreakEvenPriceScreen> {
  final _buyController = TextEditingController();
  final _qtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _brokerage = 0.05;
  double _taxes = 0.1;
  BreakEvenPriceResult? _result;

  @override
  void dispose() {
    _buyController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _buyValue => NumberFormatter.tryParse(_buyController.text) ?? 0;
  int get _qtyValue => (NumberFormatter.tryParse(_qtyController.text) ?? 0).toInt();

  @override
  Map<String, dynamic> get currentInputs => {
        'Buy Price': NumberFormatter.formatCurrency(_buyValue, symbol: _symbol),
        'Quantity': '$_qtyValue',
        'Brokerage': NumberFormatter.formatPercent(_brokerage),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Break-Even Price': NumberFormatter.formatCurrency(_result!.breakEvenPrice, symbol: _symbol),
        'Total Cost': NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Break-Even: ${NumberFormatter.formatCurrency(_result!.breakEvenPrice, symbol: _symbol)} | '
          'Cost: ${NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_buyValue <= 0 || _qtyValue <= 0) return;

    setState(() {
      _result = StockMarketCalculators.calculateBreakEvenPrice(
        buyPrice: _buyValue,
        quantity: _qtyValue,
        brokerage: _brokerage,
        taxes: _taxes,
      );
    });
  }

  void _reset() {
    setState(() {
      _buyController.clear();
      _qtyController.clear();
      _brokerage = 0.05;
      _taxes = 0.1;
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
                  buildSectionTitle('Trade Details'),
                  AppTextField(label: 'Buy Price', hint: '150', controller: _buyController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Quantity', hint: '100', controller: _qtyController,
                    keyboardType: TextInputType.number,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Brokerage', value: _brokerage,
                    min: 0, max: 1, divisions: 100,
                    displayValue: (v) => '${v.toStringAsFixed(2)}%',
                    onChanged: (v) => setState(() { _brokerage = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'STT & Taxes', value: _taxes,
                    min: 0, max: 0.2, divisions: 20,
                    displayValue: (v) => '${v.toStringAsFixed(2)}%',
                    onChanged: (v) => setState(() { _taxes = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Calculate', icon: Icons.calculate_rounded,
                            onPressed: _calculate, width: double.infinity, color: AppColors.stockMarket),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.stockMarket),
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
    final diff = r.breakEvenPrice - _buyValue;
    final isHigher = diff >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Break-Even Analysis'),
          Center(
            child: Column(
              children: [
                const Text('Break-Even Price', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.breakEvenPrice,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.stockMarket),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Buy Price',
                    value: NumberFormatter.formatCurrency(_buyValue, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Cost',
                    value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Price Difference',
            value: '${isHigher ? '+' : ''}${NumberFormatter.formatCurrency(diff, symbol: symbol)}',
            isHighlighted: true,
            valueColor: isHigher ? AppColors.warning : AppColors.success,
            subtitle: 'You need to sell ${isHigher ? 'higher' : 'at least'} than buy price to break even',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Break-Even Summary',
            items: [
              ResultItem(label: 'Buy Price', value: NumberFormatter.formatCurrency(_buyValue, symbol: symbol)),
              ResultItem(label: 'Quantity', value: '$_qtyValue'),
              ResultItem(label: 'Total Cost', value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol)),
              ResultItem(label: 'Break-Even Price', value: NumberFormatter.formatCurrency(r.breakEvenPrice, symbol: symbol), isHighlighted: true, color: AppColors.stockMarket),
              ResultItem(label: 'Required % Gain', value: '${(diff / _buyValue * 100).toStringAsFixed(2)}%',
                  color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

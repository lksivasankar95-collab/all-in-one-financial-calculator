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

class StockProfitScreen extends CalculatorBaseScreen {
  const StockProfitScreen({super.key})
      : super(
          calculatorId: 'stock_profit',
          calculatorName: 'Stock Profit Calculator',
          category: 'Stock Market',
        );

  @override
  ConsumerState<StockProfitScreen> createState() => _StockProfitScreenState();
}

class _StockProfitScreenState extends CalculatorBaseState<StockProfitScreen> {
  final _buyController = TextEditingController();
  final _sellController = TextEditingController();
  final _qtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _brokerage = 0.05;
  double _taxes = 0.1;
  StockProfitResult? _result;

  @override
  void dispose() {
    _buyController.dispose();
    _sellController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _buyValue => NumberFormatter.tryParse(_buyController.text) ?? 0;
  double get _sellValue => NumberFormatter.tryParse(_sellController.text) ?? 0;
  int get _qtyValue => (NumberFormatter.tryParse(_qtyController.text) ?? 0).toInt();

  @override
  Map<String, dynamic> get currentInputs => {
        'Buy Price': NumberFormatter.formatCurrency(_buyValue, symbol: _symbol),
        'Sell Price': NumberFormatter.formatCurrency(_sellValue, symbol: _symbol),
        'Quantity': '$_qtyValue',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Total Buy Cost': NumberFormatter.formatCurrency(_result!.totalBuyValue, symbol: _symbol),
        'Total Sell Value': NumberFormatter.formatCurrency(_result!.totalSellValue, symbol: _symbol),
        'Net P&L': NumberFormatter.formatCurrency(_result!.profitLoss, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'P&L: ${NumberFormatter.formatCurrency(_result!.profitLoss, symbol: _symbol)} | '
          'ROI: ${NumberFormatter.formatPercent(_result!.profitLossPercent)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_buyValue <= 0 || _sellValue <= 0 || _qtyValue <= 0) return;

    setState(() {
      _result = StockMarketCalculators.calculateStockProfit(
        buyPrice: _buyValue,
        sellPrice: _sellValue,
        quantity: _qtyValue,
        brokerage: _brokerage,
        taxes: _taxes,
      );
    });
  }

  void _reset() {
    setState(() {
      _buyController.clear();
      _sellController.clear();
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
                  AppTextField(label: 'Buy Price', hint: '150.50', controller: _buyController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Sell Price', hint: '175.75', controller: _sellController, prefix: symbol,
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
                    label: 'STT & Other Taxes', value: _taxes,
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
    final isProfit = r.profitLoss >= 0;
    final breakEven = _buyValue + (r.brokerage + r.taxes) / _qtyValue;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Profit / Loss'),
          Center(
            child: Column(
              children: [
                const Text('Net Profit / Loss', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.profitLoss.abs(),
                  formatter: (v) => '${isProfit ? '+' : '-'}${NumberFormatter.formatCurrency(v, symbol: symbol)}',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                      color: isProfit ? AppColors.success : AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Total Buy Cost',
                    value: NumberFormatter.formatCurrency(r.totalBuyValue, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Sell Value',
                    value: NumberFormatter.formatCurrency(r.totalSellValue, symbol: symbol)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'ROI',
            value: '${isProfit ? '+' : ''}${NumberFormatter.formatPercent(r.profitLossPercent)}',
            isHighlighted: true,
            valueColor: isProfit ? AppColors.success : AppColors.error,
            subtitle: 'Breakeven price: ${NumberFormatter.formatCurrency(breakEven, symbol: symbol)}',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'P&L Summary',
            items: [
              ResultItem(label: 'Buy Value', value: NumberFormatter.formatCurrency(r.totalBuyValue, symbol: symbol)),
              ResultItem(label: 'Sell Value', value: NumberFormatter.formatCurrency(r.totalSellValue, symbol: symbol)),
              ResultItem(label: 'Brokerage Paid', value: NumberFormatter.formatCurrency(r.brokerage, symbol: symbol)),
              ResultItem(label: 'Taxes Paid', value: NumberFormatter.formatCurrency(r.taxes, symbol: symbol)),
              ResultItem(label: 'Net P&L', value: '${isProfit ? '+' : '-'}${NumberFormatter.formatCurrency(r.profitLoss.abs(), symbol: symbol)}',
                  isHighlighted: true, color: isProfit ? AppColors.success : AppColors.error),
              ResultItem(label: 'ROI %', value: '${isProfit ? '+' : ''}${NumberFormatter.formatPercent(r.profitLossPercent)}'),
            ],
          ),
        ],
      ),
    );
  }
}

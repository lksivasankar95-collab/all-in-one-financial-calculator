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

class StockAverageScreen extends CalculatorBaseScreen {
  const StockAverageScreen({super.key})
      : super(
          calculatorId: 'stock_average',
          calculatorName: 'Stock Average Calculator',
          category: 'Stock Market',
        );

  @override
  ConsumerState<StockAverageScreen> createState() => _StockAverageScreenState();
}

class _StockAverageScreenState extends CalculatorBaseState<StockAverageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lots = List.generate(3, (_) => _LotData());

  StockAverageResult? _result;

  @override
  void dispose() {
    for (final l in _lots) {
      l.qtyController.dispose();
      l.priceController.dispose();
    }
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);

  @override
  Map<String, dynamic> get currentInputs => {
        'Lots': '${_lots.where((l) => l.isValid).length} lots entered',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Average Price': NumberFormatter.formatCurrency(_result!.averagePrice, symbol: _symbol),
        'Total Investment': NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol),
        'Total Quantity': '${_result!.totalQuantity.toInt()}',
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Avg: ${NumberFormatter.formatCurrency(_result!.averagePrice, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final holdings = _lots
        .where((l) => l.isValid)
        .map((l) => StockHolding(
              buyPrice: NumberFormatter.tryParse(l.priceController.text) ?? 0,
              quantity: (NumberFormatter.tryParse(l.qtyController.text) ?? 0).toInt(),
            ))
        .toList();
    if (holdings.isEmpty) return;

    setState(() {
      _result = StockMarketCalculators.calculateStockAverage(holdings: holdings);
    });
  }

  void _reset() {
    setState(() {
      for (final l in _lots) {
        l.qtyController.clear();
        l.priceController.clear();
      }
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
                  buildSectionTitle('Stock Lots'),
                  ...List.generate(_lots.length, (i) {
                    final lot = _lots[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < _lots.length - 1 ? 16 : 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lot ${i + 1}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.stockMarket)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Quantity',
                                    hint: '10',
                                    controller: lot.qtyController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Buy Price',
                                    hint: '150',
                                    controller: lot.priceController,
                                    prefix: symbol,
                                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
    final totalQty = r.totalQuantity.toInt();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Average Price'),
          Center(
            child: Column(
              children: [
                const Text('Average Buy Price', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.averagePrice,
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
                child: ResultCard(label: 'Total Investment',
                    value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Quantity',
                    value: '$totalQty shares',
                    valueColor: AppColors.stockMarket),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Lot Summary',
            items: [
              ..._lots.where((l) => l.isValid).toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final l = entry.value;
                final qty = NumberFormatter.tryParse(l.qtyController.text)?.toInt() ?? 0;
                final price = NumberFormatter.tryParse(l.priceController.text) ?? 0;
                return ResultItem(
                  label: 'Lot ${idx + 1}: $qty shares @ ${NumberFormatter.formatCurrency(price, symbol: symbol)}',
                  value: NumberFormatter.formatCurrency(qty * price, symbol: symbol),
                );
              }),
              ResultItem(label: 'Total Invested', value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol), isHighlighted: true),
              ResultItem(label: 'Total Quantity', value: '$totalQty shares'),
              ResultItem(label: 'Average Price', value: NumberFormatter.formatCurrency(r.averagePrice, symbol: symbol), isHighlighted: true, color: AppColors.stockMarket),
            ],
          ),
        ],
      ),
    );
  }
}

class _LotData {
  final qtyController = TextEditingController();
  final priceController = TextEditingController();

  bool get isValid {
    final qty = NumberFormatter.tryParse(qtyController.text) ?? 0;
    final price = NumberFormatter.tryParse(priceController.text) ?? 0;
    return qty > 0 && price > 0;
  }
}

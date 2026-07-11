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
import '../../domain/crypto_calculators.dart';

class CryptoAverageScreen extends CalculatorBaseScreen {
  const CryptoAverageScreen({super.key})
      : super(
          calculatorId: 'crypto_average',
          calculatorName: 'Crypto Average Calculator',
          category: 'Crypto',
        );

  @override
  ConsumerState<CryptoAverageScreen> createState() => _CryptoAverageScreenState();
}

class _CryptoAverageScreenState extends CalculatorBaseState<CryptoAverageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purchases = List.generate(3, (_) => _PurchaseData());

  CryptoAverageResult? _result;

  @override
  void dispose() {
    for (final p in _purchases) {
      p.amountController.dispose();
      p.priceController.dispose();
    }
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);

  @override
  Map<String, dynamic> get currentInputs => {
        'Purchases': '${_purchases.where((p) => p.isValid).length} entries',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Average Price': NumberFormatter.formatCurrency(_result!.averagePrice, symbol: _symbol),
        'Total Invested': NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol),
        'Total Crypto': _result!.totalQuantity.toStringAsFixed(4),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Avg: ${NumberFormatter.formatCurrency(_result!.averagePrice, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final holdings = _purchases
        .where((p) => p.isValid)
        .map((p) => CryptoHolding(
              entryPrice: NumberFormatter.tryParse(p.priceController.text) ?? 0,
              quantity: NumberFormatter.tryParse(p.amountController.text) ?? 0,
            ))
        .toList();
    if (holdings.isEmpty) return;

    setState(() {
      _result = CryptoCalculators.calculateCryptoAverage(holdings: holdings);
    });
  }

  void _reset() {
    setState(() {
      for (final p in _purchases) {
        p.amountController.clear();
        p.priceController.clear();
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
                  buildSectionTitle('Purchase History'),
                  ...List.generate(_purchases.length, (i) {
                    final p = _purchases[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < _purchases.length - 1 ? 16 : 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Purchase ${i + 1}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.crypto)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Amount (Coins)',
                                    hint: '0.5',
                                    controller: p.amountController,
                                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Price per Coin (USD)',
                                    hint: '45000',
                                    controller: p.priceController,
                                    prefix: '\$',
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
                            onPressed: _calculate, width: double.infinity, color: AppColors.crypto),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.crypto),
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
          buildSectionTitle('Average Cost'),
          Center(
            child: Column(
              children: [
                const Text('Average Price per Coin', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.averagePrice,
                  formatter: (v) => '\$${v.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.crypto),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Total Invested',
                    value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Coins',
                    value: r.totalQuantity.toStringAsFixed(4),
                    valueColor: AppColors.crypto),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Purchase Summary',
            items: [
              ..._purchases.where((p) => p.isValid).toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final amt = NumberFormatter.tryParse(p.amountController.text) ?? 0;
                final price = NumberFormatter.tryParse(p.priceController.text) ?? 0;
                return ResultItem(
                  label: 'Buy ${idx + 1}: ${amt.toStringAsFixed(4)} @ \$${price.toStringAsFixed(2)}',
                  value: NumberFormatter.formatCurrency(amt * price, symbol: symbol),
                );
              }),
              ResultItem(label: 'Total Invested', value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol), isHighlighted: true),
              ResultItem(label: 'Total Coins', value: r.totalQuantity.toStringAsFixed(4)),
              ResultItem(label: 'Average Price', value: '\$${r.averagePrice.toStringAsFixed(2)}', isHighlighted: true, color: AppColors.crypto),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseData {
  final amountController = TextEditingController();
  final priceController = TextEditingController();

  bool get isValid {
    final amt = NumberFormatter.tryParse(amountController.text) ?? 0;
    final price = NumberFormatter.tryParse(priceController.text) ?? 0;
    return amt > 0 && price > 0;
  }
}

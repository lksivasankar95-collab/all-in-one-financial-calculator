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

class _LineItemData {
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;

  _LineItemData()
      : description = TextEditingController(),
        quantity = TextEditingController(text: '1'),
        unitPrice = TextEditingController();

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class InvoiceScreen extends CalculatorBaseScreen {
  const InvoiceScreen({super.key})
      : super(
          calculatorId: 'invoice',
          calculatorName: 'Invoice Calculator',
          category: 'Business',
        );

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends CalculatorBaseState<InvoiceScreen> {
  final List<_LineItemData> _items = [
    _LineItemData(),
    _LineItemData(),
    _LineItemData(),
  ];
  final _shippingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _discountPercent = 0;
  double _taxPercent = 18;
  InvoiceResult? _result;

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _shippingController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);

  List<InvoiceLineItem> _buildLineItems() {
    return _items.map((item) {
      final qty = NumberFormatter.tryParse(item.quantity.text) ?? 0;
      final price = NumberFormatter.tryParse(item.unitPrice.text) ?? 0;
      return InvoiceLineItem(
        description: item.description.text,
        quantity: qty,
        unitPrice: price,
        total: qty * price,
      );
    }).toList();
  }

  double get _shippingValue =>
      NumberFormatter.tryParse(_shippingController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Items': _items.length.toString(),
        'Discount': '$_discountPercent%',
        'Tax': '$_taxPercent%',
        'Shipping':
            NumberFormatter.formatCurrency(_shippingValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Subtotal':
              NumberFormatter.formatCurrency(_result!.subtotal, symbol: _symbol),
          'Discount':
              NumberFormatter.formatCurrency(_result!.discountAmount, symbol: _symbol),
          'Tax':
              NumberFormatter.formatCurrency(_result!.taxAmount, symbol: _symbol),
          'Total':
              NumberFormatter.formatCurrency(_result!.total, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Subtotal: ${NumberFormatter.formatCurrency(_result!.subtotal, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.total, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final lineItems = _buildLineItems();
    final hasValidItems = lineItems.any(
        (item) => item.description.isNotEmpty && item.quantity > 0 && item.unitPrice > 0);
    if (!hasValidItems) return;

    setState(() {
      _result = BusinessCalculators.calculateInvoice(
        items: lineItems,
        discountPercent: _discountPercent,
        taxPercent: _taxPercent,
        shipping: _shippingValue,
      );
    });
  }

  void _reset() {
    setState(() {
      for (final item in _items) {
        item.description.clear();
        item.quantity.text = '1';
        item.unitPrice.clear();
      }
      _shippingController.clear();
      _discountPercent = 0;
      _taxPercent = 18;
      _result = null;
    });
  }

  void _addItem() {
    setState(() {
      _items.add(_LineItemData());
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
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
                  buildSectionTitle('Line Items'),
                  ...List.generate(_items.length, (i) {
                    final item = _items[i];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i < _items.length - 1 ? 16 : 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Item ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.business,
                                  ),
                                ),
                                if (_items.length > 1)
                                  GestureDetector(
                                    onTap: () => _removeItem(i),
                                    child: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Description',
                              hint: 'Product or service name',
                              controller: item.description,
                              keyboardType: TextInputType.text,
                              onChanged: (_) {
                                if (_result != null) {
                                  setState(() => _result = null);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Qty',
                                    hint: '1',
                                    controller: item.quantity,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (_) {
                                      if (_result != null) {
                                        setState(() => _result = null);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    label: 'Unit Price',
                                    hint: '500',
                                    controller: item.unitPrice,
                                    prefix: _symbol,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    onChanged: (_) {
                                      if (_result != null) {
                                        setState(() => _result = null);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Item'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.business,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Invoice Settings'),
                  AppSliderField(
                    label: 'Discount %',
                    value: _discountPercent,
                    min: 0,
                    max: 50,
                    divisions: 50,
                    displayValue: (v) => '${v.toInt()}%',
                    onChanged: (v) {
                      setState(() {
                        _discountPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  AppSliderField(
                    label: 'Tax % (GST)',
                    value: _taxPercent,
                    min: 0,
                    max: 28,
                    divisions: 28,
                    displayValue: (v) => '${v.toInt()}%',
                    onChanged: (v) {
                      setState(() {
                        _taxPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Shipping & Handling',
                    hint: '0',
                    controller: _shippingController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                          return 'Enter valid shipping';
                        }
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Generate Invoice',
                    icon: Icons.receipt_long_rounded,
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
          buildSectionTitle('Invoice Summary'),
          const SizedBox(height: 8),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.business.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.business.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVOICE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.business,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${NumberFormatter.formatCurrency(r.total, symbol: symbol)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ResultCard(
                      label: 'Grand Total',
                      value:
                          NumberFormatter.formatCurrency(r.total, symbol: symbol),
                      valueColor: AppColors.success,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Line Items Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('Description',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint))),
                      Expanded(
                          child: Text('Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint))),
                      Expanded(
                          child: Text('Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint))),
                      Expanded(
                          child: Text('Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint))),
                    ],
                  ),
                ),
                // Table Rows
                ...r.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.description.isNotEmpty
                                ? item.description
                                : 'Item ${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            NumberFormatter.formatNumber(item.quantity),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            NumberFormatter.formatCurrency(
                                item.unitPrice, symbol: symbol),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            NumberFormatter.formatCurrency(
                                item.total, symbol: symbol),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _totalRow(
                    'Subtotal', r.subtotal, symbol, AppColors.textPrimary),
                const SizedBox(height: 6),
                _totalRow(
                    'Discount (${r.discountPercent.toInt()}%)',
                    -r.discountAmount,
                    symbol,
                    AppColors.error),
                const SizedBox(height: 6),
                _totalRow('Taxable Amount', r.taxableAmount, symbol,
                    AppColors.textPrimary),
                const SizedBox(height: 6),
                _totalRow('Tax (${r.taxPercent.toInt()}%)', r.taxAmount,
                    symbol, AppColors.warning),
                const SizedBox(height: 6),
                _totalRow('Shipping', r.shipping, symbol,
                    AppColors.textSecondary),
                const Divider(height: 20, color: AppColors.border),
                _totalRow('Grand Total', r.total, symbol, AppColors.primary,
                    isBold: true, isLarge: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, String symbol, Color color,
      {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 14 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value < 0
              ? '- ${NumberFormatter.formatCurrency(value.abs(), symbol: symbol)}'
              : NumberFormatter.formatCurrency(value, symbol: symbol),
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

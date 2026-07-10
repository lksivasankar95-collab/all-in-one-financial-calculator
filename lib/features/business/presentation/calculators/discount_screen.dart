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

class DiscountScreen extends CalculatorBaseScreen {
  const DiscountScreen({super.key})
      : super(
          calculatorId: 'discount',
          calculatorName: 'Discount Calculator',
          category: 'Business',
        );

  @override
  ConsumerState<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends CalculatorBaseState<DiscountScreen> {
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _discountPercent = 10.0;
  DiscountResult? _result;

  // Reverse calculation
  final _finalPriceController = TextEditingController();
  DiscountResult? _reverseResult;
  final _reverseFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _priceController.dispose();
    _finalPriceController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null || _reverseResult != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _priceValue =>
      NumberFormatter.tryParse(_priceController.text) ?? 0;
  double get _finalPriceValue =>
      NumberFormatter.tryParse(_finalPriceController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Original Price':
            NumberFormatter.formatCurrency(_priceValue, symbol: _symbol),
        'Discount': '${_discountPercent.toStringAsFixed(0)}%',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Discount Amount': NumberFormatter.formatCurrency(
              _result!.discountAmount,
              symbol: _symbol),
          'Final Price': NumberFormatter.formatCurrency(_result!.finalPrice,
              symbol: _symbol),
          'You Save': NumberFormatter.formatCurrency(_result!.savings,
              symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '${NumberFormatter.formatCurrency(_priceValue, symbol: _symbol)} at '
          '${_discountPercent.toStringAsFixed(0)}% off = '
          '${NumberFormatter.formatCurrency(_result!.finalPrice, symbol: _symbol)} '
          '(Save ${NumberFormatter.formatCurrency(_result!.savings, symbol: _symbol)})';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_priceValue <= 0) return;

    setState(() {
      _result = BusinessCalculators.calculateDiscount(
        originalPrice: _priceValue,
        discountPercent: _discountPercent,
      );
      _reverseResult = null;
      _finalPriceController.clear();
    });
  }

  void _calculateReverse() {
    if (!_reverseFormKey.currentState!.validate()) return;
    final finalPrice = _finalPriceValue;
    if (finalPrice <= 0) return;

    // Derive original: original = finalPrice / (1 - discount/100)
    final originalPrice = finalPrice / (1 - _discountPercent / 100);
    setState(() {
      _reverseResult = BusinessCalculators.calculateDiscount(
        originalPrice: originalPrice,
        discountPercent: _discountPercent,
      );
      _result = null;
      _priceController.clear();
    });
  }

  void _reset() {
    setState(() {
      _priceController.clear();
      _finalPriceController.clear();
      _discountPercent = 10.0;
      _result = null;
      _reverseResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    return buildCalculatorScaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Forward: Original → Final
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Calculate Discounted Price'),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Original Price',
                        hint: '1,000',
                        controller: _priceController,
                        prefix: symbol,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                            return 'Enter a valid price';
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount %',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.business.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.business.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${_discountPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.business,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _discountPercent,
                      min: 1,
                      max: 90,
                      divisions: 89,
                      activeColor: AppColors.business,
                      onChanged: (v) => setState(() {
                        _discountPercent = v;
                        _result = null;
                        _reverseResult = null;
                      }),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('1%',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                        Text('90%',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
            _buildResultSection(symbol, _result!, _priceValue, isReverse: false),
          ],
          const SizedBox(height: 16),
          // Reverse: Final price + discount% → original
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Reverse: Find Original Price'),
                Form(
                  key: _reverseFormKey,
                  child: AppTextField(
                    label: 'Final Price (After Discount)',
                    hint: '900',
                    controller: _finalPriceController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid final price';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_reverseResult != null) {
                        setState(() => _reverseResult = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Using discount: ${_discountPercent.toStringAsFixed(0)}% (set above)',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Find Original Price',
                  icon: Icons.search_rounded,
                  onPressed: _calculateReverse,
                  width: double.infinity,
                  color: AppColors.business,
                ),
              ],
            ),
          ),
          if (_reverseResult != null) ...[
            const SizedBox(height: 16),
            _buildResultSection(symbol, _reverseResult!, _reverseResult!.finalPrice + _reverseResult!.discountAmount,
                isReverse: true),
          ],
        ],
      ),
    );
  }

  Widget _buildResultSection(String symbol, DiscountResult r, double original,
      {required bool isReverse}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(isReverse ? 'Original Price Found' : 'Discount Result'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.business.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.business.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  isReverse ? 'Original Price' : 'Final Price',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: isReverse ? original : r.finalPrice,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.business,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Discount Amount',
                  value: NumberFormatter.formatCurrency(r.discountAmount,
                      symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'You Save',
                  value: NumberFormatter.formatCurrency(r.savings,
                      symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Breakdown',
            items: [
              ResultItem(
                label: 'Original Price',
                value: NumberFormatter.formatCurrency(original, symbol: symbol),
              ),
              ResultItem(
                label: 'Discount (${_discountPercent.toStringAsFixed(0)}%)',
                value: '- ${NumberFormatter.formatCurrency(r.discountAmount, symbol: symbol)}',
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Final Price',
                value: NumberFormatter.formatCurrency(r.finalPrice,
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

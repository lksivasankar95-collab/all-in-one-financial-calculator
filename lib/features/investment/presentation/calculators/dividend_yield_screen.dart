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

class DividendYieldScreen extends CalculatorBaseScreen {
  const DividendYieldScreen({super.key})
      : super(
          calculatorId: 'dividend_yield',
          calculatorName: 'Dividend Yield',
          category: 'Investment',
        );

  @override
  ConsumerState<DividendYieldScreen> createState() =>
      _DividendYieldScreenState();
}

class _DividendYieldScreenState extends CalculatorBaseState<DividendYieldScreen> {
  final _priceController = TextEditingController();
  final _dividendController = TextEditingController();
  final _sharesController = TextEditingController();
  double? _dividendYield;
  double? _annualIncome;
  double? _monthlyIncome;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _priceController.dispose();
    _dividendController.dispose();
    _sharesController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _dividendYield != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Stock Price':
            NumberFormatter.formatCurrency(_stockPrice, symbol: _symbol),
        'Annual Dividend Per Share':
            NumberFormatter.formatCurrency(_dividendPerShare, symbol: _symbol),
        'Number of Shares': NumberFormatter.formatNumber(_sharesCount),
      };

  @override
  Map<String, dynamic> get currentResults => _dividendYield == null
      ? {}
      : {
          'Dividend Yield': NumberFormatter.formatPercent(_dividendYield!),
          'Annual Income':
              NumberFormatter.formatCurrency(_annualIncome!, symbol: _symbol),
          'Monthly Income':
              NumberFormatter.formatCurrency(_monthlyIncome!, symbol: _symbol),
        };

  @override
  String get resultSummary => _dividendYield == null
      ? ''
      : 'Dividend Yield: ${NumberFormatter.formatPercent(_dividendYield!)} | '
          'Annual: ${NumberFormatter.formatCurrency(_annualIncome!, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _stockPrice =>
      NumberFormatter.tryParse(_priceController.text) ?? 0;
  double get _dividendPerShare =>
      NumberFormatter.tryParse(_dividendController.text) ?? 0;
  double get _sharesCount =>
      NumberFormatter.tryParse(_sharesController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final price = _stockPrice;
    final div = _dividendPerShare;
    final shares = _sharesCount;
    if (price <= 0 || div <= 0 || shares <= 0) return;

    final yield = (div / price) * 100;
    final annual = div * shares;
    final monthly = annual / 12;

    setState(() {
      _dividendYield = yield;
      _annualIncome = annual;
      _monthlyIncome = monthly;
    });
  }

  void _reset() {
    setState(() {
      _priceController.clear();
      _dividendController.clear();
      _sharesController.clear();
      _dividendYield = null;
      _annualIncome = null;
      _monthlyIncome = null;
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
                  buildSectionTitle('Stock Details'),
                  AppTextField(
                    label: 'Current Stock Price',
                    hint: '2,500',
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
                      if (_dividendYield != null) {
                        setState(() => _dividendYield = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Annual Dividend Per Share',
                    hint: '50',
                    controller: _dividendController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid dividend';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_dividendYield != null) {
                        setState(() => _dividendYield = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Number of Shares',
                    hint: '100',
                    controller: _sharesController,
                    keyboardType: TextInputType.number,
                    suffix: 'shares',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_dividendYield != null) {
                        setState(() => _dividendYield = null);
                      }
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
                ],
              ),
            ),
            if (_dividendYield != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final yield = _dividendYield!;
    final annual = _annualIncome!;
    final monthly = _monthlyIncome!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Dividend Yield',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: yield,
                  formatter: NumberFormatter.formatPercent,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Annual Dividend Income',
                  value:
                      NumberFormatter.formatCurrency(annual, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Monthly Dividend Income',
                  value:
                      NumberFormatter.formatCurrency(monthly, symbol: symbol),
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Income Summary',
            items: [
              ResultItem(
                label: 'Stock Price',
                value:
                    NumberFormatter.formatCurrency(_stockPrice, symbol: symbol),
              ),
              ResultItem(
                label: 'Dividend Per Share',
                value: NumberFormatter.formatCurrency(
                    _dividendPerShare, symbol: symbol),
              ),
              ResultItem(
                label: 'Number of Shares',
                value: NumberFormatter.formatNumber(_sharesCount),
              ),
              ResultItem(
                label: 'Dividend Yield',
                value: NumberFormatter.formatPercent(yield),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Annual Income',
                value:
                    NumberFormatter.formatCurrency(annual, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Monthly Income',
                value:
                    NumberFormatter.formatCurrency(monthly, symbol: symbol),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

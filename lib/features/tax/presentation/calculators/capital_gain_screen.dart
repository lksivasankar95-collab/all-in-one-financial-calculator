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
import '../../domain/tax_calculators.dart';

class CapitalGainScreen extends CalculatorBaseScreen {
  const CapitalGainScreen({super.key})
      : super(
          calculatorId: 'capital_gain',
          calculatorName: 'Capital Gain Tax',
          category: 'Tax',
        );

  @override
  ConsumerState<CapitalGainScreen> createState() => _CapitalGainScreenState();
}

class _CapitalGainScreenState extends CalculatorBaseState<CapitalGainScreen> {
  final _purchaseController = TextEditingController();
  final _saleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEquity = true;
  bool _isLongTerm = false;
  double _ciiRatio = 1.5; // Cost Inflation Index ratio

  CapitalGainResult? _result;

  @override
  void dispose() {
    _purchaseController.dispose();
    _saleController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _purchaseValue =>
      NumberFormatter.tryParse(_purchaseController.text) ?? 0;
  double get _saleValue =>
      NumberFormatter.tryParse(_saleController.text) ?? 0;

  String get _termLabel => _isLongTerm ? 'Long Term' : 'Short Term';
  String get _assetLabel => _isEquity ? 'Equity' : 'Debt';

  @override
  Map<String, dynamic> get currentInputs => {
        'Purchase Price':
            NumberFormatter.formatCurrency(_purchaseValue, symbol: _symbol),
        'Sale Price':
            NumberFormatter.formatCurrency(_saleValue, symbol: _symbol),
        'Asset Type': _assetLabel,
        'Term': _termLabel,
        if (!_isEquity && _isLongTerm) 'CII Ratio': _ciiRatio.toStringAsFixed(2),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Capital Gain':
              NumberFormatter.formatCurrency(_result!.gain, symbol: _symbol),
          if (!_isEquity && _isLongTerm)
            'Indexed Cost':
                NumberFormatter.formatCurrency(_result!.indexedCost, symbol: _symbol),
          'Taxable Gain':
              NumberFormatter.formatCurrency(_result!.taxableGain, symbol: _symbol),
          'Tax Rate': '${_result!.taxRate.toStringAsFixed(1)}%',
          'Tax Amount':
              NumberFormatter.formatCurrency(_result!.taxAmount, symbol: _symbol),
          'Effective Rate':
              NumberFormatter.formatPercent(_result!.effectiveRate),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '$_termLabel $_assetLabel Capital Gain: '
          '${NumberFormatter.formatCurrency(_result!.gain, symbol: _symbol)} | '
          'Tax: ${NumberFormatter.formatCurrency(_result!.taxAmount, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseValue <= 0) return;

    setState(() {
      _result = TaxCalculators.calculateCapitalGain(
        purchasePrice: _purchaseValue,
        salePrice: _saleValue,
        isLongTerm: _isLongTerm,
        isEquity: _isEquity,
        costInflationIndexRatio: _ciiRatio,
      );
    });
  }

  void _reset() {
    setState(() {
      _purchaseController.clear();
      _saleController.clear();
      _isEquity = true;
      _isLongTerm = false;
      _ciiRatio = 1.5;
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
                  buildSectionTitle('Asset Details'),
                  // Asset Type Row
                  const Text(
                    'Asset Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _ToggleBtn(
                          label: 'Equity',
                          subLabel: 'Stocks / Mutual Funds',
                          selected: _isEquity,
                          onTap: () => setState(() {
                            _isEquity = true;
                            _result = null;
                          }),
                        ),
                        _ToggleBtn(
                          label: 'Debt',
                          subLabel: 'Bonds / FD / Other',
                          selected: !_isEquity,
                          onTap: () => setState(() {
                            _isEquity = false;
                            _result = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Term Toggle
                  const Text(
                    'Holding Term',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _ToggleBtn(
                          label: 'Short Term',
                          subLabel: _isEquity ? '< 12 months' : '< 36 months',
                          selected: !_isLongTerm,
                          onTap: () => setState(() {
                            _isLongTerm = false;
                            _result = null;
                          }),
                        ),
                        _ToggleBtn(
                          label: 'Long Term',
                          subLabel: _isEquity ? '>= 12 months' : '>= 36 months',
                          selected: _isLongTerm,
                          onTap: () => setState(() {
                            _isLongTerm = true;
                            _result = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Purchase Price',
                    hint: '1,00,000',
                    controller: _purchaseController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid purchase price';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Sale Price',
                    hint: '1,50,000',
                    controller: _saleController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid sale price';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  // CII Ratio for Debt LTCG
                  if (!_isEquity && _isLongTerm) ...[
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CII Ratio (Sale CII ÷ Purchase CII)',
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
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                _ciiRatio.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _ciiRatio,
                          min: 1.0,
                          max: 4.0,
                          divisions: 60,
                          onChanged: (v) => setState(() {
                            _ciiRatio = v;
                            _result = null;
                          }),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('1.00',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textHint)),
                            Text('4.00',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textHint)),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Rates Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.info.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget 2024 Rates',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _RateInfoRow('STCG Equity', '20% (flat)'),
                        _RateInfoRow('LTCG Equity', '12.5% above ₹1.25L'),
                        _RateInfoRow('STCG Debt', 'Slab rate (shown as 30%)'),
                        _RateInfoRow('LTCG Debt', '20% with indexation'),
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
    final isGain = r.gain >= 0;
    final resultColor = isGain ? AppColors.success : AppColors.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('$_termLabel $_assetLabel Capital ${isGain ? "Gain" : "Loss"}'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: resultColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  isGain ? 'Capital Gain' : 'Capital Loss',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.gain.abs(),
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: resultColor,
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
                  label: 'Tax Rate',
                  value: '${r.taxRate.toStringAsFixed(1)}%',
                  valueColor: AppColors.tax,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Effective Rate',
                  value: NumberFormatter.formatPercent(r.effectiveRate),
                  valueColor: AppColors.tax,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Tax Computation',
            items: [
              ResultItem(
                label: 'Purchase Price',
                value: NumberFormatter.formatCurrency(_purchaseValue,
                    symbol: symbol),
              ),
              if (!_isEquity && _isLongTerm)
                ResultItem(
                  label: 'Indexed Cost (CII: ${_ciiRatio.toStringAsFixed(2)}×)',
                  value: NumberFormatter.formatCurrency(r.indexedCost,
                      symbol: symbol),
                  color: AppColors.info,
                ),
              ResultItem(
                label: 'Sale Price',
                value:
                    NumberFormatter.formatCurrency(_saleValue, symbol: symbol),
              ),
              ResultItem(
                label: isGain ? 'Capital Gain' : 'Capital Loss',
                value: NumberFormatter.formatCurrency(r.gain.abs(),
                    symbol: symbol),
                color: resultColor,
              ),
              if (_isEquity && _isLongTerm)
                const ResultItem(
                  label: 'LTCG Exemption',
                  value: '₹1,25,000',
                  color: AppColors.success,
                ),
              ResultItem(
                label: 'Taxable Gain',
                value: NumberFormatter.formatCurrency(r.taxableGain,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Tax @ ${r.taxRate.toStringAsFixed(1)}%',
                value: NumberFormatter.formatCurrency(r.taxAmount,
                    symbol: symbol),
                isHighlighted: true,
                color: AppColors.tax,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.subLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.tax.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border:
                selected ? Border.all(color: AppColors.tax, width: 1.5) : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.tax : AppColors.textSecondary,
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? AppColors.tax.withOpacity(0.7)
                      : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateInfoRow extends StatelessWidget {
  final String label;
  final String rate;

  const _RateInfoRow(this.label, this.rate);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            rate,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

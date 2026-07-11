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

class GstScreen extends CalculatorBaseScreen {
  const GstScreen({super.key})
      : super(
          calculatorId: 'gst',
          calculatorName: 'GST Calculator',
          category: 'Tax',
        );

  @override
  ConsumerState<GstScreen> createState() => _GstScreenState();
}

class _GstScreenState extends CalculatorBaseState<GstScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _gstRate = 18.0;
  bool _isInclusive = false; // false = Add GST, true = Remove GST
  GstResult? _result;

  static const List<double> _gstRates = [5.0, 12.0, 18.0, 28.0];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _amountValue =>
      NumberFormatter.tryParse(_amountController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Amount': NumberFormatter.formatCurrency(_amountValue, symbol: _symbol),
        'GST Rate': '${_gstRate.toStringAsFixed(0)}%',
        'Mode': _isInclusive ? 'Remove GST (Inclusive)' : 'Add GST (Exclusive)',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Pre-GST Amount':
              NumberFormatter.formatCurrency(_result!.preTaxAmount, symbol: _symbol),
          'GST Amount':
              NumberFormatter.formatCurrency(_result!.gstAmount, symbol: _symbol),
          'CGST': NumberFormatter.formatCurrency(_result!.cgst, symbol: _symbol),
          'SGST': NumberFormatter.formatCurrency(_result!.sgst, symbol: _symbol),
          'IGST': NumberFormatter.formatCurrency(_result!.igst, symbol: _symbol),
          'Final Amount':
              NumberFormatter.formatCurrency(_result!.postTaxAmount, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'GST ${_gstRate.toStringAsFixed(0)}% on '
          '${NumberFormatter.formatCurrency(_amountValue, symbol: _symbol)}: '
          'Final = ${NumberFormatter.formatCurrency(_result!.postTaxAmount, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amountValue;
    if (amount <= 0) return;

    setState(() {
      _result = TaxCalculators.calculateGst(
        amount: amount,
        gstRate: _gstRate,
        isInclusive: _isInclusive,
      );
    });
  }

  void _reset() {
    setState(() {
      _amountController.clear();
      _gstRate = 18.0;
      _isInclusive = false;
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
                  buildSectionTitle('GST Details'),
                  AppTextField(
                    label: 'Amount',
                    hint: '10,000',
                    controller: _amountController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  // GST Rate Selector
                  const Text(
                    'GST Rate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _gstRates.map((rate) {
                      final selected = _gstRate == rate;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _gstRate = rate;
                              _result = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.tax.withValues(alpha: 0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.tax
                                      : AppColors.border,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${rate.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? AppColors.tax
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Mode Toggle
                  const Text(
                    'Calculation Mode',
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
                        _ModeToggleBtn(
                          label: 'Add GST',
                          subLabel: 'Exclusive',
                          selected: !_isInclusive,
                          onTap: () => setState(() {
                            _isInclusive = false;
                            _result = null;
                          }),
                        ),
                        _ModeToggleBtn(
                          label: 'Remove GST',
                          subLabel: 'Inclusive',
                          selected: _isInclusive,
                          onTap: () => setState(() {
                            _isInclusive = true;
                            _result = null;
                          }),
                        ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('GST Breakdown'),
          // Highlighted Final Amount
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tax.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.tax.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  _isInclusive ? 'Pre-GST Amount' : 'Total Amount (with GST)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: _isInclusive ? r.preTaxAmount : r.postTaxAmount,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tax,
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
                  label: 'Pre-GST Amount',
                  value: NumberFormatter.formatCurrency(r.preTaxAmount,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'GST Amount',
                  value: NumberFormatter.formatCurrency(r.gstAmount,
                      symbol: symbol),
                  valueColor: AppColors.tax,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          buildSectionTitle('Tax Split'),
          ResultSummaryCard(
            title: 'Tax Components',
            items: [
              ResultItem(
                label: 'Pre-GST Amount',
                value:
                    NumberFormatter.formatCurrency(r.preTaxAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'CGST (${(_gstRate / 2).toStringAsFixed(1)}%)',
                value: NumberFormatter.formatCurrency(r.cgst, symbol: symbol),
                color: AppColors.tax,
              ),
              ResultItem(
                label: 'SGST (${(_gstRate / 2).toStringAsFixed(1)}%)',
                value: NumberFormatter.formatCurrency(r.sgst, symbol: symbol),
                color: AppColors.tax,
              ),
              ResultItem(
                label: 'IGST (${_gstRate.toStringAsFixed(0)}%) — Inter-state',
                value: NumberFormatter.formatCurrency(r.igst, symbol: symbol),
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Total GST',
                value: NumberFormatter.formatCurrency(r.gstAmount, symbol: symbol),
                color: AppColors.tax,
              ),
              ResultItem(
                label: 'Final Amount (with GST)',
                value: NumberFormatter.formatCurrency(r.postTaxAmount,
                    symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeToggleBtn extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool selected;
  final VoidCallback onTap;

  const _ModeToggleBtn({
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
            color: selected ? AppColors.tax.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.tax, width: 1.5)
                : null,
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
                  fontSize: 11,
                  color: selected ? AppColors.tax.withValues(alpha: 0.7) : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

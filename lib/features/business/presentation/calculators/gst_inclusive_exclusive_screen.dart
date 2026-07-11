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

class GstInclusiveExclusiveScreen extends CalculatorBaseScreen {
  const GstInclusiveExclusiveScreen({super.key})
      : super(
          calculatorId: 'gst_inclusive_exclusive',
          calculatorName: 'GST (In/Exclusive)',
          category: 'Business',
        );

  @override
  ConsumerState<GstInclusiveExclusiveScreen> createState() =>
      _GstInclusiveExclusiveScreenState();
}

class _GstInclusiveExclusiveScreenState
    extends CalculatorBaseState<GstInclusiveExclusiveScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isInclusive = true;
  double _gstRate = 18;
  GstResult? _result;

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
        'Mode': _isInclusive ? 'GST Inclusive' : 'GST Exclusive',
        _isInclusive ? 'Total (with GST)' : 'Base (without GST)':
            NumberFormatter.formatCurrency(_amountValue, symbol: _symbol),
        'GST Rate': '$_gstRate%',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Base Amount':
              NumberFormatter.formatCurrency(_result!.baseExclusive, symbol: _symbol),
          'GST Amount':
              NumberFormatter.formatCurrency(_result!.gstAmount, symbol: _symbol),
          'Total (incl. GST)':
              NumberFormatter.formatCurrency(_result!.totalInclusive, symbol: _symbol),
          'GST Rate': '${_result!.gstRate.toInt()}%',
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Base: ${NumberFormatter.formatCurrency(_result!.baseExclusive, symbol: _symbol)} | '
          'GST: ${NumberFormatter.formatCurrency(_result!.gstAmount, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.totalInclusive, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_amountValue <= 0) return;

    setState(() {
      if (_isInclusive) {
        _result = BusinessCalculators.calculateGstInclusive(
          totalAmount: _amountValue,
          gstRate: _gstRate,
        );
      } else {
        _result = BusinessCalculators.calculateGstExclusive(
          baseAmount: _amountValue,
          gstRate: _gstRate,
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _amountController.clear();
      _gstRate = 18;
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
                  ToggleButtons(
                    isSelected: [_isInclusive, !_isInclusive],
                    onPressed: (index) {
                      setState(() {
                        _isInclusive = index == 0;
                        _result = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.black,
                    fillColor: AppColors.business,
                    color: AppColors.business,
                    constraints: const BoxConstraints(minWidth: 160),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('GST Inclusive'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('GST Exclusive'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Input'),
                  AppTextField(
                    label: _isInclusive
                        ? 'Total Amount (incl. GST)'
                        : 'Base Amount (excl. GST)',
                    hint: _isInclusive ? '1,18,000' : '1,00,000',
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
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'GST Rate',
                    value: _gstRate,
                    min: 0,
                    max: 28,
                    divisions: 28,
                    displayValue: (v) => '${v.toInt()}%',
                    onChanged: (v) {
                      setState(() {
                        _gstRate = v;
                        _result = null;
                      });
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

    return Column(
      children: [
        // Main Results
        AppCard(
          borderColor: AppColors.business.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('GST Result'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Base Amount (excl. GST)',
                      value: NumberFormatter.formatCurrency(
                          r.baseExclusive, symbol: symbol),
                      valueColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Total Amount (incl. GST)',
                      value: NumberFormatter.formatCurrency(
                          r.totalInclusive, symbol: symbol),
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'GST Amount',
                      value: NumberFormatter.formatCurrency(
                          r.gstAmount, symbol: symbol),
                      valueColor: AppColors.business,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'GST Rate',
                      value: '${r.gstRate.toInt()}%',
                      valueColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Show both views
        AppCard(
          borderColor: AppColors.borderLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Both Views (Comparison)'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _comparisonRow('Base Amount', r.baseExclusive, symbol),
                    const SizedBox(height: 6),
                    _comparisonRow('GST @ ${r.gstRate.toInt()}%', r.gstAmount,
                        symbol, color: AppColors.business),
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 6),
                    _comparisonRow('Total (incl. GST)', r.totalInclusive,
                        symbol,
                        color: AppColors.success, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('GST Inclusive',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                          const SizedBox(height: 4),
                          if (_isInclusive)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20)
                          else
                            Text(
                              NumberFormatter.formatCurrency(
                                  r.totalInclusive,
                                  symbol: symbol),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('GST Exclusive',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                          const SizedBox(height: 4),
                          if (!_isInclusive)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 20)
                          else
                            Text(
                              NumberFormatter.formatCurrency(
                                  r.baseExclusive,
                                  symbol: symbol),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultSummaryCard(
          title: 'GST Breakdown',
          items: [
            ResultItem(
              label: 'Calculation Mode',
              value: r.mode == 'Inclusive'
                  ? 'GST Inclusive'
                  : 'GST Exclusive',
            ),
            ResultItem(
              label: 'Original Amount',
              value:
                  NumberFormatter.formatCurrency(r.originalAmount, symbol: symbol),
            ),
            ResultItem(
              label: 'Base (excl. GST)',
              value:
                  NumberFormatter.formatCurrency(r.baseExclusive, symbol: symbol),
            ),
            ResultItem(
              label: 'GST @ ${r.gstRate.toInt()}%',
              value: NumberFormatter.formatCurrency(r.gstAmount, symbol: symbol),
              color: AppColors.business,
            ),
            ResultItem(
              label: 'Total (incl. GST)',
              value:
                  NumberFormatter.formatCurrency(r.totalInclusive, symbol: symbol),
              isHighlighted: true,
              color: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _comparisonRow(String label, double value, String symbol,
      {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          NumberFormatter.formatCurrency(value, symbol: symbol),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

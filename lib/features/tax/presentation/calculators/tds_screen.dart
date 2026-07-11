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

class TdsScreen extends CalculatorBaseScreen {
  const TdsScreen({super.key})
      : super(
          calculatorId: 'tds',
          calculatorName: 'TDS Calculator',
          category: 'Tax',
        );

  @override
  ConsumerState<TdsScreen> createState() => _TdsScreenState();
}

class _TdsScreenState extends CalculatorBaseState<TdsScreen> {
  final _amountController = TextEditingController();
  final _customRateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedSection = '194A';
  double _customRate = 10;
  TdsResult? _result;

  @override
  void dispose() {
    _amountController.dispose();
    _customRateController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _amountValue =>
      NumberFormatter.tryParse(_amountController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Gross Amount':
            NumberFormatter.formatCurrency(_amountValue, symbol: _symbol),
        'TDS Section': _selectedSection,
        if (_selectedSection == 'Custom')
          'Custom Rate': NumberFormatter.formatPercent(_customRate),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Gross Amount': NumberFormatter.formatCurrency(
              _result!.grossAmount,
              symbol: _symbol),
          'TDS Amount': NumberFormatter.formatCurrency(
              _result!.tdsAmount,
              symbol: _symbol),
          'Net Amount': NumberFormatter.formatCurrency(
              _result!.netAmount,
              symbol: _symbol),
          'TDS Rate': NumberFormatter.formatPercent(_result!.tdsRate),
          'Section': _result!.section,
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'TDS ${NumberFormatter.formatCurrency(_result!.tdsAmount, symbol: _symbol)} '
          'deducted @ ${NumberFormatter.formatPercent(_result!.tdsRate)} '
          'under Section ${_result!.section} | '
          'Net: ${NumberFormatter.formatCurrency(_result!.netAmount, symbol: _symbol)}';

  bool get _isCustom => _selectedSection == 'Custom';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amountValue;
    if (amount <= 0) return;

    setState(() {
      _result = TaxCalculators.calculateTds(
        amount: amount,
        tdsSection: _selectedSection,
        customRate: _customRate,
      );
    });
  }

  void _reset() {
    setState(() {
      _amountController.clear();
      _customRateController.clear();
      _selectedSection = '194A';
      _customRate = 10;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    final sectionRate = _isCustom
        ? _customRate
        : (TaxCalculators.tdsSections[_selectedSection] ?? 0);

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
                  buildSectionTitle('Payment Details'),
                  AppTextField(
                    label: 'Gross Amount',
                    hint: '5,00,000',
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
                  const Text(
                    'TDS Section',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSection,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      suffixIcon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.tax,
                      ),
                    ),
                    items: [
                      ...TaxCalculators.tdsSections.keys.map((section) {
                        final rate = TaxCalculators.tdsSections[section]!;
                        final labels = {
                          '194A': '194A — Interest (>₹40K)',
                          '194C': '194C — Contractor',
                          '194H': '194H — Commission',
                          '194I': '194I — Rent',
                          '194J': '194J — Professional Fees',
                          '194DA': '194DA — Insurance',
                        };
                        return DropdownMenuItem(
                          value: section,
                          child: Text(
                            '${labels[section] ?? section} @ ${rate.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }),
                      const DropdownMenuItem(
                        value: 'Custom',
                        child: Text(
                          'Custom Rate',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedSection = v!;
                        _result = null;
                      });
                    },
                  ),
                  if (_isCustom) ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Custom TDS Rate (%)',
                      hint: '10',
                      controller: _customRateController,
                      suffix: '%',
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final parsed = NumberFormatter.tryParse(v);
                        if (parsed != null) {
                          _customRate = parsed;
                        }
                        if (_result != null) setState(() => _result = null);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tax.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.tax.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.tax),
                        const SizedBox(width: 8),
                        Text(
                          'Rate: ${NumberFormatter.formatPercent(sectionRate)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.tax,
                            fontWeight: FontWeight.w600,
                          ),
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
          buildSectionTitle('TDS Results — Section ${r.section}'),
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
                const Text(
                  'TDS Amount',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.tdsAmount,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tax,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rate: ${NumberFormatter.formatPercent(r.tdsRate)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Gross Amount',
                  value: NumberFormatter.formatCurrency(
                      r.grossAmount, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Net Amount',
                  value: NumberFormatter.formatCurrency(
                      r.netAmount, symbol: symbol),
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'TDS Summary',
            items: [
              ResultItem(
                label: 'Gross Amount',
                value: NumberFormatter.formatCurrency(
                    r.grossAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'TDS Section',
                value: r.section,
              ),
              ResultItem(
                label: 'TDS Rate',
                value: NumberFormatter.formatPercent(r.tdsRate),
              ),
              ResultItem(
                label: 'TDS Amount',
                value:
                    '- ${NumberFormatter.formatCurrency(r.tdsAmount, symbol: symbol)}',
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Net Amount (After TDS)',
                value: NumberFormatter.formatCurrency(
                    r.netAmount, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

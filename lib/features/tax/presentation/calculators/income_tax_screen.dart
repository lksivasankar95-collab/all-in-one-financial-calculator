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

class IncomeTaxScreen extends CalculatorBaseScreen {
  const IncomeTaxScreen({super.key})
      : super(
          calculatorId: 'income_tax',
          calculatorName: 'Income Tax',
          category: 'Tax',
        );

  @override
  ConsumerState<IncomeTaxScreen> createState() => _IncomeTaxScreenState();
}

class _IncomeTaxScreenState extends CalculatorBaseState<IncomeTaxScreen> {
  final _incomeController = TextEditingController();
  final _deductions80CController = TextEditingController();
  final _otherDeductionsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _useNewRegime = true;
  IncomeTaxResult? _result;
  IncomeTaxResult? _otherResult; // For comparison

  @override
  void dispose() {
    _incomeController.dispose();
    _deductions80CController.dispose();
    _otherDeductionsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _incomeValue =>
      NumberFormatter.tryParse(_incomeController.text) ?? 0;
  double get _ded80CValue =>
      NumberFormatter.tryParse(_deductions80CController.text) ?? 0;
  double get _otherDedValue =>
      NumberFormatter.tryParse(_otherDeductionsController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Annual Income':
            NumberFormatter.formatCurrency(_incomeValue, symbol: _symbol),
        '80C Deductions':
            NumberFormatter.formatCurrency(_ded80CValue, symbol: _symbol),
        'Other Deductions':
            NumberFormatter.formatCurrency(_otherDedValue, symbol: _symbol),
        'Regime': _useNewRegime ? 'New Regime' : 'Old Regime',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Taxable Income': NumberFormatter.formatCurrency(
              _result!.taxableIncome,
              symbol: _symbol),
          'Tax Before Rebate': NumberFormatter.formatCurrency(
              _result!.taxBeforeRebate,
              symbol: _symbol),
          'Section 87A Rebate': NumberFormatter.formatCurrency(
              _result!.rebate87A,
              symbol: _symbol),
          'Final Tax':
              NumberFormatter.formatCurrency(_result!.finalTax, symbol: _symbol),
          'Education Cess':
              NumberFormatter.formatCurrency(_result!.cess, symbol: _symbol),
          'Total Tax Payable': NumberFormatter.formatCurrency(
              _result!.totalTaxPayable,
              symbol: _symbol),
          'Effective Rate':
              NumberFormatter.formatPercent(_result!.effectiveRate),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Income: ${NumberFormatter.formatCurrency(_incomeValue, symbol: _symbol)} | '
          'Total Tax (${_result!.regime}): '
          '${NumberFormatter.formatCurrency(_result!.totalTaxPayable, symbol: _symbol)} '
          '@ ${NumberFormatter.formatPercent(_result!.effectiveRate)} effective rate';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final income = _incomeValue;
    if (income <= 0) return;

    final chosen = TaxCalculators.calculateIncomeTax(
      annualIncome: income,
      deductions80C: _ded80CValue,
      deductionsOther: _otherDedValue,
      useNewRegime: _useNewRegime,
    );
    final other = TaxCalculators.calculateIncomeTax(
      annualIncome: income,
      deductions80C: _ded80CValue,
      deductionsOther: _otherDedValue,
      useNewRegime: !_useNewRegime,
    );

    setState(() {
      _result = chosen;
      _otherResult = other;
    });
  }

  void _reset() {
    setState(() {
      _incomeController.clear();
      _deductions80CController.clear();
      _otherDeductionsController.clear();
      _useNewRegime = true;
      _result = null;
      _otherResult = null;
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
                  buildSectionTitle('Income Details — FY 2024-25'),
                  AppTextField(
                    label: 'Annual Income',
                    hint: '8,00,000',
                    controller: _incomeController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid income';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: '80C Deductions (max ₹1.5L)',
                    hint: '1,50,000',
                    controller: _deductions80CController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Other Deductions (80D, HRA, etc.)',
                    hint: '0',
                    controller: _otherDeductionsController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  // Regime Toggle
                  const Text(
                    'Tax Regime',
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
                        _RegimeToggleBtn(
                          label: 'New Regime',
                          subLabel: 'Std. ded. ₹75K',
                          selected: _useNewRegime,
                          onTap: () => setState(() {
                            _useNewRegime = true;
                            _result = null;
                          }),
                        ),
                        _RegimeToggleBtn(
                          label: 'Old Regime',
                          subLabel: 'Std. ded. ₹50K',
                          selected: !_useNewRegime,
                          onTap: () => setState(() {
                            _useNewRegime = false;
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
              if (_otherResult != null) ...[
                const SizedBox(height: 16),
                _buildComparisonSection(symbol),
              ],
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
          buildSectionTitle('${r.regime} Results'),
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
                  'Total Tax Payable',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalTaxPayable,
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
                  'Effective Rate: ${NumberFormatter.formatPercent(r.effectiveRate)}',
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
                  label: 'Taxable Income',
                  value: NumberFormatter.formatCurrency(r.taxableIncome,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Tax Before Rebate',
                  value: NumberFormatter.formatCurrency(r.taxBeforeRebate,
                      symbol: symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Tax Computation',
            items: [
              ResultItem(
                label: 'Taxable Income',
                value: NumberFormatter.formatCurrency(r.taxableIncome,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Tax Before Rebate',
                value: NumberFormatter.formatCurrency(r.taxBeforeRebate,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Section 87A Rebate',
                value: '- ${NumberFormatter.formatCurrency(r.rebate87A, symbol: symbol)}',
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Tax After Rebate',
                value: NumberFormatter.formatCurrency(r.finalTax,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Education Cess (4%)',
                value: NumberFormatter.formatCurrency(r.cess, symbol: symbol),
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Total Tax Payable',
                value: NumberFormatter.formatCurrency(r.totalTaxPayable,
                    symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Effective Tax Rate',
                value: NumberFormatter.formatPercent(r.effectiveRate),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(String symbol) {
    final chosen = _result!;
    final other = _otherResult!;
    final difference = chosen.totalTaxPayable - other.totalTaxPayable;
    final chosenSaves = difference > 0;
    final savedAmount = difference.abs();
    final betterRegime = chosenSaves ? other.regime : chosen.regime;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Regime Comparison'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (chosenSaves ? AppColors.error : AppColors.success)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (chosenSaves ? AppColors.error : AppColors.success)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  chosenSaves
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: chosenSaves ? AppColors.warning : AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    chosenSaves
                        ? '$betterRegime saves you ${NumberFormatter.formatCurrency(savedAmount, symbol: symbol)} vs ${chosen.regime}'
                        : '${chosen.regime} saves you ${NumberFormatter.formatCurrency(savedAmount, symbol: symbol)} vs ${other.regime}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: chosenSaves ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RegimeCompareCard(
                  regime: chosen.regime,
                  tax: chosen.totalTaxPayable,
                  symbol: symbol,
                  isSelected: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RegimeCompareCard(
                  regime: other.regime,
                  tax: other.totalTaxPayable,
                  symbol: symbol,
                  isSelected: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegimeToggleBtn extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool selected;
  final VoidCallback onTap;

  const _RegimeToggleBtn({
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
            border: selected ? Border.all(color: AppColors.tax, width: 1.5) : null,
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
                      ? AppColors.tax.withValues(alpha: 0.7)
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

class _RegimeCompareCard extends StatelessWidget {
  final String regime;
  final double tax;
  final String symbol;
  final bool isSelected;

  const _RegimeCompareCard({
    required this.regime,
    required this.tax,
    required this.symbol,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.tax.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.tax.withValues(alpha: 0.3) : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            regime,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.tax : AppColors.textSecondary,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tax.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Selected',
                style: TextStyle(fontSize: 9, color: AppColors.tax),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            NumberFormatter.formatCurrency(tax, symbol: symbol),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.tax : AppColors.textPrimary,
            ),
          ),
          const Text(
            'Total Tax',
            style: TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

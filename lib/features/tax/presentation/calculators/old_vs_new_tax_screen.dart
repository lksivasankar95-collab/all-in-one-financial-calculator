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

class OldVsNewTaxScreen extends CalculatorBaseScreen {
  const OldVsNewTaxScreen({super.key})
      : super(
          calculatorId: 'old_vs_new_tax',
          calculatorName: 'Old vs New Tax Regime',
          category: 'Tax',
        );

  @override
  ConsumerState<OldVsNewTaxScreen> createState() => _OldVsNewTaxScreenState();
}

class _OldVsNewTaxScreenState extends CalculatorBaseState<OldVsNewTaxScreen> {
  final _incomeController = TextEditingController();
  final _hraController = TextEditingController();
  final _section80cController = TextEditingController();
  final _section80dController = TextEditingController();
  final _npsController = TextEditingController();
  final _homeLoanController = TextEditingController();
  final _otherDeductionsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TaxRegimeResult? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    _hraController.dispose();
    _section80cController.dispose();
    _section80dController.dispose();
    _npsController.dispose();
    _homeLoanController.dispose();
    _otherDeductionsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _incomeValue =>
      NumberFormatter.tryParse(_incomeController.text) ?? 0;
  double get _hraValue =>
      NumberFormatter.tryParse(_hraController.text) ?? 0;
  double get _section80cValue =>
      NumberFormatter.tryParse(_section80cController.text) ?? 0;
  double get _section80dValue =>
      NumberFormatter.tryParse(_section80dController.text) ?? 0;
  double get _npsValue =>
      NumberFormatter.tryParse(_npsController.text) ?? 0;
  double get _homeLoanValue =>
      NumberFormatter.tryParse(_homeLoanController.text) ?? 0;
  double get _otherDedValue =>
      NumberFormatter.tryParse(_otherDeductionsController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Gross Income':
            NumberFormatter.formatCurrency(_incomeValue, symbol: _symbol),
        'HRA Exemption':
            NumberFormatter.formatCurrency(_hraValue, symbol: _symbol),
        'Section 80C':
            NumberFormatter.formatCurrency(_section80cValue, symbol: _symbol),
        'Section 80D':
            NumberFormatter.formatCurrency(_section80dValue, symbol: _symbol),
        'NPS': NumberFormatter.formatCurrency(_npsValue, symbol: _symbol),
        'Home Loan Interest':
            NumberFormatter.formatCurrency(_homeLoanValue, symbol: _symbol),
        'Other Deductions':
            NumberFormatter.formatCurrency(_otherDedValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Recommended': _result!.recommended,
          'Old Regime Tax': NumberFormatter.formatCurrency(
              _result!.oldTotalTax, symbol: _symbol),
          'New Regime Tax': NumberFormatter.formatCurrency(
              _result!.newTotalTax, symbol: _symbol),
          'Savings': NumberFormatter.formatCurrency(
              _result!.savings, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '${_result!.recommended} is better | '
          'Old: ${NumberFormatter.formatCurrency(_result!.oldTotalTax, symbol: _symbol)} | '
          'New: ${NumberFormatter.formatCurrency(_result!.newTotalTax, symbol: _symbol)} | '
          'Save: ${NumberFormatter.formatCurrency(_result!.savings, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final income = _incomeValue;
    if (income <= 0) return;

    setState(() {
      _result = TaxCalculators.calculateTaxRegimeComparison(
        grossIncome: income,
        hraExemption: _hraValue,
        section80c: _section80cValue,
        section80d: _section80dValue,
        nps: _npsValue,
        homeLoanInterest: _homeLoanValue,
        otherDeductions: _otherDedValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _incomeController.clear();
      _hraController.clear();
      _section80cController.clear();
      _section80dController.clear();
      _npsController.clear();
      _homeLoanController.clear();
      _otherDeductionsController.clear();
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
                  buildSectionTitle('Income Details'),
                  AppTextField(
                    label: 'Gross Annual Income',
                    hint: '12,00,000',
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
                  const SizedBox(height: 20),
                  buildSectionTitle('Deductions (Old Regime)'),
                  _buildDeductionField(
                    'HRA Exemption',
                    '0',
                    _hraController,
                    symbol,
                  ),
                  const SizedBox(height: 12),
                  _buildDeductionField(
                    'Section 80C (max ₹1.5L)',
                    '1,50,000',
                    _section80cController,
                    symbol,
                  ),
                  const SizedBox(height: 12),
                  _buildDeductionField(
                    'Section 80D — Health Insurance (max ₹25K)',
                    '25,000',
                    _section80dController,
                    symbol,
                  ),
                  const SizedBox(height: 12),
                  _buildDeductionField(
                    'NPS — 80CCD(1B) (max ₹50K)',
                    '50,000',
                    _npsController,
                    symbol,
                  ),
                  const SizedBox(height: 12),
                  _buildDeductionField(
                    'Home Loan Interest (max ₹2L)',
                    '2,00,000',
                    _homeLoanController,
                    symbol,
                  ),
                  const SizedBox(height: 12),
                  _buildDeductionField(
                    'Other Deductions',
                    '0',
                    _otherDeductionsController,
                    symbol,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Compare',
                          icon: Icons.compare_arrows_rounded,
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
              _buildComparisonHeader(symbol),
              const SizedBox(height: 12),
              _buildSideBySide(symbol),
              const SizedBox(height: 12),
              _buildSavingsSection(symbol),
              const SizedBox(height: 12),
              _buildDeductionsBreakdown(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionField(
    String label,
    String hint,
    TextEditingController controller,
    String symbol,
  ) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      prefix: symbol,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) {
        if (_result != null) setState(() => _result = null);
      },
    );
  }

  Widget _buildComparisonHeader(String symbol) {
    final r = _result!;
    final newIsBetter = r.newTotalTax < r.oldTotalTax;
    final betterRegime = r.recommended;
    final icon = newIsBetter
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final color = newIsBetter ? AppColors.success : AppColors.warning;

    return AppCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$betterRegime is Recommended',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saves ${NumberFormatter.formatCurrency(r.savings, symbol: symbol)} vs the other regime',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySide(String symbol) {
    final r = _result!;
    return Row(
      children: [
        Expanded(
          child: _RegimeCard(
            regime: 'Old Regime',
            taxableIncome: r.oldTaxableIncome,
            tax: r.oldTax,
            cess: r.oldCess,
            totalTax: r.oldTotalTax,
            symbol: symbol,
            isRecommended: r.recommended == 'Old Regime',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RegimeCard(
            regime: 'New Regime',
            taxableIncome: r.newTaxableIncome,
            tax: r.newTax,
            cess: r.newCess,
            totalTax: r.newTotalTax,
            symbol: symbol,
            isRecommended: r.recommended == 'New Regime',
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsSection(String symbol) {
    final r = _result!;
    final savingsPercent = r.oldTotalTax > 0
        ? (r.savings / r.oldTotalTax) * 100
        : 0.0;
    final newIsBetter = r.newTotalTax < r.oldTotalTax;

    return AppCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.savings_rounded,
                color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Savings with Recommended Regime',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormatter.formatCurrency(
                        r.savings, symbol: symbol),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '${NumberFormatter.formatPercent(savingsPercent)} less than ${newIsBetter ? "Old" : "New"} Regime',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionsBreakdown(String symbol) {
    final r = _result!;
    return ResultSummaryCard(
      title: 'Deductions Breakdown (Old Regime)',
      items: r.deductions.entries.map((e) {
        final isHighlighted = e.key == 'Standard Deduction';
        return ResultItem(
          label: e.key,
          value: NumberFormatter.formatCurrency(
              e.value, symbol: symbol),
          isHighlighted: isHighlighted,
        );
      }).toList(),
    );
  }
}

class _RegimeCard extends StatelessWidget {
  final String regime;
  final double taxableIncome;
  final double tax;
  final double cess;
  final double totalTax;
  final String symbol;
  final bool isRecommended;

  const _RegimeCard({
    required this.regime,
    required this.taxableIncome,
    required this.tax,
    required this.cess,
    required this.totalTax,
    required this.symbol,
    required this.isRecommended,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRecommended ? AppColors.success : AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: isRecommended
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended
              ? color.withValues(alpha: 0.4)
              : AppColors.border,
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  regime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isRecommended
                        ? color
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isRecommended)
                Icon(Icons.check_circle_rounded,
                    color: color, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          if (isRecommended)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Recommended',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          const Divider(color: AppColors.border, height: 16),
          _row('Taxable Income',
              NumberFormatter.formatCurrency(taxableIncome, symbol: symbol)),
          const SizedBox(height: 6),
          _row('Tax',
              NumberFormatter.formatCurrency(tax, symbol: symbol)),
          const SizedBox(height: 6),
          _row('Cess (4%)',
              NumberFormatter.formatCurrency(cess, symbol: symbol)),
          const SizedBox(height: 6),
          const Divider(color: AppColors.border, height: 12),
          _row('Total Tax',
              NumberFormatter.formatCurrency(totalTax, symbol: symbol),
              isBold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: isBold ? AppColors.tax : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

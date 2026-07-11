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

class HraScreen extends CalculatorBaseScreen {
  const HraScreen({super.key})
      : super(
          calculatorId: 'hra',
          calculatorName: 'HRA Calculator',
          category: 'Tax',
        );

  @override
  ConsumerState<HraScreen> createState() => _HraScreenState();
}

class _HraScreenState extends CalculatorBaseState<HraScreen> {
  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _rentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isMetroCity = true;
  HraResult? _result;

  @override
  void dispose() {
    _basicController.dispose();
    _hraController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _basicValue => NumberFormatter.tryParse(_basicController.text) ?? 0;
  double get _hraValue => NumberFormatter.tryParse(_hraController.text) ?? 0;
  double get _rentValue => NumberFormatter.tryParse(_rentController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Basic Salary':
            NumberFormatter.formatCurrency(_basicValue, symbol: _symbol),
        'Monthly HRA Received':
            NumberFormatter.formatCurrency(_hraValue, symbol: _symbol),
        'Monthly Rent Paid':
            NumberFormatter.formatCurrency(_rentValue, symbol: _symbol),
        'City Type': _isMetroCity ? 'Metro' : 'Non-Metro',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'HRA Exemption':
              NumberFormatter.formatCurrency(_result!.exemption, symbol: _symbol),
          'Taxable HRA':
              NumberFormatter.formatCurrency(_result!.taxableHra, symbol: _symbol),
          'Annual Tax Saving (30%)':
              NumberFormatter.formatCurrency(_result!.annualSaving, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'HRA Exemption: ${NumberFormatter.formatCurrency(_result!.exemption, symbol: _symbol)} | '
          'Annual Tax Saving: ${NumberFormatter.formatCurrency(_result!.annualSaving, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final basic = _basicValue;
    if (basic <= 0) return;

    setState(() {
      _result = TaxCalculators.calculateHra(
        basicSalary: basic,
        hraReceived: _hraValue,
        rentPaid: _rentValue,
        isMetroCity: _isMetroCity,
      );
    });
  }

  void _reset() {
    setState(() {
      _basicController.clear();
      _hraController.clear();
      _rentController.clear();
      _isMetroCity = true;
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
                  buildSectionTitle('Salary Details (Monthly)'),
                  AppTextField(
                    label: 'Monthly Basic Salary',
                    hint: '40,000',
                    controller: _basicController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid basic salary';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly HRA Received',
                    hint: '20,000',
                    controller: _hraController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid HRA amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Rent Paid',
                    hint: '18,000',
                    controller: _rentController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid rent amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  // City Type Toggle
                  const Text(
                    'City Type',
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
                        _CityToggleBtn(
                          label: 'Metro City',
                          subLabel: 'Delhi, Mumbai, Kolkata, Chennai',
                          selected: _isMetroCity,
                          onTap: () => setState(() {
                            _isMetroCity = true;
                            _result = null;
                          }),
                        ),
                        _CityToggleBtn(
                          label: 'Non-Metro',
                          subLabel: 'All other cities',
                          selected: !_isMetroCity,
                          onTap: () => setState(() {
                            _isMetroCity = false;
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
    final basicAnnual = _basicValue * 12;
    final hraAnnual = _hraValue * 12;
    final rentAnnual = _rentValue * 12;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('HRA Exemption Result'),
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
                  'HRA Exemption (Annual)',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.exemption,
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
                  label: 'Taxable HRA',
                  value: NumberFormatter.formatCurrency(r.taxableHra,
                      symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Annual Tax Saving',
                  value: NumberFormatter.formatCurrency(r.annualSaving,
                      symbol: symbol),
                  valueColor: AppColors.success,
                  subtitle: 'At 30% bracket',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildSectionTitle('Formula Breakdown — Min(A, B, C)'),
          _FormulaRow(
            label: 'A — Actual HRA Received',
            value: r.conditionA,
            symbol: symbol,
            isMin: r.conditionA <= r.conditionB && r.conditionA <= r.conditionC,
          ),
          const SizedBox(height: 8),
          _FormulaRow(
            label: 'B — ${_isMetroCity ? "50%" : "40%"} of Annual Basic (${_isMetroCity ? "Metro" : "Non-Metro"})',
            value: r.conditionB,
            symbol: symbol,
            isMin: r.conditionB <= r.conditionA && r.conditionB <= r.conditionC,
          ),
          const SizedBox(height: 8),
          _FormulaRow(
            label: 'C — Rent Paid − 10% of Basic',
            value: r.conditionC,
            symbol: symbol,
            isMin: r.conditionC <= r.conditionA && r.conditionC <= r.conditionB,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _SummaryRow('Annual Basic Salary',
                    NumberFormatter.formatCurrency(basicAnnual, symbol: symbol)),
                _SummaryRow('Annual HRA Received',
                    NumberFormatter.formatCurrency(hraAnnual, symbol: symbol)),
                _SummaryRow('Annual Rent Paid',
                    NumberFormatter.formatCurrency(rentAnnual, symbol: symbol)),
                _SummaryRow('HRA Exemption = Min(A, B, C)',
                    NumberFormatter.formatCurrency(r.exemption, symbol: symbol),
                    highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final double value;
  final String symbol;
  final bool isMin;

  const _FormulaRow({
    required this.label,
    required this.value,
    required this.symbol,
    required this.isMin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMin
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMin ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
          width: isMin ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isMin ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormatter.formatCurrency(value, symbol: symbol),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isMin ? AppColors.success : AppColors.textPrimary,
                ),
              ),
              if (isMin)
                const Text(
                  'MINIMUM',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityToggleBtn extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool selected;
  final VoidCallback onTap;

  const _CityToggleBtn({
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
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

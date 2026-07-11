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

class SalaryTakeHomeScreen extends CalculatorBaseScreen {
  const SalaryTakeHomeScreen({super.key})
      : super(
          calculatorId: 'salary_take_home',
          calculatorName: 'Salary Take Home',
          category: 'Tax',
        );

  @override
  ConsumerState<SalaryTakeHomeScreen> createState() =>
      _SalaryTakeHomeScreenState();
}

class _SalaryTakeHomeScreenState extends CalculatorBaseState<SalaryTakeHomeScreen> {
  final _ctcController = TextEditingController();
  final _conveyanceController = TextEditingController();
  final _medicalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _basicPercent = 50;
  double _hraPercent = 30;
  double _pfPercent = 12;
  bool _isNewRegime = true;
  double _professionalTax = 200;
  SalaryResult? _result;

  @override
  void dispose() {
    _ctcController.dispose();
    _conveyanceController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _ctcValue => NumberFormatter.tryParse(_ctcController.text) ?? 0;
  double get _convValue =>
      NumberFormatter.tryParse(_conveyanceController.text) ?? 0;
  double get _medValue =>
      NumberFormatter.tryParse(_medicalController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'CTC': NumberFormatter.formatCurrency(_ctcValue, symbol: _symbol),
        'Basic %': NumberFormatter.formatPercent(_basicPercent),
        'HRA % of Basic': NumberFormatter.formatPercent(_hraPercent),
        'Conveyance':
            NumberFormatter.formatCurrency(_convValue, symbol: _symbol),
        'Medical': NumberFormatter.formatCurrency(_medValue, symbol: _symbol),
        'PF %': NumberFormatter.formatPercent(_pfPercent),
        'Professional Tax':
            NumberFormatter.formatCurrency(_professionalTax, symbol: _symbol),
        'Regime': _isNewRegime ? 'New Regime' : 'Old Regime',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Monthly Take Home': NumberFormatter.formatCurrency(
              _result!.monthlyTakeHome,
              symbol: _symbol),
          'Annual Take Home': NumberFormatter.formatCurrency(
              _result!.annualTakeHome,
              symbol: _symbol),
          'Total Tax Paid': NumberFormatter.formatCurrency(
              _result!.totalTaxLiability,
              symbol: _symbol),
          'Taxable Income': NumberFormatter.formatCurrency(
              _result!.taxableIncome,
              symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Monthly Take Home: ${NumberFormatter.formatCurrency(_result!.monthlyTakeHome, symbol: _symbol)} | '
          'Annual: ${NumberFormatter.formatCurrency(_result!.annualTakeHome, symbol: _symbol)} | '
          'Tax Paid: ${NumberFormatter.formatCurrency(_result!.totalTaxLiability, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final ctc = _ctcValue;
    if (ctc <= 0) return;

    setState(() {
      _result = TaxCalculators.calculateSalaryTakeHome(
        ctc: ctc,
        basicPercent: _basicPercent,
        hraPercent: _hraPercent,
        conveyanceAllowance: _convValue,
        medicalAllowance: _medValue,
        pfPercent: _pfPercent,
        professionalTax: _professionalTax,
        isNewRegime: _isNewRegime,
      );
    });
  }

  void _reset() {
    setState(() {
      _ctcController.clear();
      _conveyanceController.clear();
      _medicalController.clear();
      _basicPercent = 50;
      _hraPercent = 30;
      _pfPercent = 12;
      _isNewRegime = true;
      _professionalTax = 200;
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
                  buildSectionTitle('Salary Structure'),
                  AppTextField(
                    label: 'Cost to Company (CTC)',
                    hint: '12,00,000',
                    controller: _ctcController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid CTC';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Basic % of CTC',
                    value: _basicPercent,
                    min: 30,
                    max: 60,
                    divisions: 30,
                    displayValue: (v) =>
                        '${v.toStringAsFixed(0)}%',
                    onChanged: (v) {
                      setState(() {
                        _basicPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  AppSliderField(
                    label: 'HRA % of Basic',
                    value: _hraPercent,
                    min: 10,
                    max: 50,
                    divisions: 40,
                    displayValue: (v) =>
                        '${v.toStringAsFixed(0)}%',
                    onChanged: (v) {
                      setState(() {
                        _hraPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Conveyance Allowance',
                          hint: '1,600',
                          controller: _conveyanceController,
                          prefix: symbol,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) {
                            if (_result != null) {
                              setState(() => _result = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          label: 'Medical Allowance',
                          hint: '1,250',
                          controller: _medicalController,
                          prefix: symbol,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) {
                            if (_result != null) {
                              setState(() => _result = null);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'PF % of Basic',
                    value: _pfPercent,
                    min: 10,
                    max: 12,
                    divisions: 2,
                    displayValue: (v) =>
                        '${v.toStringAsFixed(0)}%',
                    onChanged: (v) {
                      setState(() {
                        _pfPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Professional Tax (per month)',
                    hint: '200',
                    controller: TextEditingController(
                        text: _professionalTax.toStringAsFixed(0)),
                    prefix: symbol,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = NumberFormatter.tryParse(v);
                      if (parsed != null) _professionalTax = parsed;
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
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
                          selected: _isNewRegime,
                          onTap: () => setState(() {
                            _isNewRegime = true;
                            _result = null;
                          }),
                        ),
                        _RegimeToggleBtn(
                          label: 'Old Regime',
                          selected: !_isNewRegime,
                          onTap: () => setState(() {
                            _isNewRegime = false;
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
    final regime = _isNewRegime ? 'New Regime' : 'Old Regime';
    final basic = r.basicPay;
    final hra = r.hra;
    final pf = basic * _pfPercent / 100;

    return Column(
      children: [
        // Monthly Take Home (big number)
        AppCard(
          child: Column(
            children: [
              buildSectionTitle('$regime — Take Home'),
              AnimatedResultValue(
                value: r.monthlyTakeHome,
                formatter: (v) =>
                    NumberFormatter.formatCurrency(v, symbol: symbol),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tax,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Monthly Take Home',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Annual Take Home & Total Tax Paid
        Row(
          children: [
            Expanded(
              child: ResultCard(
                label: 'Annual Take Home',
                value: NumberFormatter.formatCurrency(
                    r.annualTakeHome, symbol: symbol),
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ResultCard(
                label: 'Total Tax Paid',
                value: NumberFormatter.formatCurrency(
                    r.totalTaxLiability, symbol: symbol),
                valueColor: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Salary Breakdown
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Salary Breakdown'),
              _buildBreakdownItem(
                  'Basic Pay', basic, symbol, AppColors.tax),
              _buildBreakdownItem('HRA', hra, symbol, null),
              _buildBreakdownItem(
                  'Conveyance Allowance', _convValue, symbol, null),
              _buildBreakdownItem(
                  'Medical Allowance', _medValue, symbol, null),
              _buildBreakdownItem(
                  'Special Allowance',
                  r.grossAnnualSalary - basic - hra - _convValue - _medValue,
                  symbol,
                  null),
              const Divider(color: AppColors.border, height: 24),
              _buildBreakdownItem(
                  'Total Gross', r.grossAnnualSalary, symbol, AppColors.tax,
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Deductions
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Deductions'),
              _buildBreakdownItem(
                  'PF (${_pfPercent.toStringAsFixed(0)}% of Basic)',
                  pf,
                  symbol,
                  null),
              _buildBreakdownItem(
                  'Professional Tax',
                  _professionalTax * 12,
                  symbol,
                  null),
              _buildBreakdownItem(
                  'Standard Deduction', 50000, symbol, null),
              const Divider(color: AppColors.border, height: 24),
              _buildBreakdownItem(
                  'Total Deductions',
                  r.grossDeductions,
                  symbol,
                  AppColors.warning,
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tax Breakdown
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Tax Computation'),
              _buildBreakdownItem(
                  'Taxable Income', r.taxableIncome, symbol, null),
              _buildBreakdownItem(
                  'Income Tax', r.taxAmount, symbol, AppColors.warning),
              _buildBreakdownItem(
                  'Health & Education Cess (4%)',
                  r.cessAmount,
                  symbol,
                  null),
              const Divider(color: AppColors.border, height: 24),
              _buildBreakdownItem(
                  'Total Tax Liability',
                  r.totalTaxLiability,
                  symbol,
                  AppColors.error,
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Summary card
        ResultSummaryCard(
          title: 'Full Summary',
          items: [
            ResultItem(
              label: 'Monthly Take Home',
              value: NumberFormatter.formatCurrency(
                  r.monthlyTakeHome, symbol: symbol),
              isHighlighted: true,
            ),
            ResultItem(
              label: 'Annual Take Home',
              value: NumberFormatter.formatCurrency(
                  r.annualTakeHome, symbol: symbol),
              isHighlighted: true,
            ),
            ResultItem(
              label: 'Total Tax Paid',
              value: NumberFormatter.formatCurrency(
                  r.totalTaxLiability, symbol: symbol),
              color: AppColors.warning,
            ),
            ResultItem(
              label: 'Tax Regime',
              value: regime,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
      String label, double value, String symbol, Color? color,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(value, symbol: symbol),
            style: TextStyle(
              fontSize: isBold ? 15 : 14,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegimeToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RegimeToggleBtn({
    required this.label,
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
            color:
                selected ? AppColors.tax.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border:
                selected ? Border.all(color: AppColors.tax, width: 1.5) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.tax : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

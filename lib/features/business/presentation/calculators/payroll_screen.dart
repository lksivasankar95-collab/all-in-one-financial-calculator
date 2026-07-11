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

class PayrollScreen extends CalculatorBaseScreen {
  const PayrollScreen({super.key})
      : super(
          calculatorId: 'payroll',
          calculatorName: 'Payroll Calculator',
          category: 'Business',
        );

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends CalculatorBaseState<PayrollScreen> {
  final _grossSalaryController = TextEditingController();
  final _professionalTaxController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _basicPercent = 40;
  double _hraPercent = 40;
  bool _isEligibleForEsi = false;
  PayrollResult? _result;

  @override
  void dispose() {
    _grossSalaryController.dispose();
    _professionalTaxController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _grossSalaryValue =>
      NumberFormatter.tryParse(_grossSalaryController.text) ?? 0;
  double get _professionalTaxValue =>
      NumberFormatter.tryParse(_professionalTaxController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Gross Monthly Salary':
            NumberFormatter.formatCurrency(_grossSalaryValue, symbol: _symbol),
        'Basic %': '$_basicPercent%',
        'HRA % of Basic': '$_hraPercent%',
        'ESI Eligible': _isEligibleForEsi ? 'Yes' : 'No',
        'Professional Tax':
            NumberFormatter.formatCurrency(_professionalTaxValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Basic Pay':
              NumberFormatter.formatCurrency(_result!.basicPay, symbol: _symbol),
          'HRA':
              NumberFormatter.formatCurrency(_result!.hra, symbol: _symbol),
          'Net Salary':
              NumberFormatter.formatCurrency(_result!.netSalary, symbol: _symbol),
          'CTC (Annual)':
              NumberFormatter.formatCurrency(_result!.ctc, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Gross: ${NumberFormatter.formatCurrency(_grossSalaryValue, symbol: _symbol)} | '
          'Net: ${NumberFormatter.formatCurrency(_result!.netSalary, symbol: _symbol)} | '
          'CTC: ${NumberFormatter.formatCurrency(_result!.ctc, symbol: _symbol)} p.a.';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_grossSalaryValue <= 0) return;

    setState(() {
      _result = BusinessCalculators.calculatePayroll(
        grossSalary: _grossSalaryValue,
        basicPercent: _basicPercent,
        hraPercent: _hraPercent,
        isEligibleForEsi: _isEligibleForEsi,
        professionalTax: _professionalTaxValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _grossSalaryController.clear();
      _professionalTaxController.clear();
      _basicPercent = 40;
      _hraPercent = 40;
      _isEligibleForEsi = false;
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
                  buildSectionTitle('Salary Inputs'),
                  AppTextField(
                    label: 'Gross Monthly Salary',
                    hint: '50,000',
                    controller: _grossSalaryController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid salary';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Basic Pay % of Gross',
                    value: _basicPercent,
                    min: 30,
                    max: 60,
                    divisions: 30,
                    displayValue: (v) => '${v.toInt()}%',
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
                    displayValue: (v) => '${v.toInt()}%',
                    onChanged: (v) {
                      setState(() {
                        _hraPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Professional Tax (Monthly)',
                    hint: '200',
                    controller: _professionalTaxController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ESI Eligible',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Switch(
                        value: _isEligibleForEsi,
                        onChanged: (v) {
                          setState(() {
                            _isEligibleForEsi = v;
                            _result = null;
                          });
                        },
                        activeThumbColor: AppColors.primary,
                        inactiveThumbColor: AppColors.textHint,
                        inactiveTrackColor: AppColors.surface,
                      ),
                    ],
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
        // Top Summary
        AppCard(
          borderColor: AppColors.business.withValues(alpha: 0.3),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Net Salary',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedResultValue(
                          value: r.netSalary,
                          formatter: (v) =>
                              NumberFormatter.formatCurrency(v, symbol: symbol),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'per month',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.business.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.business.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'CTC',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          NumberFormatter.formatCurrency(r.ctc, symbol: symbol),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.business,
                          ),
                        ),
                        const Text(
                          'per annum',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Earnings Section
        AppCard(
          borderColor: AppColors.success.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Earnings'),
              const SizedBox(height: 8),
              _payrollLine('Basic Pay', r.basicPay, symbol, AppColors.success),
              _payrollLine('House Rent Allowance (HRA)', r.hra, symbol,
                  AppColors.success),
              _payrollLine('Conveyance Allowance', r.conveyanceAllowance,
                  symbol, AppColors.success),
              _payrollLine('Medical Allowance', r.medicalAllowance, symbol,
                  AppColors.success),
              _payrollLine('Special Allowance', r.specialAllowance, symbol,
                  AppColors.success),
              const Divider(height: 20, color: AppColors.border),
              _payrollLine('Gross Salary', r.grossSalary, symbol,
                  AppColors.primary,
                  isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Deductions Section
        AppCard(
          borderColor: AppColors.error.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Deductions'),
              const SizedBox(height: 8),
              _payrollLine('Employee PF', r.pfEmployee, symbol, AppColors.error),
              if (r.esiEmployee > 0)
                _payrollLine(
                    'Employee ESI', r.esiEmployee, symbol, AppColors.error),
              _payrollLine(
                  'Professional Tax', r.professionalTax, symbol, AppColors.error),
              const Divider(height: 20, color: AppColors.border),
              _payrollLine(
                  'Total Deductions', r.grossDeductions, symbol, AppColors.error,
                  isBold: true),
              const Divider(height: 20, color: AppColors.border),
              _payrollLine('Net Salary (Take Home)', r.netSalary, symbol,
                  AppColors.primary,
                  isBold: true, isLarge: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Employer Contributions
        if (r.pfEmployer > 0 || r.esiEmployer > 0)
          AppCard(
            borderColor: AppColors.warning.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Employer Contributions'),
                const SizedBox(height: 8),
                _payrollLine(
                    'Employer PF', r.pfEmployer, symbol, AppColors.warning),
                if (r.esiEmployer > 0)
                  _payrollLine('Employer ESI', r.esiEmployer, symbol,
                      AppColors.warning),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // Summary Card
        ResultSummaryCard(
          title: 'Payroll Summary',
          items: [
            ResultItem(
              label: 'Gross Monthly Salary',
              value: NumberFormatter.formatCurrency(
                  r.grossSalary, symbol: symbol),
            ),
            ResultItem(
              label: 'Basic Pay',
              value: NumberFormatter.formatCurrency(r.basicPay, symbol: symbol),
              color: AppColors.success,
            ),
            ResultItem(
              label: 'HRA',
              value: NumberFormatter.formatCurrency(r.hra, symbol: symbol),
              color: AppColors.success,
            ),
            ResultItem(
              label: 'Total Deductions',
              value: NumberFormatter.formatCurrency(
                  r.grossDeductions, symbol: symbol),
              color: AppColors.error,
            ),
            ResultItem(
              label: 'Net Salary (Monthly)',
              value:
                  NumberFormatter.formatCurrency(r.netSalary, symbol: symbol),
              isHighlighted: true,
              color: AppColors.primary,
            ),
            ResultItem(
              label: 'CTC (Annual)',
              value: NumberFormatter.formatCurrency(r.ctc, symbol: symbol),
              isHighlighted: true,
              color: AppColors.business,
            ),
          ],
        ),
      ],
    );
  }

  Widget _payrollLine(String label, double value, String symbol, Color color,
      {bool isBold = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 14 : 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            NumberFormatter.formatCurrency(value, symbol: symbol),
            style: TextStyle(
              fontSize: isLarge ? 20 : 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

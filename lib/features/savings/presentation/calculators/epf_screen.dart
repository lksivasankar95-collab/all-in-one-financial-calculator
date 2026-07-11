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
import '../../domain/savings_calculators.dart';

class EpfScreen extends CalculatorBaseScreen {
  const EpfScreen({super.key})
      : super(
          calculatorId: 'epf',
          calculatorName: 'EPF Calculator',
          category: 'Savings',
        );

  @override
  ConsumerState<EpfScreen> createState() => _EpfScreenState();
}

class _EpfScreenState extends CalculatorBaseState<EpfScreen> {
  final _salaryController = TextEditingController();
  double _employeeContrib = 12.0;
  double _employerContrib = 12.0;
  double _annualRate = 8.15;
  int _years = 10;
  EpfResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Basic Salary': NumberFormatter.formatCurrency(_salaryValue, symbol: _symbol),
        'Employee Contribution': NumberFormatter.formatPercent(_employeeContrib),
        'Employer Contribution': NumberFormatter.formatPercent(_employerContrib),
        'Annual Rate': NumberFormatter.formatPercent(_annualRate),
        'Years of Service': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Maturity Amount': NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol),
          'Employee Contribution': NumberFormatter.formatCurrency(_result!.totalEmployeeContrib, symbol: _symbol),
          'Employer Contribution': NumberFormatter.formatCurrency(_result!.totalEmployerContrib, symbol: _symbol),
          'Total Interest': NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'EPF on ${NumberFormatter.formatCurrency(_salaryValue, symbol: _symbol)} basic for $_years yrs @ ${_annualRate.toStringAsFixed(1)}% = '
          '${NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _salaryValue => NumberFormatter.tryParse(_salaryController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final salary = _salaryValue;
    if (salary <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateEpf(
        basicSalary: salary,
        employeeContrib: _employeeContrib,
        employerContrib: _employerContrib,
        annualRate: _annualRate,
        years: _years,
      );
    });
  }

  void _reset() {
    setState(() {
      _salaryController.clear();
      _employeeContrib = 12.0;
      _employerContrib = 12.0;
      _annualRate = 8.15;
      _years = 10;
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
                  buildSectionTitle('Salary & Contribution Details'),
                  AppTextField(
                    label: 'Basic Salary (Monthly)',
                    hint: '30,000',
                    controller: _salaryController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Employee Contribution',
                    value: _employeeContrib,
                    min: 12,
                    max: 20,
                    divisions: 16,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _employeeContrib = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Employer Contribution',
                    value: _employerContrib,
                    min: 3,
                    max: 12,
                    divisions: 18,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _employerContrib = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.savings.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.savings.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Monthly Contribution',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(_employeeContrib + _employerContrib).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Interest Rate',
                    value: _annualRate,
                    min: 6,
                    max: 12,
                    divisions: 60,
                    displayValue: (v) => '${v.toStringAsFixed(2)}%',
                    onChanged: (v) => setState(() {
                      _annualRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Years of Service',
                    value: _years.toDouble(),
                    min: 1,
                    max: 35,
                    divisions: 34,
                    displayValue: (v) => '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) => setState(() {
                      _years = v.toInt();
                      _result = null;
                    }),
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
                          color: AppColors.savings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.savings,
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
    final double monthlyEmployee = _salaryValue * _employeeContrib / 100;
    final double monthlyEmployer = _salaryValue * _employerContrib / 100;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'EPF Maturity Amount',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.maturityAmount,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.savings,
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
                  label: 'Employee Contribution',
                  value: NumberFormatter.formatCurrency(r.totalEmployeeContrib, symbol: symbol),
                  subtitle: '${NumberFormatter.formatCurrency(monthlyEmployee, symbol: symbol)}/mo',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Employer Contribution',
                  value: NumberFormatter.formatCurrency(r.totalEmployerContrib, symbol: symbol),
                  subtitle: '${NumberFormatter.formatCurrency(monthlyEmployer, symbol: symbol)}/mo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Total Interest Earned',
            value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
            isHighlighted: true,
            valueColor: AppColors.savings,
            subtitle: 'Over $_years years at ${_annualRate.toStringAsFixed(2)}% p.a.',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Basic Salary',
                value: NumberFormatter.formatCurrency(_salaryValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Employee Contrib. (${_employeeContrib.toStringAsFixed(0)}%)',
                value: NumberFormatter.formatCurrency(r.totalEmployeeContrib, symbol: symbol),
              ),
              ResultItem(
                label: 'Employer Contrib. (${_employerContrib.toStringAsFixed(0)}%)',
                value: NumberFormatter.formatCurrency(r.totalEmployerContrib, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Interest',
                value: NumberFormatter.formatCurrency(r.totalInterest, symbol: symbol),
                color: AppColors.savings,
              ),
              ResultItem(
                label: 'Maturity Amount',
                value: NumberFormatter.formatCurrency(r.maturityAmount, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

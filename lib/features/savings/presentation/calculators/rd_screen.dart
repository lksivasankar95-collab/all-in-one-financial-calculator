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

class RdScreen extends CalculatorBaseScreen {
  const RdScreen({super.key})
      : super(
          calculatorId: 'rd',
          calculatorName: 'RD Calculator',
          category: 'Savings',
        );

  @override
  ConsumerState<RdScreen> createState() => _RdScreenState();
}

class _RdScreenState extends CalculatorBaseState<RdScreen> {
  final _monthlyController = TextEditingController();
  double _annualRate = 6.5;
  int _years = 1;
  int _months = 0;
  RdResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Deposit': NumberFormatter.formatCurrency(_monthlyValue, symbol: _symbol),
        'Annual Rate': NumberFormatter.formatPercent(_annualRate),
        'Duration': _durationLabel,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Maturity Amount': NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol),
          'Total Deposited': NumberFormatter.formatCurrency(_result!.totalDeposited, symbol: _symbol),
          'Interest Earned': NumberFormatter.formatCurrency(_result!.interestEarned, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'RD of ${NumberFormatter.formatCurrency(_monthlyValue, symbol: _symbol)}/mo '
          'for $_durationLabel @ ${_annualRate.toStringAsFixed(1)}% = '
          '${NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _monthlyValue => NumberFormatter.tryParse(_monthlyController.text) ?? 0;

  String get _durationLabel {
    if (_years == 0 && _months == 0) return '0 mo';
    if (_years == 0) return '$_months mo';
    if (_months == 0) return '$_years ${_years == 1 ? "yr" : "yrs"}';
    return '$_years yr${_years > 1 ? "s" : ""} $_months mo';
  }

  int get _totalMonths => _years * 12 + _months;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_totalMonths == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a duration greater than 0')),
      );
      return;
    }
    final monthly = _monthlyValue;
    if (monthly <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateRd(
        monthlyDeposit: monthly,
        annualRate: _annualRate,
        years: _years,
        months: _months,
      );
    });
  }

  void _reset() {
    setState(() {
      _monthlyController.clear();
      _annualRate = 6.5;
      _years = 1;
      _months = 0;
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
                  buildSectionTitle('Deposit Details'),
                  AppTextField(
                    label: 'Monthly Deposit',
                    hint: '5,000',
                    controller: _monthlyController,
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
                    label: 'Annual Interest Rate',
                    value: _annualRate,
                    min: 1,
                    max: 12,
                    divisions: 110,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Duration (Years)',
                    value: _years.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    displayValue: (v) =>
                        v.toInt() == 0 ? '0 yrs' : '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) => setState(() {
                      _years = v.toInt();
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Duration (Months)',
                    value: _months.toDouble(),
                    min: 0,
                    max: 11,
                    divisions: 11,
                    displayValue: (v) => '${v.toInt()} mo',
                    onChanged: (v) => setState(() {
                      _months = v.toInt();
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
    final double monthlyInterest =
        _totalMonths > 0 ? r.interestEarned / _totalMonths : 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Maturity Amount',
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
                  label: 'Total Deposited',
                  value: NumberFormatter.formatCurrency(r.totalDeposited, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Interest Earned',
                  value: NumberFormatter.formatCurrency(r.interestEarned, symbol: symbol),
                  valueColor: AppColors.savings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Average Monthly Interest',
            value: NumberFormatter.formatCurrency(monthlyInterest, symbol: symbol),
            isHighlighted: true,
            subtitle: 'Over $_durationLabel at ${_annualRate.toStringAsFixed(1)}% p.a.',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Monthly Deposit',
                value: NumberFormatter.formatCurrency(_monthlyValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Months',
                value: '$_totalMonths months',
              ),
              ResultItem(
                label: 'Total Deposited',
                value: NumberFormatter.formatCurrency(r.totalDeposited, symbol: symbol),
              ),
              ResultItem(
                label: 'Interest Earned',
                value: NumberFormatter.formatCurrency(r.interestEarned, symbol: symbol),
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

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
import '../../domain/loan_calculators.dart';

class HomeLoanScreen extends CalculatorBaseScreen {
  const HomeLoanScreen({super.key})
      : super(
          calculatorId: 'home_loan',
          calculatorName: 'Home Loan Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<HomeLoanScreen> createState() => _HomeLoanScreenState();
}

class _HomeLoanScreenState extends CalculatorBaseState<HomeLoanScreen> {
  final _loanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _annualRate = 8.5;
  int _tenureYears = 20;
  double _processingFeePercent = 1.0;

  HomeLoanResult? _result;
  bool _showAmortization = false;

  @override
  void dispose() {
    _loanController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _loanValue =>
      NumberFormatter.tryParse(_loanController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Loan Amount':
          NumberFormatter.formatCurrency(_loanValue, symbol: symbol),
      'Interest Rate': NumberFormatter.formatPercent(_annualRate),
      'Tenure': '$_tenureYears years',
      'Processing Fee': NumberFormatter.formatPercent(_processingFeePercent),
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'EMI':
          NumberFormatter.formatCurrency(_result!.emi, symbol: symbol),
      'Total Interest':
          NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol),
      'Total Amount':
          NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol),
      'Processing Fee':
          NumberFormatter.formatCurrency(_result!.processingFee, symbol: symbol),
      'Net Disbursement':
          NumberFormatter.formatCurrency(_result!.netDisbursement, symbol: symbol),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'EMI: ${NumberFormatter.formatCurrency(_result!.emi, symbol: symbol)}/mo | '
        'Interest: ${NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol)} | '
        'Net: ${NumberFormatter.formatCurrency(_result!.netDisbursement, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final loan = _loanValue;
    if (loan <= 0) return;

    setState(() {
      _result = LoanCalculators.calculateHomeLoan(
        principal: loan,
        annualRate: _annualRate,
        years: _tenureYears,
        processingFeePercent: _processingFeePercent,
      );
      _showAmortization = false;
    });
  }

  void _reset() {
    setState(() {
      _loanController.clear();
      _annualRate = 8.5;
      _tenureYears = 20;
      _processingFeePercent = 1.0;
      _result = null;
      _showAmortization = false;
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
                  buildSectionTitle('Loan Details'),
                  AppTextField(
                    label: 'Loan Amount',
                    hint: '5000000',
                    controller: _loanController,
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
                  AppSliderField(
                    label: 'Interest Rate',
                    value: _annualRate,
                    min: 5,
                    max: 15,
                    divisions: 100,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _annualRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Loan Tenure',
                    value: _tenureYears.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 25,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _tenureYears = v.toInt();
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Processing Fee',
                    value: _processingFeePercent,
                    min: 0,
                    max: 3,
                    divisions: 60,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _processingFeePercent = v;
                        if (_result != null) _result = null;
                      });
                    },
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
              const SizedBox(height: 16),
              _buildAmortizationSection(symbol),
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
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Monthly EMI',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.emi,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.loan,
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
                  label: 'Total Interest',
                  value: NumberFormatter.formatCurrency(
                      r.totalInterest, symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Payment',
                  value: NumberFormatter.formatCurrency(
                      r.totalAmount, symbol: symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Processing Fee',
                  value: NumberFormatter.formatCurrency(
                      r.processingFee, symbol: symbol),
                  valueColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Net Disbursement',
                  value: NumberFormatter.formatCurrency(
                      r.netDisbursement, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Loan Amount',
                value: NumberFormatter.formatCurrency(
                    r.principalAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Processing Fee',
                value: NumberFormatter.formatCurrency(
                    r.processingFee, symbol: symbol),
                color: AppColors.warning,
              ),
              ResultItem(
                label: 'Net Disbursement',
                value: NumberFormatter.formatCurrency(
                    r.netDisbursement, symbol: symbol),
                isHighlighted: true,
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(
                    r.emi, symbol: symbol),
                isHighlighted: true,
                color: AppColors.loan,
              ),
              ResultItem(
                label: 'Total Interest',
                value: NumberFormatter.formatCurrency(
                    r.totalInterest, symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Total Payment',
                value: NumberFormatter.formatCurrency(
                    r.totalAmount, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmortizationSection(String symbol) {
    final rows = _result!.schedule.take(12).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _showAmortization = !_showAmortization),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildSectionTitle('Amortization Schedule'),
                Icon(
                  _showAmortization
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
          if (_showAmortization) ...[
            const SizedBox(height: 4),
            const Text(
              'Showing first 12 months',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                columnSpacing: 14,
                headingTextStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                columns: const [
                  DataColumn(label: Text('Mo')),
                  DataColumn(label: Text('EMI')),
                  DataColumn(label: Text('Principal')),
                  DataColumn(label: Text('Interest')),
                  DataColumn(label: Text('Balance')),
                ],
                rows: rows.map((row) {
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (row.month % 2 == 0) {
                        return AppColors.card.withValues(alpha: 0.5);
                      }
                      return null;
                    }),
                    cells: [
                      DataCell(Text(row.month.toString())),
                      DataCell(Text(
                          NumberFormatter.formatCompact(row.emi, symbol: symbol))),
                      DataCell(Text(NumberFormatter.formatCompact(
                          row.principal, symbol: symbol))),
                      DataCell(Text(NumberFormatter.formatCompact(
                          row.interest, symbol: symbol))),
                      DataCell(Text(NumberFormatter.formatCompact(
                          row.balance, symbol: symbol))),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (_result!.schedule.length > 12) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '... ${_result!.schedule.length - 12} more months',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

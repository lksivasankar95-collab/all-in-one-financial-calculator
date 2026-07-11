import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
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

class EmiScreen extends CalculatorBaseScreen {
  const EmiScreen({super.key})
      : super(
          calculatorId: 'emi',
          calculatorName: 'EMI Calculator',
          category: 'Loan',
        );

  @override
  ConsumerState<EmiScreen> createState() => _EmiScreenState();
}

class _EmiScreenState extends CalculatorBaseState<EmiScreen> {
  final _principalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _annualRate = 8.5;
  int _tenureYears = 20;
  bool _tenureInMonths = false;
  int _tenureMonths = 240;

  EmiResult? _result;
  List<AmortizationRow> _schedule = [];
  bool _showAmortization = false;
  int _touchedIndex = -1;

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _principalValue =>
      NumberFormatter.tryParse(_principalController.text) ?? 0;

  int get _totalMonths =>
      _tenureInMonths ? _tenureMonths : _tenureYears * 12;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Loan Amount':
          NumberFormatter.formatCurrency(_principalValue, symbol: symbol),
      'Annual Interest Rate': NumberFormatter.formatPercent(_annualRate),
      'Loan Tenure': _tenureInMonths
          ? '$_tenureMonths months'
          : '$_tenureYears years',
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    final interestPct = _result!.totalAmount > 0
        ? (_result!.totalInterest / _result!.totalAmount) * 100
        : 0.0;
    return {
      'Monthly EMI':
          NumberFormatter.formatCurrency(_result!.emi, symbol: symbol),
      'Principal Amount':
          NumberFormatter.formatCurrency(_result!.principalAmount, symbol: symbol),
      'Total Interest':
          NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol),
      'Total Amount':
          NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol),
      'Interest % of Total':
          NumberFormatter.formatPercent(interestPct),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'EMI: ${NumberFormatter.formatCurrency(_result!.emi, symbol: symbol)}/mo | '
        'Total: ${NumberFormatter.formatCurrency(_result!.totalAmount, symbol: symbol)} | '
        'Interest: ${NumberFormatter.formatCurrency(_result!.totalInterest, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final principal = _principalValue;
    if (principal <= 0) return;

    final int n = _totalMonths;
    final double r = _annualRate / 1200;

    double emi;
    if (r == 0) {
      emi = principal / n;
    } else {
      final double factor = pow(1 + r, n).toDouble();
      emi = (principal * r * factor) / (factor - 1);
    }

    final double totalAmount = emi * n;
    final double totalInterest = totalAmount - principal;

    // Build amortization schedule manually for exact month count
    final List<AmortizationRow> schedule = [];
    double balance = principal;
    for (int month = 1; month <= n; month++) {
      final double interestPart = balance * r;
      final double principalPart = emi - interestPart;
      balance -= principalPart;
      if (balance < 0) balance = 0;
      schedule.add(AmortizationRow(
        month: month,
        emi: emi,
        principal: principalPart,
        interest: interestPart,
        balance: balance,
      ));
    }

    setState(() {
      _result = EmiResult(
        emi: emi,
        totalAmount: totalAmount,
        totalInterest: totalInterest,
        principalAmount: principal,
      );
      _schedule = schedule;
      _showAmortization = false;
      _touchedIndex = -1;
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _annualRate = 8.5;
      _tenureYears = 20;
      _tenureMonths = 240;
      _tenureInMonths = false;
      _result = null;
      _schedule = [];
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
                    hint: '2500000',
                    controller: _principalController,
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
                    label: 'Annual Interest Rate',
                    value: _annualRate,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _annualRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Loan Tenure',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _TenureToggle(
                        inMonths: _tenureInMonths,
                        onChanged: (inMonths) {
                          setState(() {
                            _tenureInMonths = inMonths;
                            if (!inMonths) {
                              _tenureYears =
                                  (_tenureMonths / 12).round().clamp(1, 30);
                            } else {
                              _tenureMonths =
                                  (_tenureYears * 12).clamp(1, 360);
                            }
                            if (_result != null) _result = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!_tenureInMonths)
                    AppSliderField(
                      label: '',
                      value: _tenureYears.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      displayValue: (v) =>
                          '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                      onChanged: (v) {
                        setState(() {
                          _tenureYears = v.toInt();
                          _tenureMonths = _tenureYears * 12;
                          if (_result != null) _result = null;
                        });
                      },
                    )
                  else
                    AppSliderField(
                      label: '',
                      value: _tenureMonths.toDouble(),
                      min: 1,
                      max: 360,
                      divisions: 359,
                      displayValue: (v) =>
                          '${v.toInt()} ${v.toInt() == 1 ? "mo" : "mos"}',
                      onChanged: (v) {
                        setState(() {
                          _tenureMonths = v.toInt();
                          _tenureYears =
                              (_tenureMonths / 12).ceil().clamp(1, 30);
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
              _buildPieChart(),
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
    final interestPct =
        r.totalAmount > 0 ? (r.totalInterest / r.totalAmount) * 100 : 0.0;

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
                  label: 'Principal Amount',
                  value: NumberFormatter.formatCurrency(r.principalAmount,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Interest',
                  value: NumberFormatter.formatCurrency(r.totalInterest,
                      symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Total Amount Payable',
            value:
                NumberFormatter.formatCurrency(r.totalAmount, symbol: symbol),
            isHighlighted: true,
            subtitle:
                'Over ${_tenureInMonths ? "$_tenureMonths months" : "$_tenureYears years"} @ ${_annualRate.toStringAsFixed(1)}% p.a.',
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Interest as % of Total',
            value: NumberFormatter.formatPercent(interestPct),
            valueColor: AppColors.warning,
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Loan Amount',
                value: NumberFormatter.formatCurrency(r.principalAmount,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Total Interest',
                value: NumberFormatter.formatCurrency(r.totalInterest,
                    symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Total Payable',
                value: NumberFormatter.formatCurrency(r.totalAmount,
                    symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(r.emi, symbol: symbol),
                isHighlighted: true,
                color: AppColors.loan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final r = _result!;
    final principalPct =
        r.totalAmount > 0 ? (r.principalAmount / r.totalAmount) * 100 : 50.0;
    final interestPct = 100.0 - principalPct;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Principal vs Interest'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 52,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: [
                        PieChartSectionData(
                          value: r.principalAmount,
                          color: AppColors.loan,
                          title: _touchedIndex == 0
                              ? '${principalPct.toStringAsFixed(1)}%'
                              : '',
                          radius: _touchedIndex == 0 ? 60 : 52,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: r.totalInterest,
                          color: AppColors.error.withValues(alpha: 0.75),
                          title: _touchedIndex == 1
                              ? '${interestPct.toStringAsFixed(1)}%'
                              : '',
                          radius: _touchedIndex == 1 ? 60 : 52,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieLegend(
                      color: AppColors.loan,
                      label: 'Principal',
                      value: '${principalPct.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 14),
                    _PieLegend(
                      color: AppColors.error.withValues(alpha: 0.75),
                      label: 'Interest',
                      value: '${interestPct.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmortizationSection(String symbol) {
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
            _buildAmortizationTable(symbol),
          ],
        ],
      ),
    );
  }

  Widget _buildAmortizationTable(String symbol) {
    final rows = _schedule.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  DataCell(Text(NumberFormatter.formatCompact(row.principal,
                      symbol: symbol))),
                  DataCell(Text(NumberFormatter.formatCompact(row.interest,
                      symbol: symbol))),
                  DataCell(Text(NumberFormatter.formatCompact(row.balance,
                      symbol: symbol))),
                ],
              );
            }).toList(),
          ),
        ),
        if (_schedule.length > 12) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '... ${_schedule.length - 12} more months',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _TenureToggle extends StatelessWidget {
  final bool inMonths;
  final void Function(bool) onChanged;

  const _TenureToggle({required this.inMonths, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Years',
            selected: !inMonths,
            onTap: () => onChanged(false),
          ),
          _ToggleChip(
            label: 'Months',
            selected: inMonths,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.loan.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: selected
              ? Border.all(color: AppColors.loan.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.loan : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _PieLegend(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

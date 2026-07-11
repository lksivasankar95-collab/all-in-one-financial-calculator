import 'dart:math';

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

class LoanComparisonScreen extends CalculatorBaseScreen {
  const LoanComparisonScreen({super.key})
      : super(
          calculatorId: 'loan_comparison',
          calculatorName: 'Loan Comparison',
          category: 'Loan',
        );

  @override
  ConsumerState<LoanComparisonScreen> createState() =>
      _LoanComparisonScreenState();
}

class _LoanOption {
  final TextEditingController processingFeeController;
  double rate;
  int tenureYears;

  _LoanOption({
    required this.processingFeeController,
    this.rate = 8.0,
    this.tenureYears = 20,
  });
}

class _LoanOptionResult {
  final String label;
  final double emi;
  final double totalInterest;
  final double totalAmount;
  final double rate;
  final int tenureYears;
  final double processingFee;

  const _LoanOptionResult({
    required this.label,
    required this.emi,
    required this.totalInterest,
    required this.totalAmount,
    required this.rate,
    required this.tenureYears,
    required this.processingFee,
  });
}

class _ComparisonResult {
  final List<_LoanOptionResult> options;
  final int bestIndex;

  const _ComparisonResult({
    required this.options,
    required this.bestIndex,
  });
}

class _LoanComparisonScreenState extends CalculatorBaseState<LoanComparisonScreen> {
  final _loanAmountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late List<_LoanOption> _options;

  _ComparisonResult? _result;

  @override
  void initState() {
    super.initState();
    _options = List.generate(3, (_) => _LoanOption(
      processingFeeController: TextEditingController(),
    ));
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    for (final o in _options) {
      o.processingFeeController.dispose();
    }
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _loanAmountValue =>
      NumberFormatter.tryParse(_loanAmountController.text) ?? 0;

  List<String> get _labels => ['Option 1', 'Option 2', 'Option 3'];

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Loan Amount':
          NumberFormatter.formatCurrency(_loanAmountValue, symbol: symbol),
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    final r = _result!;
    final best = r.options[r.bestIndex];
    return {
      'Recommended': best.label,
      'Best EMI':
          NumberFormatter.formatCurrency(best.emi, symbol: symbol),
      'Best Total Payable':
          NumberFormatter.formatCurrency(best.totalAmount, symbol: symbol),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    final r = _result!;
    final best = r.options[r.bestIndex];
    return 'Best: ${best.label} - EMI: ${NumberFormatter.formatCurrency(best.emi, symbol: symbol)} | Total: ${NumberFormatter.formatCurrency(best.totalAmount, symbol: symbol)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final principal = _loanAmountValue;
    if (principal <= 0) return;

    final results = <_LoanOptionResult>[];
    for (int i = 0; i < _options.length; i++) {
      final opt = _options[i];
      final int n = opt.tenureYears * 12;
      final double r = opt.rate / 1200;
      final double pf = NumberFormatter.tryParse(opt.processingFeeController.text) ?? 0;
      final double effectivePrincipal = principal * (1 + pf / 100);

      double emi;
      if (r == 0) {
        emi = effectivePrincipal / n;
      } else {
        final double factor = pow(1 + r, n).toDouble();
        emi = (effectivePrincipal * r * factor) / (factor - 1);
      }

      final double totalAmount = emi * n;
      final double totalInterest = totalAmount - principal;

      results.add(_LoanOptionResult(
        label: _labels[i],
        emi: emi,
        totalInterest: totalInterest,
        totalAmount: totalAmount,
        rate: opt.rate,
        tenureYears: opt.tenureYears,
        processingFee: pf,
      ));
    }

    int best = 0;
    for (int i = 1; i < results.length; i++) {
      if (results[i].totalAmount < results[best].totalAmount) {
        best = i;
      }
    }

    setState(() {
      _result = _ComparisonResult(options: results, bestIndex: best);
    });
  }

  void _reset() {
    for (final o in _options) {
      o.rate = 8.0;
      o.tenureYears = 20;
      o.processingFeeController.clear();
    }
    setState(() {
      _loanAmountController.clear();
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
                  buildSectionTitle('Loan Amount'),
                  AppTextField(
                    label: 'Loan Amount',
                    hint: '5000000',
                    controller: _loanAmountController,
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_options.length, (i) {
              final opt = _options[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i < _options.length - 1 ? 12 : 0),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSectionTitle(_labels[i]),
                      AppSliderField(
                        label: 'Interest Rate',
                        value: opt.rate,
                        min: 1,
                        max: 30,
                        divisions: 290,
                        displayValue: (v) => '${v.toStringAsFixed(1)}%',
                        onChanged: (v) {
                          setState(() {
                            opt.rate = v;
                            if (_result != null) _result = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AppSliderField(
                        label: 'Loan Tenure',
                        value: opt.tenureYears.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        displayValue: (v) =>
                            '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                        onChanged: (v) {
                          setState(() {
                            opt.tenureYears = v.toInt();
                            if (_result != null) _result = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Processing Fee (%)',
                        hint: '0',
                        controller: opt.processingFeeController,
                        suffix: '%',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) {
                          if (_result != null) setState(() => _result = null);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
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
    final best = r.options[r.bestIndex];

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Recommended Choice'),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        best.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedResultValue(
                      value: best.emi,
                      formatter: (v) =>
                          NumberFormatter.formatCurrency(v, symbol: symbol),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.loan,
                      ),
                    ),
                    const Text(
                      'Monthly EMI',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Side-by-Side Comparison'),
              const SizedBox(height: 8),
              _buildComparisonTable(symbol, r),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSavingsSummary(symbol, r, best),
      ],
    );
  }

  Widget _buildComparisonTable(String symbol, _ComparisonResult r) {
    return SingleChildScrollView(
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
        columns: [
          const DataColumn(label: Text('')),
          for (final opt in r.options)
            DataColumn(label: Text(opt.label)),
        ],
        rows: [
          DataRow(cells: [
            const DataCell(Text('Rate', style: TextStyle(fontWeight: FontWeight.w600))),
            for (final opt in r.options)
              DataCell(Text('${opt.rate.toStringAsFixed(1)}%')),
          ]),
          DataRow(cells: [
            const DataCell(Text('Tenure', style: TextStyle(fontWeight: FontWeight.w600))),
            for (final opt in r.options)
              DataCell(Text('${opt.tenureYears} yrs')),
          ]),
          DataRow(cells: [
            const DataCell(Text('Fee', style: TextStyle(fontWeight: FontWeight.w600))),
            for (final opt in r.options)
              DataCell(Text('${opt.processingFee.toStringAsFixed(1)}%')),
          ]),
          DataRow(cells: [
            const DataCell(Text('EMI', style: TextStyle(fontWeight: FontWeight.w600))),
            for (final opt in r.options)
              DataCell(Text(NumberFormatter.formatCurrency(opt.emi, symbol: symbol))),
          ]),
          DataRow(cells: [
            const DataCell(Text('Interest', style: TextStyle(fontWeight: FontWeight.w600))),
            for (final opt in r.options)
              DataCell(Text(NumberFormatter.formatCurrency(opt.totalInterest, symbol: symbol))),
          ]),
          DataRow(cells: [
            const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
            for (final opt in r.options)
              DataCell(Text(NumberFormatter.formatCurrency(opt.totalAmount, symbol: symbol))),
          ]),
        ],
      ),
    );
  }

  Widget _buildSavingsSummary(String symbol, _ComparisonResult r, _LoanOptionResult best) {
    final savings = <double>[];
    for (final opt in r.options) {
      if (opt.label != best.label) {
        savings.add(opt.totalAmount - best.totalAmount);
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Savings Analysis'),
          const SizedBox(height: 8),
          ...savings.asMap().entries.map((entry) {
            final otherOption = r.options.where((o) => o.label != best.label).toList()[entry.key];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ResultCard(
                label: 'Savings vs ${otherOption.label}',
                value: NumberFormatter.formatCurrency(entry.value, symbol: symbol),
                isHighlighted: true,
                valueColor: AppColors.success,
              ),
            );
          }),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Best Option',
                value: best.label,
                isHighlighted: true,
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Monthly EMI',
                value: NumberFormatter.formatCurrency(best.emi, symbol: symbol),
                isHighlighted: true,
                color: AppColors.loan,
              ),
              ResultItem(
                label: 'Total Interest',
                value: NumberFormatter.formatCurrency(best.totalInterest, symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Total Payable',
                value: NumberFormatter.formatCurrency(best.totalAmount, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Processing Fee',
                value: '${best.processingFee.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

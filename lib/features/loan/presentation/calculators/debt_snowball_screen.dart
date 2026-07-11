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

class DebtSnowballScreen extends CalculatorBaseScreen {
  const DebtSnowballScreen({super.key})
      : super(
          calculatorId: 'debt_snowball',
          calculatorName: 'Debt Snowball / Avalanche',
          category: 'Loan',
        );

  @override
  ConsumerState<DebtSnowballScreen> createState() =>
      _DebtSnowballScreenState();
}

class _DebtInput {
  final TextEditingController nameController;
  final TextEditingController balanceController;
  double rate;
  final TextEditingController minPaymentController;

  _DebtInput({
    required this.nameController,
    required this.balanceController,
    this.rate = 12.0,
    required this.minPaymentController,
  });
}

class _PayoffEntry {
  final String name;
  final int month;
  final double balance;
  final double payment;

  const _PayoffEntry({
    required this.name,
    required this.month,
    required this.balance,
    required this.payment,
  });
}

class _MethodResult {
  final String name;
  final List<_PayoffEntry> timeline;
  final double totalInterest;
  final int totalMonths;

  const _MethodResult({
    required this.name,
    required this.timeline,
    required this.totalInterest,
    required this.totalMonths,
  });
}

class _DebtSnowballResult {
  final _MethodResult snowball;
  final _MethodResult avalanche;
  final double interestSaved;
  final int monthsSaved;
  final List<_DebtSummary> debts;

  const _DebtSnowballResult({
    required this.snowball,
    required this.avalanche,
    required this.interestSaved,
    required this.monthsSaved,
    required this.debts,
  });
}

class _DebtSummary {
  final String name;
  final double balance;
  final double rate;
  final double minPayment;

  const _DebtSummary({
    required this.name,
    required this.balance,
    required this.rate,
    required this.minPayment,
  });
}

class _DebtSnowballScreenState extends CalculatorBaseState<DebtSnowballScreen> {
  final _extraPaymentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late List<_DebtInput> _debts;

  _DebtSnowballResult? _result;

  @override
  void initState() {
    super.initState();
    _debts = [
      _DebtInput(
        nameController: TextEditingController(text: 'Credit Card'),
        balanceController: TextEditingController(),
        rate: 24.0,
        minPaymentController: TextEditingController(),
      ),
      _DebtInput(
        nameController: TextEditingController(text: 'Personal Loan'),
        balanceController: TextEditingController(),
        rate: 14.0,
        minPaymentController: TextEditingController(),
      ),
      _DebtInput(
        nameController: TextEditingController(text: 'Car Loan'),
        balanceController: TextEditingController(),
        rate: 9.0,
        minPaymentController: TextEditingController(),
      ),
    ];
  }

  @override
  void dispose() {
    _extraPaymentController.dispose();
    for (final d in _debts) {
      d.nameController.dispose();
      d.balanceController.dispose();
      d.minPaymentController.dispose();
    }
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _extraPaymentValue =>
      NumberFormatter.tryParse(_extraPaymentController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    final inputs = <String, dynamic>{
      'Extra Monthly Payment':
          NumberFormatter.formatCurrency(_extraPaymentValue, symbol: symbol),
    };
    for (int i = 0; i < _debts.length; i++) {
      final d = _debts[i];
      final name = d.nameController.text.isNotEmpty
          ? d.nameController.text
          : 'Debt ${i + 1}';
      inputs['$name Balance'] =
          NumberFormatter.formatCurrency(
              NumberFormatter.tryParse(d.balanceController.text) ?? 0,
              symbol: symbol);
      inputs['$name Rate'] = NumberFormatter.formatPercent(d.rate);
    }
    return inputs;
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Snowball Interest':
          NumberFormatter.formatCurrency(_result!.snowball.totalInterest, symbol: symbol),
      'Avalanche Interest':
          NumberFormatter.formatCurrency(_result!.avalanche.totalInterest, symbol: symbol),
      'Interest Saved':
          NumberFormatter.formatCurrency(_result!.interestSaved, symbol: symbol),
      'Months Saved': '${_result!.monthsSaved} months',
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    final r = _result!;
    return 'Snowball: ${NumberFormatter.formatCurrency(r.snowball.totalInterest, symbol: symbol)} interest, ${r.snowball.totalMonths}mo | '
        'Avalanche: ${NumberFormatter.formatCurrency(r.avalanche.totalInterest, symbol: symbol)} interest, ${r.avalanche.totalMonths}mo | '
        'Save: ${NumberFormatter.formatCurrency(r.interestSaved, symbol: symbol)}';
  }

  _MethodResult _simulateMethod({
    required String name,
    required List<_DebtSummary> debts,
    required double extraPayment,
    required bool useSnowball,
  }) {
    final balances = debts.map((d) => d.balance).toList();
    final rates = debts.map((d) => d.rate).toList();
    final minPayments = debts.map((d) => d.minPayment).toList();
    final debtNames = debts.map((d) => d.name).toList();
    final active = List<bool>.filled(debts.length, true);
    final timeline = <_PayoffEntry>[];
    double totalInterest = 0;
    int month = 0;
    const int maxMonths = 1200;

    while (active.any((a) => a) && month < maxMonths) {
      month++;
      double extraRemaining = extraPayment;

      // Determine payoff order
      final order = List<int>.generate(debts.length, (i) => i);
      // Remove paid-off debts from order
      order.removeWhere((i) => !active[i]);

      if (order.isEmpty) break;

      if (useSnowball) {
        // Snowball: smallest balance first
        order.sort((a, b) => balances[a].compareTo(balances[b]));
      } else {
        // Avalanche: highest rate first
        order.sort((a, b) => rates[b].compareTo(rates[a]));
      }

      // Accrue interest and apply minimum payments
      for (final i in order) {
        final double monthlyRate = rates[i] / 1200;
        final double interest = balances[i] * monthlyRate;
        totalInterest += interest;
        balances[i] += interest;

        final double minPmt = minPayments[i];
        final double payment = minPmt;
        balances[i] -= payment;
        if (balances[i] < 0) balances[i] = 0;
      }

      // Apply extra payment to target debt
      for (final i in order) {
        if (extraRemaining <= 0 || !active[i]) break;
        final double extra = min(extraRemaining, balances[i]);
        balances[i] -= extra;
        extraRemaining -= extra;
        if (balances[i] < 0) balances[i] = 0;
      }

      // Check which debts are paid off this month
      for (final i in order) {
        if (active[i] && balances[i] <= 0) {
          active[i] = false;
          timeline.add(_PayoffEntry(
            name: debtNames[i],
            month: month,
            balance: 0,
            payment: 0,
          ));
        }
      }
    }

    return _MethodResult(
      name: name,
      timeline: timeline,
      totalInterest: totalInterest,
      totalMonths: month,
    );
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final extraPayment = _extraPaymentValue;

    final summaries = <_DebtSummary>[];
    for (final d in _debts) {
      final balance = NumberFormatter.tryParse(d.balanceController.text) ?? 0;
      final minPmt = NumberFormatter.tryParse(d.minPaymentController.text) ?? 0;
      final name = d.nameController.text.isNotEmpty
          ? d.nameController.text
          : 'Debt ${_debts.indexOf(d) + 1}';
      if (balance <= 0 || minPmt <= 0) continue;
      summaries.add(_DebtSummary(
        name: name,
        balance: balance,
        rate: d.rate,
        minPayment: minPmt,
      ));
    }

    if (summaries.isEmpty) return;

    final snowball = _simulateMethod(
      name: 'Snowball',
      debts: summaries,
      extraPayment: extraPayment,
      useSnowball: true,
    );

    final avalanche = _simulateMethod(
      name: 'Avalanche',
      debts: summaries,
      extraPayment: extraPayment,
      useSnowball: false,
    );

    final interestSaved = snowball.totalInterest - avalanche.totalInterest;
    final monthsSaved = snowball.totalMonths - avalanche.totalMonths;

    setState(() {
      _result = _DebtSnowballResult(
        snowball: snowball,
        avalanche: avalanche,
        interestSaved: interestSaved > 0 ? interestSaved : 0,
        monthsSaved: monthsSaved > 0 ? monthsSaved : 0,
        debts: summaries,
      );
    });
  }

  void _addDebt() {
    setState(() {
      _debts.add(_DebtInput(
        nameController: TextEditingController(),
        balanceController: TextEditingController(),
        rate: 12.0,
        minPaymentController: TextEditingController(),
      ));
      if (_result != null) _result = null;
    });
  }

  void _removeDebt(int index) {
    if (_debts.length <= 1) return;
    setState(() {
      _debts[index].nameController.dispose();
      _debts[index].balanceController.dispose();
      _debts[index].minPaymentController.dispose();
      _debts.removeAt(index);
      if (_result != null) _result = null;
    });
  }

  void _reset() {
    for (final d in _debts) {
      d.nameController.dispose();
      d.balanceController.dispose();
      d.minPaymentController.dispose();
    }
    setState(() {
      _debts = [
        _DebtInput(
          nameController: TextEditingController(text: 'Credit Card'),
          balanceController: TextEditingController(),
          rate: 24.0,
          minPaymentController: TextEditingController(),
        ),
        _DebtInput(
          nameController: TextEditingController(text: 'Personal Loan'),
          balanceController: TextEditingController(),
          rate: 14.0,
          minPaymentController: TextEditingController(),
        ),
        _DebtInput(
          nameController: TextEditingController(text: 'Car Loan'),
          balanceController: TextEditingController(),
          rate: 9.0,
          minPaymentController: TextEditingController(),
        ),
      ];
      _extraPaymentController.clear();
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
                  buildSectionTitle('Your Debts'),
                  ...List.generate(_debts.length, (i) {
                    final d = _debts[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Debt ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (_debts.length > 1)
                                GestureDetector(
                                  onTap: () => _removeDebt(i),
                                  child: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            label: 'Debt Name',
                            hint: 'Credit Card',
                            controller: d.nameController,
                            keyboardType: TextInputType.text,
                            onChanged: (_) {
                              if (_result != null) setState(() => _result = null);
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Balance',
                            hint: '50000',
                            controller: d.balanceController,
                            prefix: symbol,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                                return 'Enter a valid balance';
                              }
                              return null;
                            },
                            onChanged: (_) {
                              if (_result != null) setState(() => _result = null);
                            },
                          ),
                          const SizedBox(height: 12),
                          AppSliderField(
                            label: 'Interest Rate',
                            value: d.rate,
                            min: 1,
                            max: 40,
                            divisions: 390,
                            displayValue: (v) => '${v.toStringAsFixed(1)}%',
                            onChanged: (v) {
                              setState(() {
                                d.rate = v;
                                if (_result != null) _result = null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Minimum Monthly Payment',
                            hint: '2000',
                            controller: d.minPaymentController,
                            prefix: symbol,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                                return 'Enter a valid payment';
                              }
                              return null;
                            },
                            onChanged: (_) {
                              if (_result != null) setState(() => _result = null);
                            },
                          ),
                          if (i < _debts.length - 1)
                            const Divider(height: 24, color: AppColors.border),
                        ],
                      ),
                    );
                  }),
                  Center(
                    child: TextButton.icon(
                      onPressed: _addDebt,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Another Debt'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Extra Payment'),
                  AppTextField(
                    label: 'Extra Monthly Payment',
                    hint: '5000',
                    controller: _extraPaymentController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate',
                          icon: Icons.leaderboard_rounded,
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

    final String recommended;
    final Color recColor;
    if (r.interestSaved > 0) {
      recommended = 'Avalanche (saves more interest)';
      recColor = AppColors.success;
    } else {
      recommended = 'Snowball (pay off faster psychologically)';
      recColor = AppColors.loan;
    }

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Recommendation'),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: recColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: recColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    recommended,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: recColor,
                    ),
                  ),
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
              buildSectionTitle('Snowball vs Avalanche'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Snowball Interest',
                      value: NumberFormatter.formatCurrency(
                          r.snowball.totalInterest, symbol: symbol),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Avalanche Interest',
                      value: NumberFormatter.formatCurrency(
                          r.avalanche.totalInterest, symbol: symbol),
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Snowball Months',
                      value: '${r.snowball.totalMonths} ${r.snowball.totalMonths == 1 ? "mo" : "mos"}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Avalanche Months',
                      value: '${r.avalanche.totalMonths} ${r.avalanche.totalMonths == 1 ? "mo" : "mos"}',
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (r.interestSaved > 0)
                ResultCard(
                  label: 'Interest Saved with Avalanche',
                  value: NumberFormatter.formatCurrency(
                      r.interestSaved, symbol: symbol),
                  isHighlighted: true,
                  valueColor: AppColors.success,
                ),
              if (r.monthsSaved > 0)
                const SizedBox(height: 10),
              if (r.monthsSaved > 0)
                ResultCard(
                  label: 'Months Saved with Avalanche',
                  value: '${r.monthsSaved} ${r.monthsSaved == 1 ? "month" : "months"}',
                  isHighlighted: true,
                  valueColor: AppColors.success,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineSection(symbol, r),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Payoff Order'),
              const SizedBox(height: 8),
              _buildOrderTable(r),
              const SizedBox(height: 12),
              ResultSummaryCard(
                title: 'Summary',
                items: [
                  ResultItem(
                    label: 'Total Debts',
                    value: '${r.debts.length}',
                  ),
                  ResultItem(
                    label: 'Snowball Interest',
                    value: NumberFormatter.formatCurrency(
                        r.snowball.totalInterest, symbol: symbol),
                    color: AppColors.warning,
                  ),
                  ResultItem(
                    label: 'Avalanche Interest',
                    value: NumberFormatter.formatCurrency(
                        r.avalanche.totalInterest, symbol: symbol),
                    color: AppColors.success,
                  ),
                  ResultItem(
                    label: 'Interest Saved',
                    value: NumberFormatter.formatCurrency(
                        r.interestSaved, symbol: symbol),
                    isHighlighted: true,
                    color: AppColors.success,
                  ),
                  ResultItem(
                    label: 'Snowball Duration',
                    value: '${r.snowball.totalMonths} ${r.snowball.totalMonths == 1 ? "month" : "months"}',
                  ),
                  ResultItem(
                    label: 'Avalanche Duration',
                    value: '${r.avalanche.totalMonths} ${r.avalanche.totalMonths == 1 ? "month" : "months"}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(String symbol, _DebtSnowballResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Payoff Timeline'),
          const SizedBox(height: 8),
          const Text(
            'Snowball Method (smallest balance first)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (r.snowball.timeline.isEmpty)
            const Text('No debts to pay off',
                style: TextStyle(fontSize: 12, color: AppColors.textHint))
          else
            ...r.snowball.timeline.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.name} - Month ${e.month}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          const Text(
            'Avalanche Method (highest rate first)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (r.avalanche.timeline.isEmpty)
            const Text('No debts to pay off',
                style: TextStyle(fontSize: 12, color: AppColors.textHint))
          else
            ...r.avalanche.timeline.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.name} - Month ${e.month}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildOrderTable(_DebtSnowballResult r) {
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
        columns: const [
          DataColumn(label: Text('Debt')),
          DataColumn(label: Text('Balance')),
          DataColumn(label: Text('Rate')),
          DataColumn(label: Text('Min Pmt')),
          DataColumn(label: Text('Snowball')),
          DataColumn(label: Text('Avalanche')),
        ],
        rows: r.debts.map((d) {
          final snowballOrder = r.snowball.timeline.indexWhere(
              (t) => t.name == d.name);
          final avalancheOrder = r.avalanche.timeline.indexWhere(
              (t) => t.name == d.name);
          return DataRow(cells: [
            DataCell(Text(d.name)),
            DataCell(Text(NumberFormatter.formatCurrency(d.balance))),
            DataCell(Text('${d.rate.toStringAsFixed(1)}%')),
            DataCell(Text(NumberFormatter.formatCurrency(d.minPayment))),
            DataCell(Text(snowballOrder >= 0
                ? '#${snowballOrder + 1} (Month ${r.snowball.timeline[snowballOrder].month})'
                : '-')),
            DataCell(Text(avalancheOrder >= 0
                ? '#${avalancheOrder + 1} (Month ${r.avalanche.timeline[avalancheOrder].month})'
                : '-')),
          ]);
        }).toList(),
      ),
    );
  }
}

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

class SinkingFundScreen extends CalculatorBaseScreen {
  const SinkingFundScreen({super.key})
      : super(
          calculatorId: 'sinking_fund',
          calculatorName: 'Sinking Fund',
          category: 'Savings',
        );

  @override
  ConsumerState<SinkingFundScreen> createState() => _SinkingFundScreenState();
}

class _SinkingFundScreenState extends CalculatorBaseState<SinkingFundScreen> {
  final _targetController = TextEditingController();
  double _years = 10.0;
  double _annualReturn = 8.0;
  SinkingFundResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Target Amount':
            NumberFormatter.formatCurrency(_targetAmount, symbol: _symbol),
        'Time Horizon': '${_years.toInt()} years',
        'Annual Return': NumberFormatter.formatPercent(_annualReturn),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Monthly Deposit Needed': NumberFormatter.formatCurrency(
              _result!.monthlyDeposit,
              symbol: _symbol),
          'Total Contributed': NumberFormatter.formatCurrency(
              _result!.totalContributed,
              symbol: _symbol),
          'Interest Earned': NumberFormatter.formatCurrency(
              _result!.interestEarned,
              symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Sinking fund: Save ${NumberFormatter.formatCurrency(_result!.monthlyDeposit, symbol: _symbol)}/mo for ${_years.toInt()} years to reach ${NumberFormatter.formatCurrency(_targetAmount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _targetAmount =>
      NumberFormatter.tryParse(_targetController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final target = _targetAmount;
    if (target <= 0) return;

    final int n = (_years * 12).toInt();
    final double r = _annualReturn / 1200;

    double monthlyDeposit;
    if (r <= 0) {
      monthlyDeposit = target / n;
    } else {
      monthlyDeposit = target / ((pow(1 + r, n) - 1) / r);
    }

    final double totalContributed = monthlyDeposit * n;
    final double interestEarned = target - totalContributed;

    setState(() {
      _result = SinkingFundResult(
        monthlyDeposit: monthlyDeposit,
        totalContributed: totalContributed,
        interestEarned: interestEarned,
      );
    });
  }

  void _reset() {
    setState(() {
      _targetController.clear();
      _years = 10.0;
      _annualReturn = 8.0;
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
                  buildSectionTitle('Sinking Fund Details'),
                  AppTextField(
                    label: 'Target Amount',
                    hint: '10,00,000',
                    controller: _targetController,
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
                    label: 'Time Horizon',
                    value: _years,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _years = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Annual Return',
                    value: _annualReturn,
                    min: 1,
                    max: 15,
                    divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualReturn = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.savings.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.savings.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Months',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${(_years * 12).toInt()} months',
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Sinking Fund Plan'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.savings.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.savings.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_rounded,
                    color: AppColors.savings, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deposit ${NumberFormatter.formatCurrency(r.monthlyDeposit, symbol: symbol)} per month for ${_years.toInt()} years.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'Monthly Deposit Needed',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.monthlyDeposit,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
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
                  label: 'Total Contributed',
                  value: NumberFormatter.formatCurrency(
                      r.totalContributed, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Interest Earned',
                  value: NumberFormatter.formatCurrency(
                      r.interestEarned, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Sinking Fund Summary',
            items: [
              ResultItem(
                label: 'Target Amount',
                value:
                    NumberFormatter.formatCurrency(_targetAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Time Horizon',
                value: '${_years.toInt()} years (${(_years * 12).toInt()} months)',
              ),
              ResultItem(
                label: 'Expected Return',
                value: NumberFormatter.formatPercent(_annualReturn),
              ),
              ResultItem(
                label: 'Monthly Deposit',
                value:
                    NumberFormatter.formatCurrency(r.monthlyDeposit, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Total Contributed',
                value: NumberFormatter.formatCurrency(
                    r.totalContributed, symbol: symbol),
              ),
              ResultItem(
                label: 'Interest Earned',
                value: NumberFormatter.formatCurrency(
                    r.interestEarned, symbol: symbol),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SinkingFundResult {
  final double monthlyDeposit;
  final double totalContributed;
  final double interestEarned;

  const SinkingFundResult({
    required this.monthlyDeposit,
    required this.totalContributed,
    required this.interestEarned,
  });
}

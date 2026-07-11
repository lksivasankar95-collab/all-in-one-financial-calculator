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

class BalanceTransferScreen extends CalculatorBaseScreen {
  const BalanceTransferScreen({super.key})
      : super(
          calculatorId: 'balance_transfer',
          calculatorName: 'Balance Transfer',
          category: 'Loan',
        );

  @override
  ConsumerState<BalanceTransferScreen> createState() =>
      _BalanceTransferScreenState();
}

class _BalanceTransferScreenState
    extends CalculatorBaseState<BalanceTransferScreen> {
  final _outstandingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _currentRate = 10.5;
  double _newRate = 8.0;
  int _remainingTenureYears = 15;

  BalanceTransferResult? _result;

  @override
  void dispose() {
    _outstandingController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _outstandingValue =>
      NumberFormatter.tryParse(_outstandingController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    return {
      'Outstanding Loan':
          NumberFormatter.formatCurrency(_outstandingValue, symbol: symbol),
      'Current Interest Rate': NumberFormatter.formatPercent(_currentRate),
      'New Interest Rate': NumberFormatter.formatPercent(_newRate),
      'Remaining Tenure': '$_remainingTenureYears years',
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    final breakevenMonths = _result!.processingFeeBreakeven.isFinite
        ? _result!.processingFeeBreakeven.round()
        : 0;
    return {
      'Current EMI':
          NumberFormatter.formatCurrency(_result!.currentEmi, symbol: symbol),
      'New EMI':
          NumberFormatter.formatCurrency(_result!.newEmi, symbol: symbol),
      'EMI Saved Per Month':
          NumberFormatter.formatCurrency(_result!.emiSaved, symbol: symbol),
      'Total Savings':
          NumberFormatter.formatCurrency(_result!.totalSavings, symbol: symbol),
      'Breakeven Period': '$breakevenMonths months',
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    final breakevenMonths = _result!.processingFeeBreakeven.isFinite
        ? _result!.processingFeeBreakeven.round()
        : 0;
    return 'EMI Saved: ${NumberFormatter.formatCurrency(_result!.emiSaved, symbol: symbol)}/mo | '
        'Total Savings: ${NumberFormatter.formatCurrency(_result!.totalSavings, symbol: symbol)} | '
        'Breakeven: $breakevenMonths months';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final outstanding = _outstandingValue;
    if (outstanding <= 0) return;

    setState(() {
      _result = LoanCalculators.calculateBalanceTransfer(
        outstandingLoan: outstanding,
        currentRate: _currentRate,
        newRate: _newRate,
        remainingTenureYears: _remainingTenureYears,
      );
    });
  }

  void _reset() {
    setState(() {
      _outstandingController.clear();
      _currentRate = 10.5;
      _newRate = 8.0;
      _remainingTenureYears = 15;
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
                  buildSectionTitle('Current Loan Details'),
                  AppTextField(
                    label: 'Outstanding Loan Amount',
                    hint: '1500000',
                    controller: _outstandingController,
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
                    label: 'Current Interest Rate',
                    value: _currentRate,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _currentRate = v;
                        // Ensure new rate stays below current for meaningful comparison
                        if (_newRate >= _currentRate) {
                          _newRate = (_currentRate - 0.5).clamp(1.0, 30.0);
                        }
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('New Lender Details'),
                  AppSliderField(
                    label: 'New Interest Rate',
                    value: _newRate,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _newRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Remaining Tenure',
                    value: _remainingTenureYears.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _remainingTenureYears = v.toInt();
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_newRate >= _currentRate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16, color: AppColors.warning),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'New rate should be lower than current rate for savings.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate Savings',
                          icon: Icons.swap_horiz_rounded,
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
    final beneficial = r.emiSaved > 0;
    final breakevenMonths = r.processingFeeBreakeven.isFinite
        ? r.processingFeeBreakeven.round()
        : 0;
    final totalRemainingMonths = _remainingTenureYears * 12;
    final processingFee = _outstandingValue * 0.01;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Transfer Analysis'),
          // EMI comparison side-by-side
          Row(
            children: [
              Expanded(
                child: _EmiCompareCard(
                  label: 'Current EMI',
                  value: NumberFormatter.formatCurrency(r.currentEmi,
                      symbol: symbol),
                  color: AppColors.error,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Icon(Icons.arrow_forward_rounded,
                        color: AppColors.textHint, size: 20),
                  ],
                ),
              ),
              Expanded(
                child: _EmiCompareCard(
                  label: 'New EMI',
                  value:
                      NumberFormatter.formatCurrency(r.newEmi, symbol: symbol),
                  color: AppColors.success,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total savings – animated
          Center(
            child: Column(
              children: [
                const Text(
                  'Total Savings',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalSavings,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: beneficial ? AppColors.success : AppColors.textHint,
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
                  label: 'EMI Saved / Month',
                  value: NumberFormatter.formatCurrency(r.emiSaved,
                      symbol: symbol),
                  valueColor: beneficial ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Breakeven Period',
                  value: '$breakevenMonths months',
                  subtitle: '(to recover 1% processing fee)',
                  valueColor: breakevenMonths < totalRemainingMonths
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Current EMI',
                value: NumberFormatter.formatCurrency(r.currentEmi,
                    symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'New EMI',
                value:
                    NumberFormatter.formatCurrency(r.newEmi, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'EMI Saved / Month',
                value: NumberFormatter.formatCurrency(r.emiSaved,
                    symbol: symbol),
              ),
              ResultItem(
                label: '1% Processing Fee',
                value: NumberFormatter.formatCurrency(processingFee,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Breakeven Period',
                value: '$breakevenMonths months',
              ),
              ResultItem(
                label: 'Total Savings',
                value: NumberFormatter.formatCurrency(r.totalSavings,
                    symbol: symbol),
                isHighlighted: true,
                color: beneficial ? AppColors.success : AppColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAdviceSection(beneficial, breakevenMonths, totalRemainingMonths, symbol),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(
    bool beneficial,
    int breakevenMonths,
    int totalRemainingMonths,
    String symbol,
  ) {
    final Color adviceColor =
        beneficial && breakevenMonths < totalRemainingMonths
            ? AppColors.success
            : AppColors.warning;

    String adviceText;
    IconData adviceIcon;

    if (!beneficial) {
      adviceText =
          'Balance transfer is NOT recommended. Your new rate is not lower than the current rate. '
          'You will end up paying more EMI.';
      adviceIcon = Icons.cancel_rounded;
    } else if (breakevenMonths >= totalRemainingMonths) {
      adviceText =
          'Transfer may not be beneficial. You would need more than $_remainingTenureYears years '
          'to recover the 1% processing fee (${NumberFormatter.formatCurrency(_outstandingValue * 0.01, symbol: symbol)}). '
          'Consider negotiating a rate cut with your existing lender instead.';
      adviceIcon = Icons.warning_amber_rounded;
    } else {
      adviceText =
          'Transfer is beneficial if you plan to repay for more than $breakevenMonths months. '
          'You will start saving from month ${breakevenMonths + 1} onwards. '
          'With $_remainingTenureYears years remaining, '
          'you will earn a net benefit of '
          '${NumberFormatter.formatCurrency((_result!.totalSavings - _outstandingValue * 0.01).clamp(0, double.infinity), symbol: symbol)}.';
      adviceIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: adviceColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: adviceColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(adviceIcon, size: 16, color: adviceColor),
              const SizedBox(width: 6),
              Text(
                'Transfer Advice',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: adviceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            adviceText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widget ────────────────────────────────────────────────────────

class _EmiCompareCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _EmiCompareCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

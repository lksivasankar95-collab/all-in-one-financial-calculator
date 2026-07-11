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
import '../../domain/banking_calculators.dart';

class CreditCardInterestScreen extends CalculatorBaseScreen {
  const CreditCardInterestScreen({super.key})
      : super(
          calculatorId: 'credit_card_interest',
          calculatorName: 'Credit Card Interest Calculator',
          category: 'Banking',
        );

  @override
  ConsumerState<CreditCardInterestScreen> createState() => _CreditCardInterestScreenState();
}

class _CreditCardInterestScreenState extends CalculatorBaseState<CreditCardInterestScreen> {
  final _balanceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _annualRate = 36.0;
  int _daysOverdue = 30;
  CreditCardInterestResult? _result;

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _balanceValue => NumberFormatter.tryParse(_balanceController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Outstanding Balance': NumberFormatter.formatCurrency(_balanceValue, symbol: _symbol),
        'Annual Rate': NumberFormatter.formatPercent(_annualRate),
        'Days Overdue': '$_daysOverdue days',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Interest Charged': NumberFormatter.formatCurrency(_result!.interestCharged, symbol: _symbol),
          'Total Due': NumberFormatter.formatCurrency(_result!.totalDue, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Interest: ${NumberFormatter.formatCurrency(_result!.interestCharged, symbol: _symbol)} | '
          'Total Due: ${NumberFormatter.formatCurrency(_result!.totalDue, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final balance = _balanceValue;
    if (balance <= 0) return;

    setState(() {
      _result = BankingCalculators.calculateCreditCardInterest(
        outstandingBalance: balance,
        annualRate: _annualRate,
        days: _daysOverdue,
      );
    });
  }

  void _reset() {
    setState(() {
      _balanceController.clear();
      _annualRate = 36.0;
      _daysOverdue = 30;
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
                  buildSectionTitle('Credit Card Details'),
                  AppTextField(
                    label: 'Outstanding Balance',
                    hint: '50000',
                    controller: _balanceController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Interest Rate',
                    value: _annualRate,
                    min: 5,
                    max: 45,
                    divisions: 400,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _annualRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Days Overdue',
                    value: _daysOverdue.toDouble(),
                    min: 1,
                    max: 90,
                    divisions: 89,
                    displayValue: (v) => '${v.toInt()} days',
                    onChanged: (v) => setState(() { _daysOverdue = v.toInt(); _result = null; }),
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
                          color: AppColors.banking,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.banking,
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
    final monthlyInterest = r.interestCharged;
    final isHigh = _annualRate >= 30;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text('Interest Charged', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.interestCharged,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w800,
                    color: isHigh ? AppColors.error : AppColors.banking,
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
                  label: 'Outstanding Balance',
                  value: NumberFormatter.formatCurrency(_balanceValue, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Due',
                  value: NumberFormatter.formatCurrency(r.totalDue, symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Monthly Interest (approx.)',
            value: NumberFormatter.formatCurrency(monthlyInterest, symbol: symbol),
            isHighlighted: true,
            subtitle: 'At ${_annualRate.toStringAsFixed(1)}% p.a. for $_daysOverdue days',
          ),
          if (isHigh) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'High interest rate! Consider paying off your credit card balance ASAP.',
                      style: TextStyle(fontSize: 12, color: AppColors.error.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Outstanding Balance',
                value: NumberFormatter.formatCurrency(_balanceValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Interest Rate',
                value: NumberFormatter.formatPercent(_annualRate),
                color: isHigh ? AppColors.error : null,
              ),
              ResultItem(
                label: 'Interest Charged',
                value: NumberFormatter.formatCurrency(r.interestCharged, symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Total Due',
                value: NumberFormatter.formatCurrency(r.totalDue, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

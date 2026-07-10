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
import '../../domain/investment_calculators.dart';

class SwpScreen extends CalculatorBaseScreen {
  const SwpScreen({super.key})
      : super(
          calculatorId: 'swp',
          calculatorName: 'SWP Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<SwpScreen> createState() => _SwpScreenState();
}

class _SwpScreenState extends CalculatorBaseState<SwpScreen> {
  final _corpusController = TextEditingController();
  final _withdrawalController = TextEditingController();
  double _annualReturn = 8.0;
  SwpResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _corpusController.dispose();
    _withdrawalController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Initial Corpus':
            NumberFormatter.formatCurrency(_corpusValue, symbol: _symbol),
        'Monthly Withdrawal':
            NumberFormatter.formatCurrency(_withdrawalValue, symbol: _symbol),
        'Annual Return Rate': NumberFormatter.formatPercent(_annualReturn),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Withdrawal Sustains':
              NumberFormatter.formatMonths(_result!.monthsWithdrawalSustains),
          'Total Withdrawn':
              NumberFormatter.formatCurrency(_result!.totalWithdrawn, symbol: _symbol),
          'Remaining Corpus':
              NumberFormatter.formatCurrency(_result!.remainingCorpus, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'SWP: ${NumberFormatter.formatCurrency(_withdrawalValue, symbol: _symbol)}/mo '
          'from ${NumberFormatter.formatCurrency(_corpusValue, symbol: _symbol)} '
          'sustains for ${NumberFormatter.formatMonths(_result!.monthsWithdrawalSustains)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _corpusValue =>
      NumberFormatter.tryParse(_corpusController.text) ?? 0;
  double get _withdrawalValue =>
      NumberFormatter.tryParse(_withdrawalController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculateSwp(
        initialCorpus: _corpusValue,
        monthlyWithdrawal: _withdrawalValue,
        annualReturnRate: _annualReturn,
      );
    });
  }

  void _reset() {
    setState(() {
      _corpusController.clear();
      _withdrawalController.clear();
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
                  buildSectionTitle('Withdrawal Details'),
                  AppTextField(
                    label: 'Initial Corpus / Investment',
                    hint: '10,00,000',
                    controller: _corpusController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid corpus';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Withdrawal Amount',
                    hint: '10,000',
                    controller: _withdrawalController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = NumberFormatter.tryParse(v) ?? 0;
                      if (val <= 0) return 'Enter a valid withdrawal amount';
                      if (val >= (_corpusValue)) {
                        return 'Withdrawal must be less than corpus';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Annual Return',
                    value: _annualReturn,
                    min: 0,
                    max: 20,
                    divisions: 200,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _annualReturn = v;
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final months = r.monthsWithdrawalSustains;
    final isSustainable = months >= 1200;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Withdrawal Plan Results'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                Text(
                  isSustainable ? 'Perpetual Withdrawal' : 'Sustains For',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSustainable
                      ? 'Indefinitely'
                      : NumberFormatter.formatMonths(months),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (isSustainable)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Monthly returns exceed withdrawal amount',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Withdrawn',
                  value: NumberFormatter.formatCurrency(r.totalWithdrawn,
                      symbol: symbol),
                  valueColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Remaining Corpus',
                  value: NumberFormatter.formatCurrency(r.remainingCorpus,
                      symbol: symbol),
                  valueColor: r.remainingCorpus > 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Initial Corpus',
                value: NumberFormatter.formatCurrency(_corpusValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Monthly Withdrawal',
                value: NumberFormatter.formatCurrency(_withdrawalValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Annual Return',
                value: NumberFormatter.formatPercent(_annualReturn),
              ),
              ResultItem(
                label: 'Withdrawal Duration',
                value: isSustainable
                    ? 'Perpetual'
                    : NumberFormatter.formatMonths(months),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Total Amount Withdrawn',
                value: NumberFormatter.formatCurrency(r.totalWithdrawn,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Balance Remaining',
                value: NumberFormatter.formatCurrency(r.remainingCorpus,
                    symbol: symbol),
                color: r.remainingCorpus > 0
                    ? AppColors.success
                    : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

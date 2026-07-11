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

class SavingsInterestScreen extends CalculatorBaseScreen {
  const SavingsInterestScreen({super.key})
      : super(
          calculatorId: 'savings_interest',
          calculatorName: 'Savings Interest Calculator',
          category: 'Banking',
        );

  @override
  ConsumerState<SavingsInterestScreen> createState() => _SavingsInterestScreenState();
}

class _SavingsInterestScreenState extends CalculatorBaseState<SavingsInterestScreen> {
  final _principalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _annualRate = 4.0;
  int _days = 365;
  SavingsInterestResult? _result;

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _principalValue => NumberFormatter.tryParse(_principalController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Principal': NumberFormatter.formatCurrency(_principalValue, symbol: _symbol),
        'Rate': NumberFormatter.formatPercent(_annualRate),
        'Days': '$_days days',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Interest Earned': NumberFormatter.formatCurrency(_result!.interest, symbol: _symbol),
          'Maturity Amount': NumberFormatter.formatCurrency(_result!.totalBalance, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Interest: ${NumberFormatter.formatCurrency(_result!.interest, symbol: _symbol)} | '
          'Maturity: ${NumberFormatter.formatCurrency(_result!.totalBalance, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final principal = _principalValue;
    if (principal <= 0) return;

    setState(() {
      _result = BankingCalculators.calculateSavingsInterest(
        dailyBalance: principal,
        rate: _annualRate,
        days: _days,
      );
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _annualRate = 4.0;
      _days = 365;
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
                  buildSectionTitle('Savings Details'),
                  AppTextField(
                    label: 'Principal Amount',
                    hint: '100000',
                    controller: _principalController,
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
                    min: 1,
                    max: 15,
                    divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _annualRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Number of Days',
                    value: _days.toDouble(),
                    min: 1,
                    max: 365,
                    divisions: 364,
                    displayValue: (v) => '${v.toInt()} days',
                    onChanged: (v) => setState(() { _days = v.toInt(); _result = null; }),
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
    final effectiveRate = _principalValue > 0
        ? (r.interest / _principalValue) * (365 / _days) * 100
        : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text('Interest Earned', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.interest,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.banking),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Principal',
                  value: NumberFormatter.formatCurrency(_principalValue, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Maturity Amount',
                  value: NumberFormatter.formatCurrency(r.totalBalance, symbol: symbol),
                  valueColor: AppColors.banking,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Effective Annual Rate',
            value: NumberFormatter.formatPercent(effectiveRate),
            isHighlighted: true,
            subtitle: 'Based on $_days days @ ${_annualRate.toStringAsFixed(1)}% p.a.',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Principal',
                value: NumberFormatter.formatCurrency(_principalValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Rate',
                value: '${_annualRate.toStringAsFixed(1)}% p.a.',
              ),
              ResultItem(
                label: 'Period',
                value: '$_days days',
              ),
              ResultItem(
                label: 'Interest Earned',
                value: NumberFormatter.formatCurrency(r.interest, symbol: symbol),
                color: AppColors.banking,
              ),
              ResultItem(
                label: 'Maturity Amount',
                value: NumberFormatter.formatCurrency(r.totalBalance, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

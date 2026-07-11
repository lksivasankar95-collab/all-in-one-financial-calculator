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

class FutureValueScreen extends CalculatorBaseScreen {
  const FutureValueScreen({super.key})
      : super(
          calculatorId: 'future_value',
          calculatorName: 'Future Value Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<FutureValueScreen> createState() => _FutureValueScreenState();
}

class _FutureValueScreenState extends CalculatorBaseState<FutureValueScreen> {
  final _presentValueController = TextEditingController();
  final _monthlyAdditionController = TextEditingController();
  double _annualRate = 8.0;
  int _years = 10;
  FutureValueResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _presentValueController.dispose();
    _monthlyAdditionController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Present Value':
            NumberFormatter.formatCurrency(_presentValue, symbol: _symbol),
        'Annual Rate': NumberFormatter.formatPercent(_annualRate),
        'Period': '$_years years',
        'Monthly Addition':
            NumberFormatter.formatCurrency(_monthlyAddition, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Future Value':
              NumberFormatter.formatCurrency(_result!.futureValue, symbol: _symbol),
          'Total Contributions':
              NumberFormatter.formatCurrency(_result!.totalContributions, symbol: _symbol),
          'Total Interest':
              NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'FV: ${NumberFormatter.formatCurrency(_result!.futureValue, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.totalContributions, symbol: _symbol)} | '
          'Interest: ${NumberFormatter.formatCurrency(_result!.totalInterest, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _presentValue =>
      NumberFormatter.tryParse(_presentValueController.text) ?? 0;
  double get _monthlyAddition =>
      NumberFormatter.tryParse(_monthlyAdditionController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculateFutureValue(
        presentValue: _presentValue,
        rate: _annualRate,
        years: _years,
        monthlyAddition: _monthlyAddition,
      );
    });
  }

  void _reset() {
    setState(() {
      _presentValueController.clear();
      _monthlyAdditionController.clear();
      _annualRate = 8.0;
      _years = 10;
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
                  buildSectionTitle('Investment Details'),
                  AppTextField(
                    label: 'Present Value',
                    hint: '100000',
                    controller: _presentValueController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Monthly Addition',
                    hint: '5000',
                    controller: _monthlyAdditionController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
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
                    label: 'Expected Annual Return',
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
                  AppSliderField(
                    label: 'Investment Period',
                    value: _years.toDouble(),
                    min: 1,
                    max: 40,
                    divisions: 39,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _years = v.toInt();
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Future Value',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.futureValue,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
                  label: 'Total Contributions',
                  value: NumberFormatter.formatCurrency(r.totalContributions,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Interest',
                  value: NumberFormatter.formatCurrency(r.totalInterest,
                      symbol: symbol),
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
                label: 'Present Value',
                value: NumberFormatter.formatCurrency(_presentValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Monthly Addition',
                value: NumberFormatter.formatCurrency(_monthlyAddition,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Total Contributions',
                value: NumberFormatter.formatCurrency(
                    r.totalContributions, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Interest Earned',
                value: NumberFormatter.formatCurrency(r.totalInterest,
                    symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Future Value',
                value: NumberFormatter.formatCurrency(r.futureValue,
                    symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
import '../../domain/retirement_calculators.dart';

class RetirementCorpusScreen extends CalculatorBaseScreen {
  const RetirementCorpusScreen({super.key})
      : super(
          calculatorId: 'retirement_corpus',
          calculatorName: 'Retirement Corpus Calculator',
          category: 'Retirement',
        );

  @override
  ConsumerState<RetirementCorpusScreen> createState() => _RetirementCorpusScreenState();
}

class _RetirementCorpusScreenState extends CalculatorBaseState<RetirementCorpusScreen> {
  final _expenseController = TextEditingController();
  final _savingsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentAge = 30;
  int _retirementAge = 60;
  int _lifeExpectancy = 85;
  double _inflation = 6.0;
  double _returnRate = 10.0;
  RetirementCorpusResult? _result;

  @override
  void dispose() {
    _expenseController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _expenseValue => NumberFormatter.tryParse(_expenseController.text) ?? 0;
  double get _savingsValue => NumberFormatter.tryParse(_savingsController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Age': '$_currentAge',
        'Retirement Age': '$_retirementAge',
        'Life Expectancy': '$_lifeExpectancy',
        'Monthly Expense': NumberFormatter.formatCurrency(_expenseValue, symbol: _symbol),
        'Current Savings': NumberFormatter.formatCurrency(_savingsValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Corpus Needed': NumberFormatter.formatCurrency(_result!.corpusNeeded, symbol: _symbol),
        'Monthly Savings Needed': NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol),
        'Shortfall': NumberFormatter.formatCurrency(_result!.shortfall, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Corpus: ${NumberFormatter.formatCurrency(_result!.corpusNeeded, symbol: _symbol)} | '
          'Monthly Savings: ${NumberFormatter.formatCurrency(_result!.monthlySavingsNeeded, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_expenseValue <= 0) return;

    setState(() {
      _result = RetirementCalculators.calculateRetirementCorpus(
        currentAge: _currentAge,
        retirementAge: _retirementAge,
        lifeExpectancy: _lifeExpectancy,
        monthlyExpense: _expenseValue,
        inflation: _inflation,
        returnRate: _returnRate,
        currentSavings: _savingsValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _expenseController.clear();
      _savingsController.clear();
      _currentAge = 30;
      _retirementAge = 60;
      _lifeExpectancy = 85;
      _inflation = 6.0;
      _returnRate = 10.0;
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
                  buildSectionTitle('Personal Details'),
                  Row(
                    children: [
                      Expanded(
                        child: AppSliderField(
                          label: 'Current Age',
                          value: _currentAge.toDouble(),
                          min: 18, max: 70, divisions: 52,
                          displayValue: (v) => '${v.toInt()} yrs',
                          onChanged: (v) => setState(() { _currentAge = v.toInt(); _result = null; }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppSliderField(
                          label: 'Retirement Age',
                          value: _retirementAge.toDouble(),
                          min: 30, max: 70, divisions: 40,
                          displayValue: (v) => '${v.toInt()} yrs',
                          onChanged: (v) => setState(() { _retirementAge = v.toInt(); _result = null; }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Life Expectancy',
                    value: _lifeExpectancy.toDouble(),
                    min: 70, max: 100, divisions: 30,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() { _lifeExpectancy = v.toInt(); _result = null; }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Financial Details'),
                  AppTextField(
                    label: 'Current Monthly Expenses',
                    hint: '30000',
                    controller: _expenseController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Current Retirement Savings',
                    hint: '0',
                    controller: _savingsController,
                    prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return null; if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Return',
                    value: _returnRate,
                    min: 1, max: 20, divisions: 190,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _returnRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Inflation Rate',
                    value: _inflation,
                    min: 1, max: 15, divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _inflation = v; _result = null; }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Calculate', icon: Icons.calculate_rounded,
                    onPressed: _calculate, width: double.infinity,
                    color: AppColors.retirement,
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.retirement),
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
    final hasShortfall = r.shortfall > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Retirement Analysis'),
          Center(
            child: Column(
              children: [
                const Text('Required Corpus', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.corpusNeeded,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.retirement),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Monthly Savings Needed',
                    value: NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Inflated Monthly Expense',
                    value: NumberFormatter.formatCurrency(r.inflatedMonthlyExpense, symbol: symbol),
                    valueColor: AppColors.warning),
              ),
            ],
          ),
          if (hasShortfall) ...[
            const SizedBox(height: 10),
            ResultCard(
              label: 'Shortfall',
              value: NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
              isHighlighted: true,
              valueColor: AppColors.error,
              subtitle: 'Amount you need to save additionally',
            ),
          ] else ...[
            const SizedBox(height: 10),
            const ResultCard(
              label: 'Shortfall',
              value: 'No shortfall - you are on track!',
              isHighlighted: true,
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Corpus Analysis',
            items: [
              ResultItem(label: 'Current Age', value: '$_currentAge'),
              ResultItem(label: 'Retirement Age', value: '$_retirementAge'),
              ResultItem(label: 'Retirement Duration', value: '${_lifeExpectancy - _retirementAge} years'),
              ResultItem(label: 'Inflated Monthly Expense', value: NumberFormatter.formatCurrency(r.inflatedMonthlyExpense, symbol: symbol)),
              ResultItem(label: 'Corpus Needed', value: NumberFormatter.formatCurrency(r.corpusNeeded, symbol: symbol), isHighlighted: true, color: AppColors.retirement),
              ResultItem(label: 'Monthly Savings Needed', value: NumberFormatter.formatCurrency(r.monthlySavingsNeeded, symbol: symbol)),
              ResultItem(label: 'Shortfall', value: NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
                  color: hasShortfall ? AppColors.error : AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

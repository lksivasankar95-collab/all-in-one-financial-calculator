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
import '../../domain/utility_calculators.dart';

class InflationScreen extends CalculatorBaseScreen {
  const InflationScreen({super.key})
      : super(
          calculatorId: 'inflation',
          calculatorName: 'Inflation Calculator',
          category: 'Utility',
        );

  @override
  ConsumerState<InflationScreen> createState() => _InflationScreenState();
}

class _InflationScreenState extends CalculatorBaseState<InflationScreen> {
  final _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _inflationRate = 6.0;
  int _years = 10;
  InflationResult? _result;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _currentValue =>
      NumberFormatter.tryParse(_valueController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Value':
            NumberFormatter.formatCurrency(_currentValue, symbol: _symbol),
        'Inflation Rate': '${_inflationRate.toStringAsFixed(1)}%',
        'Years': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Future Value':
              NumberFormatter.formatCurrency(_result!.futureValue, symbol: _symbol),
          'Inflation Amount':
              NumberFormatter.formatCurrency(_result!.inflationAmount, symbol: _symbol),
          'Purchasing Power Loss':
              NumberFormatter.formatPercent(_result!.purchasingPowerLoss),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'In $_years years at ${_inflationRate.toStringAsFixed(1)}% inflation, '
          '${NumberFormatter.formatCurrency(_currentValue, symbol: _symbol)} will cost '
          '${NumberFormatter.formatCurrency(_result!.futureValue, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentValue <= 0) return;

    setState(() {
      _result = UtilityCalculators.calculateInflation(
        currentValue: _currentValue,
        inflationRate: _inflationRate,
        years: _years,
      );
    });
  }

  void _reset() {
    setState(() {
      _valueController.clear();
      _inflationRate = 6.0;
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
                  buildSectionTitle('Inflation Details'),
                  AppTextField(
                    label: 'Current Value',
                    hint: '1,00,000',
                    controller: _valueController,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Inflation Rate',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.utility.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.utility.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${_inflationRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppColors.utility,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _inflationRate,
                        min: 1,
                        max: 15,
                        divisions: 28,
                        activeColor: AppColors.utility,
                        onChanged: (v) => setState(() {
                          _inflationRate = v;
                          _result = null;
                        }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('1%',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                          Text('15%',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Years',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.utility.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.utility.withOpacity(0.3)),
                            ),
                            child: Text(
                              '$_years ${_years == 1 ? "yr" : "yrs"}',
                              style: const TextStyle(
                                color: AppColors.utility,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _years.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: AppColors.utility,
                        onChanged: (v) => setState(() {
                          _years = v.toInt();
                          _result = null;
                        }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('1 yr',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                          Text('30 yrs',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ],
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
                          color: AppColors.utility,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.utility,
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
    final realValue = _currentValue / (r.futureValue / _currentValue);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Inflation Impact'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.utility.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.utility.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Future Value in $_years ${_years == 1 ? "year" : "years"}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.futureValue,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.utility,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Inflation Amount',
                  value: NumberFormatter.formatCurrency(r.inflationAmount,
                      symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Purchasing Power Loss',
                  value: NumberFormatter.formatPercent(r.purchasingPowerLoss),
                  valueColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Current Value',
                value: NumberFormatter.formatCurrency(_currentValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Inflation Rate',
                value: '${_inflationRate.toStringAsFixed(1)}% per year',
              ),
              ResultItem(
                label: 'Period',
                value: '$_years ${_years == 1 ? "year" : "years"}',
              ),
              ResultItem(
                label: 'Future Value',
                value: NumberFormatter.formatCurrency(r.futureValue,
                    symbol: symbol),
                isHighlighted: true,
                color: AppColors.utility,
              ),
              ResultItem(
                label: 'Real Value Today',
                value: NumberFormatter.formatCurrency(realValue,
                    symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Purchasing Power Loss',
                value: NumberFormatter.formatPercent(r.purchasingPowerLoss),
                isHighlighted: true,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

class PresentValueScreen extends CalculatorBaseScreen {
  const PresentValueScreen({super.key})
      : super(
          calculatorId: 'present_value',
          calculatorName: 'Present Value Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<PresentValueScreen> createState() =>
      _PresentValueScreenState();
}

class _PresentValueScreenState extends CalculatorBaseState<PresentValueScreen> {
  final _futureValueController = TextEditingController();
  double _discountRate = 8.0;
  int _years = 10;
  PresentValueResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _futureValueController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Future Value':
            NumberFormatter.formatCurrency(_futureValue, symbol: _symbol),
        'Discount Rate': NumberFormatter.formatPercent(_discountRate),
        'Period': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Present Value':
              NumberFormatter.formatCurrency(_result!.presentValue, symbol: _symbol),
          'Total Discount':
              NumberFormatter.formatCurrency(_result!.totalDiscount, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'PV: ${NumberFormatter.formatCurrency(_result!.presentValue, symbol: _symbol)} | '
          'Discount: ${NumberFormatter.formatCurrency(_result!.totalDiscount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _futureValue =>
      NumberFormatter.tryParse(_futureValueController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculatePresentValue(
        futureValue: _futureValue,
        rate: _discountRate,
        years: _years,
      );
    });
  }

  void _reset() {
    setState(() {
      _futureValueController.clear();
      _discountRate = 8.0;
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
                  buildSectionTitle('Discounting Details'),
                  AppTextField(
                    label: 'Future Value',
                    hint: '500000',
                    controller: _futureValueController,
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
                    label: 'Discount Rate',
                    value: _discountRate,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _discountRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Time Period',
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
                  'Present Value',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.presentValue,
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
          ResultCard(
            label: 'Total Discount',
            value: NumberFormatter.formatCurrency(r.totalDiscount, symbol: symbol),
            isHighlighted: true,
            valueColor: AppColors.warning,
            subtitle:
                'Discounted at ${_discountRate.toStringAsFixed(1)}% for $_years years',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Future Value',
                value: NumberFormatter.formatCurrency(_futureValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Present Value',
                value: NumberFormatter.formatCurrency(r.presentValue, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Total Discount',
                value: NumberFormatter.formatCurrency(r.totalDiscount, symbol: symbol),
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

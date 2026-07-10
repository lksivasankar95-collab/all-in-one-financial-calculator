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

class CagrScreen extends CalculatorBaseScreen {
  const CagrScreen({super.key})
      : super(
          calculatorId: 'cagr',
          calculatorName: 'CAGR Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<CagrScreen> createState() => _CagrScreenState();
}

class _CagrScreenState extends CalculatorBaseState<CagrScreen> {
  final _initialController = TextEditingController();
  final _finalController = TextEditingController();
  final _yearsController = TextEditingController();
  double? _cagr;
  double? _totalGrowth;
  double? _absoluteGain;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _initialController.dispose();
    _finalController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _cagr != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Initial Value':
            NumberFormatter.formatCurrency(_initialValue, symbol: _symbol),
        'Final Value':
            NumberFormatter.formatCurrency(_finalValue, symbol: _symbol),
        'Duration': '$_yearsValue years',
      };

  @override
  Map<String, dynamic> get currentResults => _cagr == null
      ? {}
      : {
          'CAGR': NumberFormatter.formatPercent(_cagr!),
          'Total Growth': NumberFormatter.formatPercent(_totalGrowth ?? 0),
          'Absolute Gain':
              NumberFormatter.formatCurrency(_absoluteGain ?? 0, symbol: _symbol),
        };

  @override
  String get resultSummary => _cagr == null
      ? ''
      : 'CAGR: ${NumberFormatter.formatPercent(_cagr!)} | '
          '${NumberFormatter.formatCurrency(_initialValue, symbol: _symbol)} → '
          '${NumberFormatter.formatCurrency(_finalValue, symbol: _symbol)} '
          'in $_yearsValue yrs';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _initialValue =>
      NumberFormatter.tryParse(_initialController.text) ?? 0;
  double get _finalValue =>
      NumberFormatter.tryParse(_finalController.text) ?? 0;
  int get _yearsValue =>
      int.tryParse(_yearsController.text.trim()) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final cagr = InvestmentCalculators.calculateCagr(
      startValue: _initialValue,
      endValue: _finalValue,
      years: _yearsValue,
    );
    final gain = _finalValue - _initialValue;
    final totalGrowth =
        _initialValue > 0 ? (gain / _initialValue) * 100 : 0.0;

    setState(() {
      _cagr = cagr;
      _absoluteGain = gain;
      _totalGrowth = totalGrowth;
    });
  }

  void _reset() {
    setState(() {
      _initialController.clear();
      _finalController.clear();
      _yearsController.clear();
      _cagr = null;
      _absoluteGain = null;
      _totalGrowth = null;
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
                  buildSectionTitle('Investment Values'),
                  AppTextField(
                    label: 'Initial Investment Value',
                    hint: '1,00,000',
                    controller: _initialController,
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
                      if (_cagr != null) setState(() => _cagr = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Final Investment Value',
                    hint: '2,50,000',
                    controller: _finalController,
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
                      if (_cagr != null) setState(() => _cagr = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Duration (Years)',
                    hint: '5',
                    controller: _yearsController,
                    keyboardType: TextInputType.number,
                    suffix: 'yrs',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final years = int.tryParse(v.trim()) ?? 0;
                      if (years <= 0) return 'Enter a valid number of years';
                      return null;
                    },
                    onChanged: (_) {
                      if (_cagr != null) setState(() => _cagr = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate CAGR',
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
            if (_cagr != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final cagr = _cagr!;
    final gain = _absoluteGain!;
    final totalGrowth = _totalGrowth!;
    final isProfit = gain >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('CAGR Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'CAGR',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: cagr,
                  formatter: NumberFormatter.formatPercent,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: isProfit ? AppColors.primary : AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compound Annual Growth Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
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
                  label: 'Total Growth',
                  value: NumberFormatter.formatPercent(totalGrowth),
                  valueColor:
                      isProfit ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: isProfit ? 'Absolute Gain' : 'Absolute Loss',
                  value: NumberFormatter.formatCurrency(gain.abs(),
                      symbol: symbol),
                  valueColor:
                      isProfit ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Initial Value',
                value: NumberFormatter.formatCurrency(_initialValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Final Value',
                value: NumberFormatter.formatCurrency(_finalValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Duration',
                value: '$_yearsValue years',
              ),
              ResultItem(
                label: isProfit ? 'Net Gain' : 'Net Loss',
                value: NumberFormatter.formatCurrency(gain.abs(),
                    symbol: symbol),
                color: isProfit ? AppColors.success : AppColors.error,
              ),
              ResultItem(
                label: 'Total Growth',
                value: NumberFormatter.formatPercent(totalGrowth),
                color: isProfit ? AppColors.success : AppColors.error,
              ),
              ResultItem(
                label: 'CAGR',
                value: NumberFormatter.formatPercent(cagr),
                isHighlighted: true,
                color: isProfit ? AppColors.primary : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

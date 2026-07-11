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

class AnnualizedReturnScreen extends CalculatorBaseScreen {
  const AnnualizedReturnScreen({super.key})
      : super(
          calculatorId: 'annualized_return',
          calculatorName: 'Annualized Return',
          category: 'Investment',
        );

  @override
  ConsumerState<AnnualizedReturnScreen> createState() =>
      _AnnualizedReturnScreenState();
}

class _AnnualizedReturnScreenState
    extends CalculatorBaseState<AnnualizedReturnScreen> {
  final _initialController = TextEditingController();
  final _finalController = TextEditingController();
  int _years = 5;
  double? _annualizedReturn;
  double? _totalReturn;
  double? _growthFactor;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _initialController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _annualizedReturn != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Initial Value':
            NumberFormatter.formatCurrency(_initialValue, symbol: _symbol),
        'Final Value':
            NumberFormatter.formatCurrency(_finalValue, symbol: _symbol),
        'Time Period': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _annualizedReturn == null
      ? {}
      : {
          'Annualized Return':
              NumberFormatter.formatPercent(_annualizedReturn!),
          'Total Return': NumberFormatter.formatPercent(_totalReturn!),
          'Growth Factor': _growthFactor!.toStringAsFixed(2) + 'x',
        };

  @override
  String get resultSummary => _annualizedReturn == null
      ? ''
      : 'Annualized Return: ${NumberFormatter.formatPercent(_annualizedReturn!)} | '
          'Total: ${NumberFormatter.formatPercent(_totalReturn!)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _initialValue =>
      NumberFormatter.tryParse(_initialController.text) ?? 0;
  double get _finalValue =>
      NumberFormatter.tryParse(_finalController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final initial = _initialValue;
    final finalVal = _finalValue;
    if (initial <= 0 || finalVal <= 0 || _years <= 0) return;

    final annualized = (pow(finalVal / initial, 1 / _years) - 1) * 100;
    final totalRet = ((finalVal - initial) / initial) * 100;
    final growth = finalVal / initial;

    setState(() {
      _annualizedReturn = annualized;
      _totalReturn = totalRet;
      _growthFactor = growth;
    });
  }

  void _reset() {
    setState(() {
      _initialController.clear();
      _finalController.clear();
      _years = 5;
      _annualizedReturn = null;
      _totalReturn = null;
      _growthFactor = null;
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
                      if (_annualizedReturn != null) {
                        setState(() => _annualizedReturn = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Final Investment Value',
                    hint: '5,00,000',
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
                      if (_annualizedReturn != null) {
                        setState(() => _annualizedReturn = null);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Time Period',
                    value: _years.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _years = v.toInt();
                        if (_annualizedReturn != null) {
                          _annualizedReturn = null;
                        }
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
            if (_annualizedReturn != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final annualized = _annualizedReturn!;
    final totalRet = _totalReturn!;
    final growth = _growthFactor!;
    final isProfit = annualized >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Return Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Annualized Return',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: annualized,
                  formatter: NumberFormatter.formatPercent,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: isProfit ? AppColors.primary : AppColors.error,
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
                  label: 'Total Return',
                  value: NumberFormatter.formatPercent(totalRet),
                  valueColor:
                      isProfit ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Growth Factor',
                  value: '${growth.toStringAsFixed(2)}x',
                  valueColor: AppColors.primary,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Return Summary',
            items: [
              ResultItem(
                label: 'Initial Value',
                value: NumberFormatter.formatCurrency(
                    _initialValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Final Value',
                value: NumberFormatter.formatCurrency(
                    _finalValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Time Period',
                value: '$_years ${_years == 1 ? "year" : "years"}',
              ),
              ResultItem(
                label: 'Total Return',
                value: NumberFormatter.formatPercent(totalRet),
                color: isProfit ? AppColors.success : AppColors.error,
              ),
              ResultItem(
                label: 'Growth Factor',
                value: '${growth.toStringAsFixed(2)}x',
              ),
              ResultItem(
                label: 'Annualized Return',
                value: NumberFormatter.formatPercent(annualized),
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

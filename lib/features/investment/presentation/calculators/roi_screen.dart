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

class RoiScreen extends CalculatorBaseScreen {
  const RoiScreen({super.key})
      : super(
          calculatorId: 'roi',
          calculatorName: 'ROI Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<RoiScreen> createState() => _RoiScreenState();
}

class _RoiScreenState extends CalculatorBaseState<RoiScreen> {
  final _costController = TextEditingController();
  final _finalValueController = TextEditingController();
  double? _roi;
  double? _netProfitLoss;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _costController.dispose();
    _finalValueController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _roi != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Investment Cost':
            NumberFormatter.formatCurrency(_costValue, symbol: _symbol),
        'Final Value':
            NumberFormatter.formatCurrency(_finalValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _roi == null
      ? {}
      : {
          'ROI': NumberFormatter.formatPercent(_roi!),
          'Net ${_isProfit ? "Profit" : "Loss"}':
              NumberFormatter.formatCurrency((_netProfitLoss ?? 0).abs(), symbol: _symbol),
        };

  @override
  String get resultSummary => _roi == null
      ? ''
      : 'ROI: ${NumberFormatter.formatPercent(_roi!)} | '
          '${_isProfit ? "Profit" : "Loss"}: '
          '${NumberFormatter.formatCurrency((_netProfitLoss ?? 0).abs(), symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _costValue =>
      NumberFormatter.tryParse(_costController.text) ?? 0;
  double get _finalValue =>
      NumberFormatter.tryParse(_finalValueController.text) ?? 0;
  bool get _isProfit => (_netProfitLoss ?? 0) >= 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final roi = InvestmentCalculators.calculateRoi(
      investmentCost: _costValue,
      finalValue: _finalValue,
    );
    setState(() {
      _roi = roi;
      _netProfitLoss = _finalValue - _costValue;
    });
  }

  void _reset() {
    setState(() {
      _costController.clear();
      _finalValueController.clear();
      _roi = null;
      _netProfitLoss = null;
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
                    label: 'Investment Cost',
                    hint: '1,00,000',
                    controller: _costController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid investment cost';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_roi != null) setState(() => _roi = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Final Value',
                    hint: '1,50,000',
                    controller: _finalValueController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid final value';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_roi != null) setState(() => _roi = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate ROI',
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
            if (_roi != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final roi = _roi!;
    final netAmount = _netProfitLoss!;
    final isProfit = netAmount >= 0;
    final resultColor = isProfit ? AppColors.success : AppColors.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('ROI Results'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: resultColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: resultColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isProfit ? 'PROFIT' : 'LOSS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: resultColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedResultValue(
                  value: roi,
                  formatter: NumberFormatter.formatPercent,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Return on Investment',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
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
                  label: 'Investment Cost',
                  value: NumberFormatter.formatCurrency(_costValue,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Final Value',
                  value: NumberFormatter.formatCurrency(_finalValue,
                      symbol: symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: isProfit ? 'Net Profit' : 'Net Loss',
            value: NumberFormatter.formatCurrency(netAmount.abs(),
                symbol: symbol),
            valueColor: resultColor,
            isHighlighted: true,
            subtitle: isProfit
                ? 'You gained on your investment'
                : 'You lost on your investment',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Investment Cost',
                value: NumberFormatter.formatCurrency(_costValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Final Value',
                value: NumberFormatter.formatCurrency(_finalValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: isProfit ? 'Net Profit' : 'Net Loss',
                value: NumberFormatter.formatCurrency(netAmount.abs(),
                    symbol: symbol),
                color: resultColor,
              ),
              ResultItem(
                label: 'ROI',
                value: NumberFormatter.formatPercent(roi),
                isHighlighted: true,
                color: resultColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

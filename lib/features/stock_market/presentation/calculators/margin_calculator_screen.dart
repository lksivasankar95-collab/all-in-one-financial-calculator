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

class MarginCalculatorScreen extends CalculatorBaseScreen {
  const MarginCalculatorScreen({super.key})
      : super(
          calculatorId: 'margin_calculator',
          calculatorName: 'Margin Calculator',
          category: 'Stock Market',
        );

  @override
  ConsumerState<MarginCalculatorScreen> createState() => _MarginCalculatorScreenState();
}

class _MarginCalculatorScreenState extends CalculatorBaseState<MarginCalculatorScreen> {
  final _tradeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _marginPct = 20;
  double _interestRate = 12.0;
  int _holdingDays = 30;
  double? _marginRequired;
  double? _interestCost;

  @override
  void dispose() {
    _tradeController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _marginRequired != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _tradeValue => NumberFormatter.tryParse(_tradeController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Trade Value': NumberFormatter.formatCurrency(_tradeValue, symbol: _symbol),
        'Margin %': NumberFormatter.formatPercent(_marginPct),
        'Interest Rate': NumberFormatter.formatPercent(_interestRate),
        'Holding Days': '$_holdingDays days',
      };

  @override
  Map<String, dynamic> get currentResults => _marginRequired == null ? {} : {
        'Margin Required': NumberFormatter.formatCurrency(_marginRequired!, symbol: _symbol),
        'Interest Cost': NumberFormatter.formatCurrency(_interestCost!, symbol: _symbol),
        'Total Cost': NumberFormatter.formatCurrency(_marginRequired! + _interestCost!, symbol: _symbol),
      };

  @override
  String get resultSummary => _marginRequired == null ? ''
      : 'Margin: ${NumberFormatter.formatCurrency(_marginRequired!, symbol: _symbol)} | '
          'Interest: ${NumberFormatter.formatCurrency(_interestCost!, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_tradeValue <= 0) return;

    final marginReq = _tradeValue * _marginPct / 100;
    final interest = marginReq * _interestRate / 100 * _holdingDays / 365;

    setState(() {
      _marginRequired = marginReq;
      _interestCost = interest;
    });
  }

  void _reset() {
    setState(() {
      _tradeController.clear();
      _marginPct = 20;
      _interestRate = 12.0;
      _holdingDays = 30;
      _marginRequired = null;
      _interestCost = null;
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
                  buildSectionTitle('Margin Trade Details'),
                  AppTextField(label: 'Total Trade Value', hint: '100000', controller: _tradeController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_marginRequired != null) setState(() { _marginRequired = null; _interestCost = null; }); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Margin Percentage', value: _marginPct,
                    min: 5, max: 50, divisions: 45,
                    displayValue: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() { _marginPct = v; _marginRequired = null; _interestCost = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Interest Rate (p.a.)', value: _interestRate,
                    min: 5, max: 20, divisions: 150,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _interestRate = v; _marginRequired = null; _interestCost = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Holding Period', value: _holdingDays.toDouble(),
                    min: 1, max: 365, divisions: 364,
                    displayValue: (v) => '${v.toInt()} days',
                    onChanged: (v) => setState(() { _holdingDays = v.toInt(); _marginRequired = null; _interestCost = null; }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Calculate', icon: Icons.calculate_rounded,
                            onPressed: _calculate, width: double.infinity, color: AppColors.stockMarket),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.stockMarket),
                    ],
                  ),
                ],
              ),
            ),
            if (_marginRequired != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final marginReq = _marginRequired!;
    final interest = _interestCost!;
    final totalCost = marginReq + interest;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Margin Analysis'),
          Center(
            child: Column(
              children: [
                const Text('Margin Required', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: marginReq,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.stockMarket),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Interest Cost',
                    value: NumberFormatter.formatCurrency(interest, symbol: symbol),
                    valueColor: AppColors.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Cost (Margin + Interest)',
                    value: NumberFormatter.formatCurrency(totalCost, symbol: symbol)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Leverage Ratio',
            value: '${(_tradeValue / marginReq).toStringAsFixed(1)}x',
            isHighlighted: true,
            subtitle: '$_holdingDays days @ ${_interestRate.toStringAsFixed(1)}% p.a.',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Margin Summary',
            items: [
              ResultItem(label: 'Trade Value', value: NumberFormatter.formatCurrency(_tradeValue, symbol: symbol)),
              ResultItem(label: 'Margin %', value: NumberFormatter.formatPercent(_marginPct)),
              ResultItem(label: 'Margin Required', value: NumberFormatter.formatCurrency(marginReq, symbol: symbol), isHighlighted: true),
              ResultItem(label: 'Broker Borrowing', value: NumberFormatter.formatCurrency(_tradeValue - marginReq, symbol: symbol)),
              ResultItem(label: 'Interest Cost', value: NumberFormatter.formatCurrency(interest, symbol: symbol), color: AppColors.error),
              ResultItem(label: 'Total Cost', value: NumberFormatter.formatCurrency(totalCost, symbol: symbol), isHighlighted: true, color: AppColors.stockMarket),
            ],
          ),
        ],
      ),
    );
  }
}

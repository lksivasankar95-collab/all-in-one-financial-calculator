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
import '../../domain/stock_market_calculators.dart';

class PositionSizeScreen extends CalculatorBaseScreen {
  const PositionSizeScreen({super.key})
      : super(
          calculatorId: 'position_size',
          calculatorName: 'Position Size Calculator',
          category: 'Stock Market',
        );

  @override
  ConsumerState<PositionSizeScreen> createState() => _PositionSizeScreenState();
}

class _PositionSizeScreenState extends CalculatorBaseState<PositionSizeScreen> {
  final _accountController = TextEditingController();
  final _entryController = TextEditingController();
  final _stopController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _riskPercent = 2.0;
  PositionSizeResult? _result;

  @override
  void dispose() {
    _accountController.dispose();
    _entryController.dispose();
    _stopController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _accountValue => NumberFormatter.tryParse(_accountController.text) ?? 0;
  double get _entryValue => NumberFormatter.tryParse(_entryController.text) ?? 0;
  double get _stopValue => NumberFormatter.tryParse(_stopController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Account Size': NumberFormatter.formatCurrency(_accountValue, symbol: _symbol),
        'Risk %': NumberFormatter.formatPercent(_riskPercent),
        'Entry Price': NumberFormatter.formatCurrency(_entryValue, symbol: _symbol),
        'Stop Loss': NumberFormatter.formatCurrency(_stopValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Position Size': NumberFormatter.formatCurrency(_result!.positionSize, symbol: _symbol),
        'Shares': '${_result!.quantity}',
        'Risk Amount': NumberFormatter.formatCurrency(_result!.riskAmount, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Position: ${NumberFormatter.formatCurrency(_result!.positionSize, symbol: _symbol)} | '
          'Shares: ${_result!.quantity} | Risk: ${NumberFormatter.formatCurrency(_result!.riskAmount, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_accountValue <= 0 || _entryValue <= 0 || _stopValue <= 0) return;

    setState(() {
      _result = StockMarketCalculators.calculatePositionSize(
        accountSize: _accountValue,
        riskPercent: _riskPercent,
        entryPrice: _entryValue,
        stopLoss: _stopValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _accountController.clear();
      _entryController.clear();
      _stopController.clear();
      _riskPercent = 2.0;
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
                  buildSectionTitle('Account & Risk'),
                  AppTextField(label: 'Account Size', hint: '500000', controller: _accountController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Risk per Trade', value: _riskPercent,
                    min: 0.5, max: 5, divisions: 45,
                    displayValue: (v) => '${v.toStringAsFixed(1)}% (${NumberFormatter.formatCurrency(_accountValue * v / 100, symbol: symbol)})',
                    onChanged: (v) => setState(() { _riskPercent = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(label: 'Entry Price', hint: '250', controller: _entryController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Stop Loss Price', hint: '235', controller: _stopController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
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
          buildSectionTitle('Position Sizing'),
          Center(
            child: Column(
              children: [
                const Text('Position Size', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.positionSize,
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
                child: ResultCard(label: 'Shares to Buy',
                    value: '${r.quantity}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Risk Amount',
                    value: NumberFormatter.formatCurrency(r.riskAmount, symbol: symbol),
                    valueColor: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Actual Risk',
            value: NumberFormatter.formatCurrency(r.actualRisk, symbol: symbol),
            isHighlighted: true,
            subtitle: '${(r.actualRisk / _accountValue * 100).toStringAsFixed(2)}% of account',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Position Summary',
            items: [
              ResultItem(label: 'Account Size', value: NumberFormatter.formatCurrency(_accountValue, symbol: symbol)),
              ResultItem(label: 'Risk %', value: NumberFormatter.formatPercent(_riskPercent)),
              ResultItem(label: 'Entry Price', value: NumberFormatter.formatCurrency(_entryValue, symbol: symbol)),
              ResultItem(label: 'Stop Loss', value: NumberFormatter.formatCurrency(_stopValue, symbol: symbol)),
              ResultItem(label: 'Shares to Buy', value: '${r.quantity}', isHighlighted: true),
              ResultItem(label: 'Position Size', value: NumberFormatter.formatCurrency(r.positionSize, symbol: symbol), isHighlighted: true, color: AppColors.stockMarket),
              ResultItem(label: 'Risk Amount', value: NumberFormatter.formatCurrency(r.riskAmount, symbol: symbol), color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

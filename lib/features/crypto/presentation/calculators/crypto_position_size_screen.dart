import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../domain/crypto_calculators.dart';

class CryptoPositionSizeScreen extends CalculatorBaseScreen {
  const CryptoPositionSizeScreen({super.key})
      : super(
          calculatorId: 'crypto_position_size',
          calculatorName: 'Crypto Position Size Calculator',
          category: 'Crypto',
        );

  @override
  ConsumerState<CryptoPositionSizeScreen> createState() => _CryptoPositionSizeScreenState();
}

class _CryptoPositionSizeScreenState extends CalculatorBaseState<CryptoPositionSizeScreen> {
  final _portfolioController = TextEditingController();
  final _entryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _riskPercent = 2.0;
  double _stopLossPercent = 10.0;
  PositionSizeResult? _result;

  @override
  void dispose() {
    _portfolioController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _portfolioValue => NumberFormatter.tryParse(_portfolioController.text) ?? 0;
  double get _entryValue => NumberFormatter.tryParse(_entryController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Portfolio Size': '\$${_portfolioValue.toStringAsFixed(2)}',
        'Risk %': NumberFormatter.formatPercent(_riskPercent),
        'Entry Price': '\$${_entryValue.toStringAsFixed(2)}',
        'Stop Loss %': NumberFormatter.formatPercent(_stopLossPercent),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Position Size': '\$${_result!.positionSize.toStringAsFixed(2)}',
        'Units to Buy': _result!.quantity.toStringAsFixed(4),
        'Risk Amount': '\$${_result!.riskAmount.toStringAsFixed(2)}',
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Position: \$${_result!.positionSize.toStringAsFixed(2)} | '
          'Units: ${_result!.quantity.toStringAsFixed(4)} | '
          'Risk: \$${_result!.riskAmount.toStringAsFixed(2)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_portfolioValue <= 0 || _entryValue <= 0) return;

    setState(() {
      _result = CryptoCalculators.calculateCryptoPositionSize(
        accountSize: _portfolioValue,
        riskPercent: _riskPercent,
        entryPrice: _entryValue,
        stopLossPercent: _stopLossPercent,
      );
    });
  }

  void _reset() {
    setState(() {
      _portfolioController.clear();
      _entryController.clear();
      _riskPercent = 2.0;
      _stopLossPercent = 10.0;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  buildSectionTitle('Portfolio & Risk'),
                  AppTextField(label: 'Portfolio Size (USD)', hint: '10000', controller: _portfolioController, prefix: '\$',
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Risk per Trade', value: _riskPercent,
                    min: 0.5, max: 5, divisions: 45,
                    displayValue: (v) => '${v.toStringAsFixed(1)}% (\$${(_portfolioValue * v / 100).toStringAsFixed(2)})',
                    onChanged: (v) => setState(() { _riskPercent = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(label: 'Entry Price (USD)', hint: '50000', controller: _entryController, prefix: '\$',
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Stop Loss % from Entry', value: _stopLossPercent,
                    min: 1, max: 50, divisions: 49,
                    displayValue: (v) => '${v.toStringAsFixed(0)}% (Stop at \$${(_entryValue * (1 - v / 100)).toStringAsFixed(2)})',
                    onChanged: (v) => setState(() { _stopLossPercent = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Calculate', icon: Icons.calculate_rounded,
                            onPressed: _calculate, width: double.infinity, color: AppColors.crypto),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.crypto),
                    ],
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
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
                  formatter: (v) => '\$${v.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.crypto),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Units to Buy',
                    value: r.quantity.toStringAsFixed(4)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Risk Amount',
                    value: '\$${r.riskAmount.toStringAsFixed(2)}',
                    valueColor: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Stop Loss Price',
            value: '\$${r.stopLossPrice.toStringAsFixed(2)}',
            isHighlighted: true,
            subtitle: '${(r.riskAmount / _portfolioValue * 100).toStringAsFixed(2)}% of portfolio at risk',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Position Summary',
            items: [
              ResultItem(label: 'Portfolio Size', value: '\$${_portfolioValue.toStringAsFixed(2)}'),
              ResultItem(label: 'Risk %', value: NumberFormatter.formatPercent(_riskPercent)),
              ResultItem(label: 'Entry Price', value: '\$${_entryValue.toStringAsFixed(2)}'),
              ResultItem(label: 'Stop Loss Price', value: '\$${r.stopLossPrice.toStringAsFixed(2)}'),
              ResultItem(label: 'Stop Loss %', value: NumberFormatter.formatPercent(_stopLossPercent)),
              ResultItem(label: 'Units to Buy', value: r.quantity.toStringAsFixed(4), isHighlighted: true),
              ResultItem(label: 'Position Size', value: '\$${r.positionSize.toStringAsFixed(2)}', isHighlighted: true, color: AppColors.crypto),
              ResultItem(label: 'Risk Amount', value: '\$${r.riskAmount.toStringAsFixed(2)}', color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

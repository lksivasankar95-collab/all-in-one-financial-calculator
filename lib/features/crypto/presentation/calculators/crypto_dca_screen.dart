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
import '../../domain/crypto_calculators.dart';

class CryptoDcaScreen extends CalculatorBaseScreen {
  const CryptoDcaScreen({super.key})
      : super(
          calculatorId: 'crypto_dca',
          calculatorName: 'Crypto DCA Calculator',
          category: 'Crypto',
        );

  @override
  ConsumerState<CryptoDcaScreen> createState() => _CryptoDcaScreenState();
}

class _CryptoDcaScreenState extends CalculatorBaseState<CryptoDcaScreen> {
  final _investmentController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _months = 12;
  double _volatility = 10;
  DcaResult? _result;

  @override
  void dispose() {
    _investmentController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _investmentValue => NumberFormatter.tryParse(_investmentController.text) ?? 0;
  double get _startValue => NumberFormatter.tryParse(_startController.text) ?? 0;
  double get _endValue => NumberFormatter.tryParse(_endController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Investment': '\$${_investmentValue.toStringAsFixed(2)}',
        'Start Price': '\$${_startValue.toStringAsFixed(2)}',
        'End Price': '\$${_endValue.toStringAsFixed(2)}',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Total Invested': '\$${_result!.totalInvested.toStringAsFixed(2)}',
        'Total Coins': _result!.totalShares.toStringAsFixed(4),
        'Average Cost': '\$${_result!.averageCost.toStringAsFixed(2)}',
        'Current Value': '\$${_result!.currentValue.toStringAsFixed(2)}',
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Invested: \$${_result!.totalInvested.toStringAsFixed(2)} | '
          'Value: \$${_result!.currentValue.toStringAsFixed(2)} | '
          'Avg Cost: \$${_result!.averageCost.toStringAsFixed(2)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_investmentValue <= 0 || _startValue <= 0 || _endValue <= 0) return;

    setState(() {
      _result = CryptoCalculators.calculateCryptoDCA(
        monthlyInvestment: _investmentValue,
        startPrice: _startValue,
        endPrice: _endValue,
        months: _months,
        volatility: _volatility,
      );
    });
  }

  void _reset() {
    setState(() {
      _investmentController.clear();
      _startController.clear();
      _endController.clear();
      _months = 12;
      _volatility = 10;
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
                  buildSectionTitle('DCA Settings'),
                  AppTextField(label: 'Monthly Investment (USD)', hint: '100', controller: _investmentController, prefix: '\$',
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Start Price (USD)', hint: '40000', controller: _startController, prefix: '\$',
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'End Price (USD)', hint: '60000', controller: _endController, prefix: '\$',
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Investment Period', value: _months.toDouble(),
                    min: 1, max: 60, divisions: 59,
                    displayValue: (v) => '${v.toInt()} months',
                    onChanged: (v) => setState(() { _months = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Price Volatility', value: _volatility,
                    min: 0, max: 20, divisions: 200,
                    displayValue: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() { _volatility = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Simulate DCA', icon: Icons.analytics_rounded,
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
    final isProfit = r.profitLoss >= 0;
    final lumpSumShares = _investmentValue * _months / _startValue;
    final lumpSumValue = lumpSumShares * _endValue;
    final dcaAdvantage = r.currentValue - lumpSumValue;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('DCA Results'),
          Center(
            child: Column(
              children: [
                const Text('Average Cost per Coin', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.averageCost,
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
                child: ResultCard(label: 'Total Invested',
                    value: '\$${r.totalInvested.toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Current Value',
                    value: '\$${r.currentValue.toStringAsFixed(2)}',
                    valueColor: isProfit ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Profit / Loss',
            value: '${isProfit ? '+' : '-'}\$${r.profitLoss.abs().toStringAsFixed(2)} (${isProfit ? '+' : ''}${NumberFormatter.formatPercent(r.profitLossPercent)})',
            isHighlighted: true,
            valueColor: isProfit ? AppColors.success : AppColors.error,
            subtitle: 'Total coins: ${r.totalShares.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'DCA vs Lump Sum',
            items: [
              ResultItem(label: 'Monthly Investment', value: '\$${_investmentValue.toStringAsFixed(2)}'),
              ResultItem(label: 'Total Invested', value: '\$${r.totalInvested.toStringAsFixed(2)}'),
              ResultItem(label: 'Total Coins Accumulated', value: r.totalShares.toStringAsFixed(4)),
              ResultItem(label: 'Average Cost (DCA)', value: '\$${r.averageCost.toStringAsFixed(2)}', isHighlighted: true, color: AppColors.crypto),
              ResultItem(label: 'Current Value', value: '\$${r.currentValue.toStringAsFixed(2)}'),
              ResultItem(label: 'P&L', value: '${isProfit ? '+' : '-'}\$${r.profitLoss.abs().toStringAsFixed(2)}',
                  color: isProfit ? AppColors.success : AppColors.error),
              ResultItem(label: 'DCA vs Lump Sum', value: dcaAdvantage >= 0 ? 'DCA wins by \$${dcaAdvantage.toStringAsFixed(2)}' : 'Lump sum wins by \$${dcaAdvantage.abs().toStringAsFixed(2)}',
                  color: dcaAdvantage >= 0 ? AppColors.success : AppColors.info),
            ],
          ),
        ],
      ),
    );
  }
}

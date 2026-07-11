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

class CryptoProfitScreen extends CalculatorBaseScreen {
  const CryptoProfitScreen({super.key})
      : super(
          calculatorId: 'crypto_profit',
          calculatorName: 'Crypto Profit Calculator',
          category: 'Crypto',
        );

  @override
  ConsumerState<CryptoProfitScreen> createState() => _CryptoProfitScreenState();
}

class _CryptoProfitScreenState extends CalculatorBaseState<CryptoProfitScreen> {
  final _entryController = TextEditingController();
  final _exitController = TextEditingController();
  final _qtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _fee = 1.0;
  CryptoProfitResult? _result;

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _entryValue => NumberFormatter.tryParse(_entryController.text) ?? 0;
  double get _exitValue => NumberFormatter.tryParse(_exitController.text) ?? 0;
  double get _qtyValue => NumberFormatter.tryParse(_qtyController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Entry Price': NumberFormatter.formatCurrency(_entryValue, symbol: _symbol),
        'Exit Price': NumberFormatter.formatCurrency(_exitValue, symbol: _symbol),
        'Quantity': _qtyValue.toStringAsFixed(4),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Total Entry Cost': NumberFormatter.formatCurrency(_result!.totalEntry, symbol: _symbol),
        'Total Exit Value': NumberFormatter.formatCurrency(_result!.totalExit, symbol: _symbol),
        'Net P&L': NumberFormatter.formatCurrency(_result!.profitLoss, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'P&L: ${NumberFormatter.formatCurrency(_result!.profitLoss, symbol: _symbol)} | '
          'ROI: ${NumberFormatter.formatPercent(_result!.profitLossPercent)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_entryValue <= 0 || _exitValue <= 0 || _qtyValue <= 0) return;

    setState(() {
      _result = CryptoCalculators.calculateCryptoProfit(
        entryPrice: _entryValue,
        exitPrice: _exitValue,
        quantity: _qtyValue,
        fee: _fee,
      );
    });
  }

  void _reset() {
    setState(() {
      _entryController.clear();
      _exitController.clear();
      _qtyController.clear();
      _fee = 1.0;
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
                  buildSectionTitle('Trade Details'),
                  AppTextField(label: 'Entry Price (USD)', hint: '45000', controller: _entryController, prefix: '\$',
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Exit Price (USD)', hint: '52000', controller: _exitController, prefix: '\$',
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Quantity (Coins/Tokens)', hint: '0.5', controller: _qtyController,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Exchange Fee', value: _fee,
                    min: 0, max: 5, divisions: 50,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _fee = v; _result = null; }),
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
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final isProfit = r.profitLoss >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Profit / Loss'),
          Center(
            child: Column(
              children: [
                const Text('Net Profit / Loss', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.profitLoss.abs(),
                  formatter: (v) => '${isProfit ? '+' : '-'}${NumberFormatter.formatCurrency(v, symbol: symbol)}',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                      color: isProfit ? AppColors.success : AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Total Entry Cost',
                    value: NumberFormatter.formatCurrency(r.totalEntry, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Exit Value',
                    value: NumberFormatter.formatCurrency(r.totalExit, symbol: symbol)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'ROI',
            value: '${isProfit ? '+' : ''}${NumberFormatter.formatPercent(r.profitLossPercent)}',
            isHighlighted: true,
            valueColor: isProfit ? AppColors.success : AppColors.error,
            subtitle: 'Total fees paid: ${NumberFormatter.formatCurrency(r.totalFees, symbol: symbol)}',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'P&L Summary',
            items: [
              ResultItem(label: 'Entry Value', value: NumberFormatter.formatCurrency(r.totalEntry, symbol: symbol)),
              ResultItem(label: 'Exit Value', value: NumberFormatter.formatCurrency(r.totalExit, symbol: symbol)),
              ResultItem(label: 'Fees Paid', value: NumberFormatter.formatCurrency(r.totalFees, symbol: symbol)),
              ResultItem(label: 'Net P&L', value: '${isProfit ? '+' : '-'}${NumberFormatter.formatCurrency(r.profitLoss.abs(), symbol: symbol)}',
                  isHighlighted: true, color: isProfit ? AppColors.success : AppColors.error),
              ResultItem(label: 'ROI %', value: '${isProfit ? '+' : ''}${NumberFormatter.formatPercent(r.profitLossPercent)}'),
            ],
          ),
        ],
      ),
    );
  }
}

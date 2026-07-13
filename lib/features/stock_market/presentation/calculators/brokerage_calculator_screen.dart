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

class BrokerageCalculatorScreen extends CalculatorBaseScreen {
  const BrokerageCalculatorScreen({super.key})
      : super(
          calculatorId: 'brokerage_calculator',
          calculatorName: 'Brokerage Calculator',
          category: 'Stock Market',
        );

  @override
  ConsumerState<BrokerageCalculatorScreen> createState() => _BrokerageCalculatorScreenState();
}

class _BrokerageCalculatorScreenState extends CalculatorBaseState<BrokerageCalculatorScreen> {
  final _buyController = TextEditingController();
  final _sellController = TextEditingController();
  final _qtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _brokerage = 0.05;
  double _stt = 0.025;
  double _stampDuty = 0.003;
  double _gst = 18.0;
  double? _totalCharges;
  double? _netPnl;

  @override
  void dispose() {
    _buyController.dispose();
    _sellController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _netPnl != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _buyValue => NumberFormatter.tryParse(_buyController.text) ?? 0;
  double get _sellValue => NumberFormatter.tryParse(_sellController.text) ?? 0;
  int get _qtyValue => (NumberFormatter.tryParse(_qtyController.text) ?? 0).toInt();

  @override
  Map<String, dynamic> get currentInputs => {
        'Buy Price': NumberFormatter.formatCurrency(_buyValue, symbol: _symbol),
        'Sell Price': NumberFormatter.formatCurrency(_sellValue, symbol: _symbol),
        'Quantity': '$_qtyValue',
      };

  @override
  Map<String, dynamic> get currentResults => _netPnl == null ? {} : {
        'Total Charges': NumberFormatter.formatCurrency(_totalCharges!, symbol: _symbol),
        'Net P&L': NumberFormatter.formatCurrency(_netPnl!, symbol: _symbol),
      };

  @override
  String get resultSummary => _netPnl == null ? ''
      : 'Charges: ${NumberFormatter.formatCurrency(_totalCharges!, symbol: _symbol)} | '
          'Net: ${NumberFormatter.formatCurrency(_netPnl!, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_buyValue <= 0 || _sellValue <= 0 || _qtyValue <= 0) return;

    final buyTotal = _buyValue * _qtyValue;
    final sellTotal = _sellValue * _qtyValue;
    final grossPnl = sellTotal - buyTotal;

    final brokerageAmt = (buyTotal + sellTotal) * _brokerage / 100;
    final sttAmt = sellTotal * _stt / 100;
    final stampAmt = buyTotal * _stampDuty / 100;
    final gstAmt = brokerageAmt * _gst / 100;
    final totalCharges = brokerageAmt + sttAmt + stampAmt + gstAmt;

    setState(() {
      _totalCharges = totalCharges;
      _netPnl = grossPnl - totalCharges;
    });
  }

  void _reset() {
    setState(() {
      _buyController.clear();
      _sellController.clear();
      _qtyController.clear();
      _brokerage = 0.05;
      _stt = 0.025;
      _stampDuty = 0.003;
      _gst = 18.0;
      _totalCharges = null;
      _netPnl = null;
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
                  AppTextField(label: 'Buy Price', hint: '150', controller: _buyController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_netPnl != null) setState(() { _totalCharges = null; _netPnl = null; }); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Sell Price', hint: '175', controller: _sellController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_netPnl != null) setState(() { _totalCharges = null; _netPnl = null; }); }),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Quantity', hint: '100', controller: _qtyController,
                    keyboardType: TextInputType.number,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_netPnl != null) setState(() { _totalCharges = null; _netPnl = null; }); }),
                  const SizedBox(height: 20),
                  _buildChargesSection(),
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
            if (_totalCharges != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChargesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Charges', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        AppSliderField(label: 'Brokerage (%)', value: _brokerage, min: 0, max: 1, divisions: 100,
            displayValue: (v) => '${v.toStringAsFixed(2)}%',
            onChanged: (v) => setState(() { _brokerage = v; _totalCharges = null; _netPnl = null; })),
        const SizedBox(height: 12),
        AppSliderField(label: 'STT (%)', value: _stt, min: 0, max: 0.2, divisions: 20,
            displayValue: (v) => '${v.toStringAsFixed(3)}%',
            onChanged: (v) => setState(() { _stt = v; _totalCharges = null; _netPnl = null; })),
        const SizedBox(height: 12),
        AppSliderField(label: 'Stamp Duty (%)', value: _stampDuty, min: 0, max: 0.01, divisions: 100,
            displayValue: (v) => '${v.toStringAsFixed(3)}%',
            onChanged: (v) => setState(() { _stampDuty = v; _totalCharges = null; _netPnl = null; })),
        const SizedBox(height: 12),
        AppSliderField(label: 'GST on Brokerage (%)', value: _gst, min: 0, max: 18, divisions: 18,
            displayValue: (v) => '${v.toStringAsFixed(0)}%',
            onChanged: (v) => setState(() { _gst = v; _totalCharges = null; _netPnl = null; })),
      ],
    );
  }

  Widget _buildResultSection(String symbol) {
    final buyTotal = _buyValue * _qtyValue;
    final sellTotal = _sellValue * _qtyValue;
    final grossPnl = sellTotal - buyTotal;
    final isProfit = _netPnl! >= 0;
    final charges = _totalCharges!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Charges Breakdown'),
          Center(
            child: Column(
              children: [
                const Text('Net P&L', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: _netPnl!.abs(),
                  formatter: (v) => '${isProfit ? '+' : '-'}${NumberFormatter.formatCurrency(v, symbol: symbol)}',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                      color: isProfit ? AppColors.success : AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ResultCard(label: 'Total Charges', value: NumberFormatter.formatCurrency(charges, symbol: symbol),
              isHighlighted: true, valueColor: AppColors.error),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Detailed Breakdown',
            items: [
              ResultItem(label: 'Buy Value', value: NumberFormatter.formatCurrency(buyTotal, symbol: symbol)),
              ResultItem(label: 'Sell Value', value: NumberFormatter.formatCurrency(sellTotal, symbol: symbol)),
              ResultItem(label: 'Gross P&L', value: '${grossPnl >= 0 ? '+' : ''}${NumberFormatter.formatCurrency(grossPnl, symbol: symbol)}'),
              ResultItem(label: 'Brokerage', value: NumberFormatter.formatCurrency(buyTotal * _brokerage / 100 + sellTotal * _brokerage / 100, symbol: symbol)),
              ResultItem(label: 'STT', value: NumberFormatter.formatCurrency(sellTotal * _stt / 100, symbol: symbol)),
              ResultItem(label: 'Stamp Duty', value: NumberFormatter.formatCurrency(buyTotal * _stampDuty / 100, symbol: symbol)),
              ResultItem(label: 'GST', value: NumberFormatter.formatCurrency((buyTotal + sellTotal) * _brokerage / 100 * _gst / 100, symbol: symbol)),
              ResultItem(label: 'Total Charges', value: NumberFormatter.formatCurrency(charges, symbol: symbol), color: AppColors.error),
              ResultItem(label: 'Net P&L', value: '${isProfit ? '+' : '-'}${NumberFormatter.formatCurrency(_netPnl!.abs(), symbol: symbol)}',
                  isHighlighted: true, color: isProfit ? AppColors.success : AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

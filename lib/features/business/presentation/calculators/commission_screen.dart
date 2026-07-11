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
import '../../domain/business_calculators.dart';

class CommissionScreen extends CalculatorBaseScreen {
  const CommissionScreen({super.key})
      : super(
          calculatorId: 'commission',
          calculatorName: 'Commission Calculator',
          category: 'Business',
        );

  @override
  ConsumerState<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends CalculatorBaseState<CommissionScreen> {
  final _saleAmountController = TextEditingController();
  final _baseCommissionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _commissionRate = 5.0;
  CommissionResult? _result;

  @override
  void dispose() {
    _saleAmountController.dispose();
    _baseCommissionController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _saleValue =>
      NumberFormatter.tryParse(_saleAmountController.text) ?? 0;
  double get _baseCommValue =>
      NumberFormatter.tryParse(_baseCommissionController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Sale Amount':
            NumberFormatter.formatCurrency(_saleValue, symbol: _symbol),
        'Commission Rate': '${_commissionRate.toStringAsFixed(1)}%',
        'Base Commission':
            NumberFormatter.formatCurrency(_baseCommValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Commission Earned':
              NumberFormatter.formatCurrency(_result!.commission, symbol: _symbol),
          'Base Commission':
              NumberFormatter.formatCurrency(_baseCommValue, symbol: _symbol),
          'Total Earning':
              NumberFormatter.formatCurrency(_result!.totalEarning, symbol: _symbol),
          'Net Sale to Client':
              NumberFormatter.formatCurrency(_result!.netSale, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Sale: ${NumberFormatter.formatCurrency(_saleValue, symbol: _symbol)} @ '
          '${_commissionRate.toStringAsFixed(1)}% = '
          'Total Earning: ${NumberFormatter.formatCurrency(_result!.totalEarning, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_saleValue <= 0) return;

    setState(() {
      _result = BusinessCalculators.calculateCommission(
        saleAmount: _saleValue,
        commissionRate: _commissionRate,
        baseCommission: _baseCommValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _saleAmountController.clear();
      _baseCommissionController.clear();
      _commissionRate = 5.0;
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
                  buildSectionTitle('Commission Details'),
                  AppTextField(
                    label: 'Sale Amount',
                    hint: '1,00,000',
                    controller: _saleAmountController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid sale amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Commission Rate',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.business.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.business.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${_commissionRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppColors.business,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _commissionRate,
                        min: 0.5,
                        max: 50.0,
                        divisions: 99,
                        activeColor: AppColors.business,
                        onChanged: (v) => setState(() {
                          _commissionRate = v;
                          _result = null;
                        }),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0.5%',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                          Text('50%',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Base Commission (Fixed)',
                    hint: '0',
                    controller: _baseCommissionController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null &&
                          v.isNotEmpty &&
                          (NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid base commission';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
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
                          color: AppColors.business,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.business,
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
          buildSectionTitle('Commission Breakdown'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.business.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.business.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Earning',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalEarning,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.business,
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
                  label: 'Commission Earned',
                  value: NumberFormatter.formatCurrency(r.commission,
                      symbol: symbol),
                  valueColor: AppColors.business,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Net Sale to Client',
                  value: NumberFormatter.formatCurrency(r.netSale,
                      symbol: symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Earning Summary',
            items: [
              ResultItem(
                label: 'Sale Amount',
                value: NumberFormatter.formatCurrency(_saleValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Commission (${_commissionRate.toStringAsFixed(1)}%)',
                value: NumberFormatter.formatCurrency(r.commission,
                    symbol: symbol),
                color: AppColors.business,
              ),
              ResultItem(
                label: 'Base Commission (Fixed)',
                value: NumberFormatter.formatCurrency(_baseCommValue,
                    symbol: symbol),
                color: AppColors.business,
              ),
              ResultItem(
                label: 'Total Earning',
                value: NumberFormatter.formatCurrency(r.totalEarning,
                    symbol: symbol),
                isHighlighted: true,
                color: AppColors.business,
              ),
              ResultItem(
                label: 'Net Sale to Client',
                value: NumberFormatter.formatCurrency(r.netSale,
                    symbol: symbol),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

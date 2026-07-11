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

class XirrScreen extends CalculatorBaseScreen {
  const XirrScreen({super.key})
      : super(
          calculatorId: 'xirr',
          calculatorName: 'XIRR Calculator',
          category: 'Investment',
        );

  @override
  ConsumerState<XirrScreen> createState() => _XirrScreenState();
}

class _XirrScreenState extends CalculatorBaseState<XirrScreen> {
  final _amountControllers = <TextEditingController>[];
  final _dayControllers = <TextEditingController>[];
  XirrResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _addEntry();
    _addEntry();
  }

  @override
  void dispose() {
    for (final c in _amountControllers) {
      c.dispose();
    }
    for (final c in _dayControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Cash Flows': '${_amountControllers.length} entries',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'XIRR': NumberFormatter.formatPercent(_result!.xirr),
          'Total Invested':
              NumberFormatter.formatCurrency(_result!.totalInvestment, symbol: _symbol),
          'Total Value':
              NumberFormatter.formatCurrency(_result!.totalValue, symbol: _symbol),
          'Total Returns':
              NumberFormatter.formatCurrency(_result!.totalReturns, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'XIRR: ${NumberFormatter.formatPercent(_result!.xirr)} | '
          'Invested: ${NumberFormatter.formatCurrency(_result!.totalInvestment, symbol: _symbol)} | '
          'Value: ${NumberFormatter.formatCurrency(_result!.totalValue, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);

  void _addEntry() {
    setState(() {
      _amountControllers.add(TextEditingController());
      _dayControllers.add(TextEditingController(text: _amountControllers.length == 1 ? '0' : '365'));
      if (_result != null) _result = null;
    });
  }

  void _removeEntry(int index) {
    if (_amountControllers.length <= 2) return;
    setState(() {
      _amountControllers[index].dispose();
      _dayControllers[index].dispose();
      _amountControllers.removeAt(index);
      _dayControllers.removeAt(index);
      if (_result != null) _result = null;
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final cashFlows = <double>[];
    final days = <int>[];

    for (int i = 0; i < _amountControllers.length; i++) {
      final amount = NumberFormatter.tryParse(_amountControllers[i].text) ?? 0;
      final day = int.tryParse(_dayControllers[i].text) ?? 0;
      cashFlows.add(amount);
      days.add(day);
    }

    final hasNegative = cashFlows.any((cf) => cf < 0);
    final hasPositive = cashFlows.any((cf) => cf > 0);
    if (!hasNegative || !hasPositive) return;

    setState(() {
      _result = InvestmentCalculators.calculateXirr(
        cashFlows: cashFlows,
        days: days,
      );
    });
  }

  void _reset() {
    setState(() {
      for (final c in _amountControllers) {
        c.dispose();
      }
      for (final c in _dayControllers) {
        c.dispose();
      }
      _amountControllers.clear();
      _dayControllers.clear();
      _result = null;
    });
    _addEntry();
    _addEntry();
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
                  buildSectionTitle('Cash Flows'),
                  const Text(
                    'Enter negative values for investments, positive for returns.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_amountControllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              label: 'Amount ${i + 1}',
                              hint: i == 0 ? '-100000' : '+120000',
                              prefix: symbol,
                              controller: _amountControllers[i],
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                return null;
                              },
                              onChanged: (_) {
                                if (_result != null) {
                                  setState(() => _result = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              label: 'Day',
                              hint: '0',
                              controller: _dayControllers[i],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Req';
                                if (int.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                              onChanged: (_) {
                                if (_result != null) {
                                  setState(() => _result = null);
                                }
                              },
                            ),
                          ),
                          if (_amountControllers.length > 2)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.error,
                                size: 22,
                              ),
                              onPressed: () => _removeEntry(i),
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Add Cash Flow',
                    isOutlined: true,
                    icon: Icons.add_rounded,
                    onPressed: _addEntry,
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
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'XIRR',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.xirr,
                  formatter: (v) => NumberFormatter.formatPercent(v),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
                  label: 'Total Invested',
                  value: NumberFormatter.formatCurrency(r.totalInvestment, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Value',
                  value: NumberFormatter.formatCurrency(r.totalValue, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Total Returns',
            value: NumberFormatter.formatCurrency(r.totalReturns, symbol: symbol),
            isHighlighted: true,
            valueColor: r.totalReturns >= 0 ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Total Invested',
                value: NumberFormatter.formatCurrency(r.totalInvestment, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Value',
                value: NumberFormatter.formatCurrency(r.totalValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Returns',
                value: NumberFormatter.formatCurrency(r.totalReturns, symbol: symbol),
                color: r.totalReturns >= 0 ? AppColors.success : AppColors.error,
              ),
              ResultItem(
                label: 'XIRR',
                value: NumberFormatter.formatPercent(r.xirr),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

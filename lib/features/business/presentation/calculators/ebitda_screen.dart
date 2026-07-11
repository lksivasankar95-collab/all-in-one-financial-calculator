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

class EbitdaScreen extends CalculatorBaseScreen {
  const EbitdaScreen({super.key})
      : super(
          calculatorId: 'ebitda',
          calculatorName: 'EBITDA Calculator',
          category: 'Business',
        );

  @override
  ConsumerState<EbitdaScreen> createState() => _EbitdaScreenState();
}

class _EbitdaScreenState extends CalculatorBaseState<EbitdaScreen> {
  final _revenueController = TextEditingController();
  final _cogsController = TextEditingController();
  final _opexController = TextEditingController();
  final _depreciationController = TextEditingController();
  final _amortizationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  EbitdaResult? _result;

  @override
  void dispose() {
    _revenueController.dispose();
    _cogsController.dispose();
    _opexController.dispose();
    _depreciationController.dispose();
    _amortizationController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _revenue =>
      NumberFormatter.tryParse(_revenueController.text) ?? 0;
  double get _cogs => NumberFormatter.tryParse(_cogsController.text) ?? 0;
  double get _opex => NumberFormatter.tryParse(_opexController.text) ?? 0;
  double get _depreciation =>
      NumberFormatter.tryParse(_depreciationController.text) ?? 0;
  double get _amortization =>
      NumberFormatter.tryParse(_amortizationController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Revenue': NumberFormatter.formatCurrency(_revenue, symbol: _symbol),
        'COGS': NumberFormatter.formatCurrency(_cogs, symbol: _symbol),
        'Operating Expenses':
            NumberFormatter.formatCurrency(_opex, symbol: _symbol),
        'Depreciation':
            NumberFormatter.formatCurrency(_depreciation, symbol: _symbol),
        'Amortization':
            NumberFormatter.formatCurrency(_amortization, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Gross Profit':
              NumberFormatter.formatCurrency(_result!.grossProfit, symbol: _symbol),
          'EBITDA':
              NumberFormatter.formatCurrency(_result!.ebitda, symbol: _symbol),
          'EBITDA Margin':
              NumberFormatter.formatPercent(_result!.ebitdaMargin),
          'Net Operating Income':
              NumberFormatter.formatCurrency(_result!.operatingIncome, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'EBITDA: ${NumberFormatter.formatCurrency(_result!.ebitda, symbol: _symbol)} | '
          'Margin: ${NumberFormatter.formatPercent(_result!.ebitdaMargin)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_revenue <= 0) return;

    final double grossProfit = _revenue - _cogs;
    final double ebitda = grossProfit - _opex;
    final double ebitdaMargin =
        _revenue > 0 ? (ebitda / _revenue) * 100 : 0;
    final double operatingIncome = ebitda - _depreciation - _amortization;

    setState(() {
      _result = EbitdaResult(
        grossProfit: grossProfit,
        ebitda: ebitda,
        ebitdaMargin: ebitdaMargin,
        operatingIncome: operatingIncome,
      );
    });
  }

  void _reset() {
    setState(() {
      _revenueController.clear();
      _cogsController.clear();
      _opexController.clear();
      _depreciationController.clear();
      _amortizationController.clear();
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
                  buildSectionTitle('Income Statement'),
                  AppTextField(
                    label: 'Revenue (Total Sales)',
                    hint: '10,00,000',
                    controller: _revenueController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid revenue';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Cost of Goods Sold (COGS)',
                    hint: '4,00,000',
                    controller: _cogsController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid COGS';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Operating Expenses',
                    hint: '3,00,000',
                    controller: _opexController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid operating expenses';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Depreciation',
                    hint: '50,000',
                    controller: _depreciationController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid depreciation';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Amortization',
                    hint: '20,000',
                    controller: _amortizationController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amortization';
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
    final isEbitdaPositive = r.ebitda >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('EBITDA Analysis'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.business.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.business.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'EBITDA',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.ebitda,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isEbitdaPositive
                        ? AppColors.business
                        : AppColors.error,
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
                  label: 'EBITDA Margin',
                  value: NumberFormatter.formatPercent(r.ebitdaMargin),
                  valueColor: isEbitdaPositive
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Operating Income',
                  value: NumberFormatter.formatCurrency(
                      r.operatingIncome, symbol: symbol),
                  valueColor: r.operatingIncome >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Income Breakdown',
            items: [
              ResultItem(
                label: 'Revenue',
                value:
                    NumberFormatter.formatCurrency(_revenue, symbol: symbol),
              ),
              ResultItem(
                label: '(-) COGS',
                value: '- ${NumberFormatter.formatCurrency(_cogs, symbol: symbol)}',
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Gross Profit',
                value: NumberFormatter.formatCurrency(
                    r.grossProfit, symbol: symbol),
                color: AppColors.business,
              ),
              ResultItem(
                label: '(-) Operating Expenses',
                value: '- ${NumberFormatter.formatCurrency(_opex, symbol: symbol)}',
                color: AppColors.error,
              ),
              ResultItem(
                label: 'EBITDA',
                value: NumberFormatter.formatCurrency(
                    r.ebitda, symbol: symbol),
                isHighlighted: true,
                color: isEbitdaPositive
                    ? AppColors.business
                    : AppColors.error,
              ),
              ResultItem(
                label: '(-) Depreciation',
                value:
                    '- ${NumberFormatter.formatCurrency(_depreciation, symbol: symbol)}',
                color: AppColors.textHint,
              ),
              ResultItem(
                label: '(-) Amortization',
                value:
                    '- ${NumberFormatter.formatCurrency(_amortization, symbol: symbol)}',
                color: AppColors.textHint,
              ),
              ResultItem(
                label: 'Operating Income',
                value: NumberFormatter.formatCurrency(
                    r.operatingIncome, symbol: symbol),
                color: r.operatingIncome >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
              const ResultItem(label: '', value: ''),
              ResultItem(
                label: 'EBITDA Margin',
                value: NumberFormatter.formatPercent(r.ebitdaMargin),
                isHighlighted: true,
                color: isEbitdaPositive
                    ? AppColors.success
                    : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EbitdaResult {
  final double grossProfit;
  final double ebitda;
  final double ebitdaMargin;
  final double operatingIncome;

  const EbitdaResult({
    required this.grossProfit,
    required this.ebitda,
    required this.ebitdaMargin,
    required this.operatingIncome,
  });
}

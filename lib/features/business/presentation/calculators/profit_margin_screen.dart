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

class ProfitMarginScreen extends CalculatorBaseScreen {
  const ProfitMarginScreen({super.key})
      : super(
          calculatorId: 'profit_margin',
          calculatorName: 'Profit Margin',
          category: 'Business',
        );

  @override
  ConsumerState<ProfitMarginScreen> createState() => _ProfitMarginScreenState();
}

class _ProfitMarginScreenState extends CalculatorBaseState<ProfitMarginScreen> {
  final _revenueController = TextEditingController();
  final _cogsController = TextEditingController();
  final _opexController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ProfitResult? _result;

  @override
  void dispose() {
    _revenueController.dispose();
    _cogsController.dispose();
    _opexController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _revenueValue =>
      NumberFormatter.tryParse(_revenueController.text) ?? 0;
  double get _cogsValue =>
      NumberFormatter.tryParse(_cogsController.text) ?? 0;
  double get _opexValue =>
      NumberFormatter.tryParse(_opexController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Revenue': NumberFormatter.formatCurrency(_revenueValue, symbol: _symbol),
        'Cost of Goods Sold':
            NumberFormatter.formatCurrency(_cogsValue, symbol: _symbol),
        'Operating Expenses':
            NumberFormatter.formatCurrency(_opexValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Gross Profit':
              NumberFormatter.formatCurrency(_result!.grossProfit, symbol: _symbol),
          'Gross Margin': NumberFormatter.formatPercent(_result!.grossMargin),
          'Net Profit':
              NumberFormatter.formatCurrency(_result!.netProfit, symbol: _symbol),
          'Net Margin': NumberFormatter.formatPercent(_result!.netMargin),
          'Markup': NumberFormatter.formatPercent(_result!.markup),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Revenue: ${NumberFormatter.formatCurrency(_revenueValue, symbol: _symbol)} | '
          'Net Profit: ${NumberFormatter.formatCurrency(_result!.netProfit, symbol: _symbol)} '
          '(${NumberFormatter.formatPercent(_result!.netMargin)} margin)';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_revenueValue <= 0) return;

    setState(() {
      _result = BusinessCalculators.calculateProfitMargin(
        revenue: _revenueValue,
        costOfGoods: _cogsValue,
        operatingExpenses: _opexValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _revenueController.clear();
      _cogsController.clear();
      _opexController.clear();
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
                  buildSectionTitle('Business Financials'),
                  AppTextField(
                    label: 'Revenue (Total Sales)',
                    hint: '5,00,000',
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
                    hint: '2,50,000',
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
                    hint: '50,000',
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
    final isProfit = r.netProfit >= 0;
    final profitColor = isProfit ? AppColors.success : AppColors.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Profit Analysis'),
          // Gross Profit Card
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Gross Profit',
                  value: NumberFormatter.formatCurrency(r.grossProfit,
                      symbol: symbol),
                  subValue: '${NumberFormatter.formatPercent(r.grossMargin)} margin',
                  color: AppColors.business,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Net Profit',
                  value: NumberFormatter.formatCurrency(r.netProfit.abs(),
                      symbol: symbol),
                  subValue:
                      '${NumberFormatter.formatPercent(r.netMargin.abs())} margin',
                  color: profitColor,
                  isLoss: !isProfit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Gross Margin %',
                  value: NumberFormatter.formatPercent(r.grossMargin),
                  valueColor: AppColors.business,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Markup %',
                  value: NumberFormatter.formatPercent(r.markup),
                  valueColor: AppColors.business,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'P&L Summary',
            items: [
              ResultItem(
                label: 'Revenue',
                value: NumberFormatter.formatCurrency(_revenueValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: '(-) COGS',
                value: '- ${NumberFormatter.formatCurrency(_cogsValue, symbol: symbol)}',
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Gross Profit',
                value: NumberFormatter.formatCurrency(r.grossProfit,
                    symbol: symbol),
                color: AppColors.business,
              ),
              ResultItem(
                label: 'Gross Margin',
                value: NumberFormatter.formatPercent(r.grossMargin),
                color: AppColors.business,
              ),
              ResultItem(
                label: '(-) Operating Expenses',
                value: '- ${NumberFormatter.formatCurrency(_opexValue, symbol: symbol)}',
                color: AppColors.error,
              ),
              ResultItem(
                label: isProfit ? 'Net Profit' : 'Net Loss',
                value: NumberFormatter.formatCurrency(r.netProfit.abs(),
                    symbol: symbol),
                isHighlighted: true,
                color: profitColor,
              ),
              ResultItem(
                label: 'Net Margin',
                value: NumberFormatter.formatPercent(r.netMargin.abs()),
                isHighlighted: true,
                color: profitColor,
              ),
              ResultItem(
                label: 'Markup on COGS',
                value: NumberFormatter.formatPercent(r.markup),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color color;
  final bool isLoss;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    this.isLoss = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textHint),
              ),
              if (isLoss) ...[
                const SizedBox(width: 4),
                const Text(
                  'LOSS',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColors.error,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          AnimatedResultValue(
            value: double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0,
            formatter: (_) => value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
                fontSize: 11, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

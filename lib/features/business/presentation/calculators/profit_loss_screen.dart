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

class ProfitLossScreen extends CalculatorBaseScreen {
  const ProfitLossScreen({super.key})
      : super(
          calculatorId: 'profit_loss',
          calculatorName: 'P&L Calculator',
          category: 'Business',
        );

  @override
  ConsumerState<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends CalculatorBaseState<ProfitLossScreen> {
  final _revenueController = TextEditingController();
  final _cogsController = TextEditingController();
  final _salariesController = TextEditingController();
  final _rentController = TextEditingController();
  final _utilitiesController = TextEditingController();
  final _marketingController = TextEditingController();
  final _otherExpController = TextEditingController();
  final _otherIncController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PnLResult? _result;

  @override
  void dispose() {
    _revenueController.dispose();
    _cogsController.dispose();
    _salariesController.dispose();
    _rentController.dispose();
    _utilitiesController.dispose();
    _marketingController.dispose();
    _otherExpController.dispose();
    _otherIncController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _revenueValue =>
      NumberFormatter.tryParse(_revenueController.text) ?? 0;
  double get _cogsValue =>
      NumberFormatter.tryParse(_cogsController.text) ?? 0;
  double get _salariesValue =>
      NumberFormatter.tryParse(_salariesController.text) ?? 0;
  double get _rentValue =>
      NumberFormatter.tryParse(_rentController.text) ?? 0;
  double get _utilitiesValue =>
      NumberFormatter.tryParse(_utilitiesController.text) ?? 0;
  double get _marketingValue =>
      NumberFormatter.tryParse(_marketingController.text) ?? 0;
  double get _otherExpValue =>
      NumberFormatter.tryParse(_otherExpController.text) ?? 0;
  double get _otherIncValue =>
      NumberFormatter.tryParse(_otherIncController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Revenue':
            NumberFormatter.formatCurrency(_revenueValue, symbol: _symbol),
        'COGS': NumberFormatter.formatCurrency(_cogsValue, symbol: _symbol),
        'Salaries':
            NumberFormatter.formatCurrency(_salariesValue, symbol: _symbol),
        'Rent': NumberFormatter.formatCurrency(_rentValue, symbol: _symbol),
        'Utilities':
            NumberFormatter.formatCurrency(_utilitiesValue, symbol: _symbol),
        'Marketing':
            NumberFormatter.formatCurrency(_marketingValue, symbol: _symbol),
        'Other Expenses':
            NumberFormatter.formatCurrency(_otherExpValue, symbol: _symbol),
        'Other Income':
            NumberFormatter.formatCurrency(_otherIncValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Gross Profit':
              NumberFormatter.formatCurrency(_result!.grossProfit, symbol: _symbol),
          'Gross Margin': NumberFormatter.formatPercent(_result!.grossMargin),
          'Operating Expenses':
              NumberFormatter.formatCurrency(_result!.operatingExpenses, symbol: _symbol),
          'Operating Income':
              NumberFormatter.formatCurrency(_result!.operatingIncome, symbol: _symbol),
          'Net Profit':
              NumberFormatter.formatCurrency(_result!.netProfit, symbol: _symbol),
          'Net Margin': NumberFormatter.formatPercent(_result!.netMargin),
          'Status': _result!.profitStatus,
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Revenue: ${NumberFormatter.formatCurrency(_revenueValue, symbol: _symbol)} | '
          'Net ${_result!.profitStatus}: ${NumberFormatter.formatCurrency(_result!.netProfit, symbol: _symbol)} '
          '(${NumberFormatter.formatPercent(_result!.netMargin)} margin)';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_revenueValue <= 0) return;

    setState(() {
      _result = BusinessCalculators.calculatePnL(
        revenue: _revenueValue,
        cogs: _cogsValue,
        salaries: _salariesValue,
        rent: _rentValue,
        utilities: _utilitiesValue,
        marketing: _marketingValue,
        otherExpenses: _otherExpValue,
        otherIncome: _otherIncValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _revenueController.clear();
      _cogsController.clear();
      _salariesController.clear();
      _rentController.clear();
      _utilitiesController.clear();
      _marketingController.clear();
      _otherExpController.clear();
      _otherIncController.clear();
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
                  buildSectionTitle('Revenue & COGS'),
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
                        return 'Enter valid COGS';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Operating Expenses'),
                  AppTextField(
                    label: 'Salaries & Wages',
                    hint: '1,00,000',
                    controller: _salariesController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Rent & Lease',
                    hint: '30,000',
                    controller: _rentController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Utilities',
                    hint: '15,000',
                    controller: _utilitiesController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Marketing & Advertising',
                    hint: '20,000',
                    controller: _marketingController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Other Expenses',
                    hint: '10,000',
                    controller: _otherExpController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Other Income'),
                  AppTextField(
                    label: 'Other Income',
                    hint: '5,000',
                    controller: _otherIncController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                ],
              ),
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

    return Column(
      children: [
        AppCard(
          borderColor: AppColors.business.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('P&L Statement'),
              const SizedBox(height: 8),
              // Revenue Section
              _sectionHeader('Revenue', AppColors.business),
              _lineItem('Revenue', r.revenue, symbol, AppColors.textPrimary),
              const Divider(height: 24, color: AppColors.border),
              // COGS Section
              _sectionHeader('Cost of Goods Sold', AppColors.error),
              _lineItem('COGS', r.costOfGoodsSold, symbol, AppColors.error),
              const SizedBox(height: 4),
              _lineItem('Gross Profit', r.grossProfit, symbol, AppColors.business,
                  isBold: true),
              _lineItem(
                  'Gross Margin', r.grossMargin, symbol, AppColors.business,
                  isPercent: true),
              const Divider(height: 24, color: AppColors.border),
              // Operating Expenses Section
              _sectionHeader('Operating Expenses', AppColors.error),
              _lineItem(
                  'Salaries', _salariesValue, symbol, AppColors.textSecondary),
              _lineItem('Rent', _rentValue, symbol, AppColors.textSecondary),
              _lineItem(
                  'Utilities', _utilitiesValue, symbol, AppColors.textSecondary),
              _lineItem(
                  'Marketing', _marketingValue, symbol, AppColors.textSecondary),
              _lineItem(
                  'Other Expenses', _otherExpValue, symbol, AppColors.textSecondary),
              const SizedBox(height: 4),
              _lineItem('Total Operating Expenses', r.operatingExpenses, symbol,
                  AppColors.warning,
                  isBold: true),
              const SizedBox(height: 4),
              _lineItem('Operating Income (EBIT)', r.operatingIncome, symbol,
                  r.operatingIncome >= 0 ? AppColors.success : AppColors.error,
                  isBold: true),
              const Divider(height: 24, color: AppColors.border),
              // Bottom Line
              _sectionHeader('Bottom Line', profitColor),
              _lineItem(
                  'Other Income', r.otherIncome, symbol, AppColors.success),
              const SizedBox(height: 4),
              _lineItem(
                  r.profitStatus == 'Profit' ? 'Net Profit' : 'Net Loss',
                  r.netProfit.abs(),
                  symbol,
                  profitColor,
                  isBold: true,
                  isLarge: true),
              _lineItem('Net Margin', r.netMargin, symbol, profitColor,
                  isPercent: true, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultSummaryCard(
          title: 'P&L Summary',
          items: [
            ResultItem(
              label: 'Revenue',
              value: NumberFormatter.formatCurrency(r.revenue, symbol: symbol),
            ),
            ResultItem(
              label: '(-) COGS',
              value:
                  '- ${NumberFormatter.formatCurrency(r.costOfGoodsSold, symbol: symbol)}',
              color: AppColors.error,
            ),
            ResultItem(
              label: 'Gross Profit',
              value:
                  NumberFormatter.formatCurrency(r.grossProfit, symbol: symbol),
              color: AppColors.business,
            ),
            ResultItem(
              label: 'Gross Margin',
              value: NumberFormatter.formatPercent(r.grossMargin),
              color: AppColors.business,
            ),
            ResultItem(
              label: '(-) Operating Expenses',
              value:
                  '- ${NumberFormatter.formatCurrency(r.operatingExpenses, symbol: symbol)}',
              color: AppColors.error,
            ),
            ResultItem(
              label: 'Operating Income',
              value: NumberFormatter.formatCurrency(
                  r.operatingIncome, symbol: symbol),
              color: r.operatingIncome >= 0
                  ? AppColors.success
                  : AppColors.error,
            ),
            ResultItem(
              label: '(+) Other Income',
              value:
                  NumberFormatter.formatCurrency(r.otherIncome, symbol: symbol),
              color: AppColors.success,
            ),
            ResultItem(
              label: r.profitStatus == 'Profit' ? 'Net Profit' : 'Net Loss',
              value: NumberFormatter.formatCurrency(
                  r.netProfit.abs(), symbol: symbol),
              isHighlighted: true,
              color: profitColor,
            ),
            ResultItem(
              label: 'Net Margin',
              value: NumberFormatter.formatPercent(r.netMargin.abs()),
              isHighlighted: true,
              color: profitColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _lineItem(String label, double value, String symbol, Color color,
      {bool isBold = false, bool isLarge = false, bool isPercent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 14 : 13,
                fontWeight:
                    isBold ? FontWeight.w600 : FontWeight.w400,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isPercent
                ? NumberFormatter.formatPercent(value)
                : NumberFormatter.formatCurrency(value, symbol: symbol),
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
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
import '../../domain/banking_calculators.dart';

class NetWorthScreen extends CalculatorBaseScreen {
  const NetWorthScreen({super.key})
      : super(
          calculatorId: 'net_worth',
          calculatorName: 'Net Worth Calculator',
          category: 'Banking',
        );

  @override
  ConsumerState<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends CalculatorBaseState<NetWorthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _investmentsController = TextEditingController();
  final _propertyController = TextEditingController();
  final _otherAssetsController = TextEditingController();
  final _homeLoanController = TextEditingController();
  final _carLoanController = TextEditingController();
  final _creditCardController = TextEditingController();
  final _otherLiabilitiesController = TextEditingController();

  NetWorthResult? _result;
  int _touchedIndex = -1;

  @override
  void dispose() {
    _cashController.dispose();
    _investmentsController.dispose();
    _propertyController.dispose();
    _otherAssetsController.dispose();
    _homeLoanController.dispose();
    _carLoanController.dispose();
    _creditCardController.dispose();
    _otherLiabilitiesController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);

  @override
  Map<String, dynamic> get currentInputs => {
        'Cash': NumberFormatter.formatCurrency(_cashValue, symbol: _symbol),
        'Investments': NumberFormatter.formatCurrency(_investmentsValue, symbol: _symbol),
        'Property': NumberFormatter.formatCurrency(_propertyValue, symbol: _symbol),
        'Other Assets': NumberFormatter.formatCurrency(_otherAssetsValue, symbol: _symbol),
        'Home Loan': NumberFormatter.formatCurrency(_homeLoanValue, symbol: _symbol),
        'Car Loan': NumberFormatter.formatCurrency(_carLoanValue, symbol: _symbol),
        'Credit Card': NumberFormatter.formatCurrency(_creditCardValue, symbol: _symbol),
        'Other Liabilities': NumberFormatter.formatCurrency(_otherLiabilitiesValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Total Assets': NumberFormatter.formatCurrency(_result!.totalAssets, symbol: _symbol),
          'Total Liabilities': NumberFormatter.formatCurrency(_result!.totalLiabilities, symbol: _symbol),
          'Net Worth': NumberFormatter.formatCurrency(_result!.netWorth, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Net Worth: ${NumberFormatter.formatCurrency(_result!.netWorth, symbol: _symbol)} | '
          'Assets: ${NumberFormatter.formatCurrency(_result!.totalAssets, symbol: _symbol)} | '
          'Liabilities: ${NumberFormatter.formatCurrency(_result!.totalLiabilities, symbol: _symbol)}';

  double get _cashValue => NumberFormatter.tryParse(_cashController.text) ?? 0;
  double get _investmentsValue => NumberFormatter.tryParse(_investmentsController.text) ?? 0;
  double get _propertyValue => NumberFormatter.tryParse(_propertyController.text) ?? 0;
  double get _otherAssetsValue => NumberFormatter.tryParse(_otherAssetsController.text) ?? 0;
  double get _homeLoanValue => NumberFormatter.tryParse(_homeLoanController.text) ?? 0;
  double get _carLoanValue => NumberFormatter.tryParse(_carLoanController.text) ?? 0;
  double get _creditCardValue => NumberFormatter.tryParse(_creditCardController.text) ?? 0;
  double get _otherLiabilitiesValue => NumberFormatter.tryParse(_otherLiabilitiesController.text) ?? 0;

  String? _validateAmount(String? v) {
    if (v == null || v.isEmpty) return null;
    if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Enter a valid amount';
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = BankingCalculators.calculateNetWorth(
        assets: [
          AssetItem(name: 'Cash', amount: _cashValue),
          AssetItem(name: 'Investments', amount: _investmentsValue),
          AssetItem(name: 'Property', amount: _propertyValue),
          AssetItem(name: 'Other Assets', amount: _otherAssetsValue),
        ],
        liabilities: [
          LiabilityItem(name: 'Home Loan', amount: _homeLoanValue),
          LiabilityItem(name: 'Car Loan', amount: _carLoanValue),
          LiabilityItem(name: 'Credit Card', amount: _creditCardValue),
          LiabilityItem(name: 'Other Liabilities', amount: _otherLiabilitiesValue),
        ],
      );
    });
  }

  void _reset() {
    setState(() {
      for (final c in [
        _cashController,
        _investmentsController,
        _propertyController,
        _otherAssetsController,
        _homeLoanController,
        _carLoanController,
        _creditCardController,
        _otherLiabilitiesController,
      ]) {
        c.clear();
      }
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
                  buildSectionTitle('Assets'),
                  AppTextField(
                    label: 'Cash & Bank',
                    hint: '0',
                    controller: _cashController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Investments',
                    hint: '0',
                    controller: _investmentsController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Property',
                    hint: '0',
                    controller: _propertyController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Other Assets',
                    hint: '0',
                    controller: _otherAssetsController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Liabilities'),
                  AppTextField(
                    label: 'Home Loan',
                    hint: '0',
                    controller: _homeLoanController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Car Loan',
                    hint: '0',
                    controller: _carLoanController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Credit Card Debt',
                    hint: '0',
                    controller: _creditCardController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Other Liabilities',
                    hint: '0',
                    controller: _otherLiabilitiesController,
                    prefix: symbol,
                    validator: _validateAmount,
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Calculate',
                    icon: Icons.calculate_rounded,
                    onPressed: _calculate,
                    width: double.infinity,
                    color: AppColors.banking,
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(
                  label: 'Reset',
                  isOutlined: true,
                  onPressed: _reset,
                  color: AppColors.banking,
                ),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
              const SizedBox(height: 16),
              _buildPieChart(),
              const SizedBox(height: 16),
              _buildHealthStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final isPositive = r.netWorth >= 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text(
                  'Net Worth',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.netWorth.abs(),
                  formatter: (v) => '${isPositive ? '' : '-'}${NumberFormatter.formatCurrency(v, symbol: symbol)}',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? AppColors.success : AppColors.error,
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
                  label: 'Total Assets',
                  value: NumberFormatter.formatCurrency(r.totalAssets, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Liabilities',
                  value: NumberFormatter.formatCurrency(r.totalLiabilities, symbol: symbol),
                  valueColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Breakdown',
            items: [
              ResultItem(
                label: 'Total Assets',
                value: NumberFormatter.formatCurrency(r.totalAssets, symbol: symbol),
              ),
              ResultItem(
                label: 'Total Liabilities',
                value: NumberFormatter.formatCurrency(r.totalLiabilities, symbol: symbol),
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Net Worth',
                value: '${isPositive ? '' : '-'}${NumberFormatter.formatCurrency(r.netWorth.abs(), symbol: symbol)}',
                isHighlighted: true,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final r = _result!;
    final totalAssets = r.totalAssets > 0 ? r.totalAssets : 1;
    final totalLiabilities = r.totalLiabilities > 0 ? r.totalLiabilities : 1;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Assets vs Liabilities'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 52,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: [
                        PieChartSectionData(
                          value: r.assets.fold(0.0, (s, a) => s + a.amount),
                          color: AppColors.success,
                          title: _touchedIndex == 0 ? 'Assets' : '',
                          radius: _touchedIndex == 0 ? 60 : 52,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: r.liabilities.fold(0.0, (s, l) => s + l.amount),
                          color: AppColors.error.withValues(alpha: 0.75),
                          title: _touchedIndex == 1 ? 'Liabilities' : '',
                          radius: _touchedIndex == 1 ? 60 : 52,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieLegend(
                      color: AppColors.success,
                      label: 'Assets',
                      value: '${(r.totalAssets / (r.totalAssets + r.totalLiabilities) * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 14),
                    _PieLegend(
                      color: AppColors.error.withValues(alpha: 0.75),
                      label: 'Liabilities',
                      value: '${(r.totalLiabilities / (r.totalAssets + r.totalLiabilities) * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatus() {
    final r = _result!;
    final ratio = r.totalLiabilities > 0 ? r.totalAssets / r.totalLiabilities : double.infinity;

    String status;
    Color color;
    IconData icon;
    if (ratio >= 3) {
      status = 'Excellent';
      color = AppColors.success;
      icon = Icons.emoji_emotions_rounded;
    } else if (ratio >= 2) {
      status = 'Good';
      color = AppColors.success;
      icon = Icons.sentiment_satisfied_rounded;
    } else if (ratio >= 1) {
      status = 'Fair';
      color = AppColors.warning;
      icon = Icons.sentiment_neutral_rounded;
    } else {
      status = 'Needs Attention';
      color = AppColors.error;
      icon = Icons.sentiment_dissatisfied_rounded;
    }

    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Health',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                ratio.isFinite
                    ? 'Asset/Liability Ratio: ${ratio.toStringAsFixed(2)}x'
                    : 'No liabilities',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _PieLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}

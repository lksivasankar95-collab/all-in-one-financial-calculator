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
import '../../domain/real_estate_calculators.dart';

class RentVsBuyScreen extends CalculatorBaseScreen {
  const RentVsBuyScreen({super.key})
      : super(
          calculatorId: 'rent_vs_buy',
          calculatorName: 'Rent vs Buy Calculator',
          category: 'Real Estate',
        );

  @override
  ConsumerState<RentVsBuyScreen> createState() => _RentVsBuyScreenState();
}

class _RentVsBuyScreenState extends CalculatorBaseState<RentVsBuyScreen> {
  final _priceController = TextEditingController();
  final _rentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _downPaymentPct = 20;
  double _loanRate = 9.0;
  int _tenureYears = 20;
  double _propertyTaxRate = 1.0;
  double _maintenanceRate = 1.0;
  double _rentIncrease = 5.0;
  double _appreciation = 5.0;
  RentVsBuyResult? _result;

  @override
  void dispose() {
    _priceController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _priceValue => NumberFormatter.tryParse(_priceController.text) ?? 0;
  double get _rentValue => NumberFormatter.tryParse(_rentController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Property Price': NumberFormatter.formatCurrency(_priceValue, symbol: _symbol),
        'Monthly Rent': NumberFormatter.formatCurrency(_rentValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Net Buy Cost': NumberFormatter.formatCurrency(_result!.netBuyCost, symbol: _symbol),
        'Net Rent Cost': NumberFormatter.formatCurrency(_result!.netRentCost, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Buy: ${NumberFormatter.formatCurrency(_result!.netBuyCost, symbol: _symbol)} | '
          'Rent: ${NumberFormatter.formatCurrency(_result!.netRentCost, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_priceValue <= 0 || _rentValue <= 0) return;
    final downPayment = _priceValue * _downPaymentPct / 100;

    setState(() {
      _result = RealEstateCalculators.calculateRentVsBuy(
        propertyPrice: _priceValue,
        rent: _rentValue,
        downPayment: downPayment,
        loanRate: _loanRate,
        tenureYears: _tenureYears,
        propertyTaxRate: _propertyTaxRate,
        maintenanceRate: _maintenanceRate,
        rentIncrease: _rentIncrease,
        appreciation: _appreciation,
      );
    });
  }

  void _reset() {
    setState(() {
      _priceController.clear();
      _rentController.clear();
      _downPaymentPct = 20;
      _loanRate = 9.0;
      _tenureYears = 20;
      _propertyTaxRate = 1.0;
      _maintenanceRate = 1.0;
      _rentIncrease = 5.0;
      _appreciation = 5.0;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ref.watch(currencySymbolProvider);
    final isBuyBetter = _result != null && _result!.netBuyCost < _result!.netRentCost;

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
                  buildSectionTitle('Property & Rent'),
                  AppTextField(
                    label: 'Property Price', hint: '5000000',
                    controller: _priceController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Rent', hint: '20000',
                    controller: _rentController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
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
                  buildSectionTitle('Loan & Costs'),
                  AppSliderField(
                    label: 'Down Payment', value: _downPaymentPct,
                    min: 5, max: 50, divisions: 45,
                    displayValue: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() { _downPaymentPct = v; _result = null; }),
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Home Loan Rate', value: _loanRate,
                    min: 1, max: 15, divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _loanRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Loan Tenure', value: _tenureYears.toDouble(),
                    min: 5, max: 30, divisions: 25,
                    displayValue: (v) => '${v.toInt()} years',
                    onChanged: (v) => setState(() { _tenureYears = v.toInt(); _result = null; }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Assumptions'),
                  AppSliderField(
                    label: 'Property Tax Rate', value: _propertyTaxRate,
                    min: 0, max: 5, divisions: 50,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _propertyTaxRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Maintenance Rate', value: _maintenanceRate,
                    min: 0, max: 5, divisions: 50,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _maintenanceRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Annual Rent Increase', value: _rentIncrease,
                    min: 0, max: 15, divisions: 150,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _rentIncrease = v; _result = null; }),
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Property Appreciation', value: _appreciation,
                    min: 0, max: 20, divisions: 200,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _appreciation = v; _result = null; }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(label: 'Compare', icon: Icons.compare_arrows_rounded,
                      onPressed: _calculate, width: double.infinity, color: AppColors.realEstate),
                ),
                const SizedBox(width: 10),
                AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.realEstate),
              ],
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol, isBuyBetter),
              const SizedBox(height: 16),
              _buildComparisonChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol, bool isBuyBetter) {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Comparison'),
          Center(
            child: Column(
              children: [
                const Text('Recommendation', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: isBuyBetter ? r.netBuyCost : r.netRentCost,
                  formatter: (v) => isBuyBetter ? 'Buy' : 'Rent',
                  style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w800,
                    color: isBuyBetter ? AppColors.success : AppColors.info,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Net Cost of Buying',
                    value: NumberFormatter.formatCurrency(r.netBuyCost, symbol: symbol),
                    valueColor: isBuyBetter ? AppColors.success : AppColors.error),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Net Cost of Renting',
                    value: NumberFormatter.formatCurrency(r.netRentCost, symbol: symbol),
                    valueColor: !isBuyBetter ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Monthly EMI (if buying)',
            value: NumberFormatter.formatCurrency(r.monthlyEmi, symbol: symbol),
            subtitle: 'Property value after $_tenureYears years: ${NumberFormatter.formatCurrency(r.buyAssetValue, symbol: symbol)}',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Cost Comparison over $_tenureYears Years',
            items: [
              ResultItem(label: 'Buy - Total Cost', value: NumberFormatter.formatCurrency(r.totalBuyCost, symbol: symbol)),
              ResultItem(label: 'Buy - Asset Value', value: NumberFormatter.formatCurrency(r.buyAssetValue, symbol: symbol), color: AppColors.realEstate),
              ResultItem(label: 'Buy - Net Cost', value: NumberFormatter.formatCurrency(r.netBuyCost, symbol: symbol), isHighlighted: true),
              ResultItem(label: 'Rent - Total Cost', value: NumberFormatter.formatCurrency(r.netRentCost, symbol: symbol), isHighlighted: true),
              ResultItem(label: isBuyBetter ? '✓ Buy is cheaper' : '✓ Rent is cheaper',
                  value: isBuyBetter ? 'Save ${NumberFormatter.formatCurrency(r.netRentCost - r.netBuyCost, symbol: symbol)}' : 'Save ${NumberFormatter.formatCurrency(r.netBuyCost - r.netRentCost, symbol: symbol)}',
                  color: isBuyBetter ? AppColors.success : AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Cost Comparison'),
          const SizedBox(height: 8),
          SizedBox(height: 200, child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: [r.totalBuyCost, r.netRentCost].reduce((a, b) => a > b ? a : b) * 1.2,
            barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8, tooltipPadding: const EdgeInsets.all(8),
              getTooltipColor: (_) => AppColors.card,
              getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                '${ri == 0 ? "Buy" : "Rent"}: ${NumberFormatter.formatCompact(rod.toY)}',
                const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
            )),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, getTitlesWidget: (v, m) {
                  final labels = ['Buy Total', 'Buy Net', 'Rent'];
                  final idx = v.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(labels[idx], style: const TextStyle(fontSize: 9, color: AppColors.textHint)));
                },
              )),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: r.totalBuyCost, color: AppColors.realEstate, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: r.netBuyCost, color: AppColors.realEstate.withValues(alpha: 0.6), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: r.netRentCost, color: AppColors.info, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
            ],
          ))),
          const SizedBox(height: 8),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LegendDot(color: AppColors.realEstate, label: 'Buy Total'),
            SizedBox(width: 12),
            _LegendDot(color: AppColors.realEstate, label: 'Buy Net'),
            SizedBox(width: 12),
            _LegendDot(color: AppColors.info, label: 'Rent'),
          ]),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

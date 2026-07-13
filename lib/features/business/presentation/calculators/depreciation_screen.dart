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

class DepreciationScreen extends CalculatorBaseScreen {
  const DepreciationScreen({super.key})
      : super(
          calculatorId: 'depreciation',
          calculatorName: 'Depreciation',
          category: 'Business',
        );

  @override
  ConsumerState<DepreciationScreen> createState() =>
      _DepreciationScreenState();
}

class _DepreciationScreenState extends CalculatorBaseState<DepreciationScreen> {
  final _assetCostController = TextEditingController();
  final _salvageValueController = TextEditingController();
  double _usefulLife = 10.0;
  DepreciationResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _assetCostController.dispose();
    _salvageValueController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Asset Cost':
            NumberFormatter.formatCurrency(_assetCost, symbol: _symbol),
        'Salvage Value':
            NumberFormatter.formatCurrency(_salvageValue, symbol: _symbol),
        'Useful Life': '${_usefulLife.toInt()} years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Straight-Line Annual Depreciation':
              NumberFormatter.formatCurrency(
                  _result!.slAnnualDepreciation, symbol: _symbol),
          'Reducing Balance Rate':
              NumberFormatter.formatPercent(_result!.rbRate),
          'Total SL Depreciation':
              NumberFormatter.formatCurrency(
                  _result!.totalSlDepreciation, symbol: _symbol),
          'Total RB Depreciation':
              NumberFormatter.formatCurrency(
                  _result!.totalRbDepreciation, symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'SL: ${NumberFormatter.formatCurrency(_result!.slAnnualDepreciation, symbol: _symbol)}/yr | '
          'RB rate: ${NumberFormatter.formatPercent(_result!.rbRate)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _assetCost =>
      NumberFormatter.tryParse(_assetCostController.text) ?? 0;
  double get _salvageValue =>
      NumberFormatter.tryParse(_salvageValueController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final cost = _assetCost;
    final salvage = _salvageValue;
    final life = _usefulLife.toInt();
    if (cost <= 0 || life <= 0) return;

    final double slAnnual = (cost - salvage) / life;
    final double rbRate = (2.0 / life) * 100;

    final List<DepreciationYearData> slSchedule = [];
    double slRemaining = cost;
    double totalSl = 0;
    for (int y = 1; y <= life; y++) {
      final double dep = (y < life) ? slAnnual : slRemaining - salvage;
      slRemaining -= dep;
      if (slRemaining < salvage) slRemaining = salvage;
      totalSl += dep;
      slSchedule.add(DepreciationYearData(
        year: y,
        depreciation: dep,
        accumulated: totalSl,
        bookValue: slRemaining,
      ));
    }

    final List<DepreciationYearData> rbSchedule = [];
    double rbBookValue = cost;
    double totalRb = 0;
    for (int y = 1; y <= life; y++) {
      final double dep = rbBookValue * (rbRate / 100);
      final double adjustedDep =
          (rbBookValue - dep >= salvage) ? dep : rbBookValue - salvage;
      rbBookValue -= adjustedDep;
      if (rbBookValue < salvage) rbBookValue = salvage;
      totalRb += adjustedDep;
      rbSchedule.add(DepreciationYearData(
        year: y,
        depreciation: adjustedDep,
        accumulated: totalRb,
        bookValue: rbBookValue,
      ));
    }

    setState(() {
      _result = DepreciationResult(
        slAnnualDepreciation: slAnnual,
        rbRate: rbRate,
        totalSlDepreciation: totalSl,
        totalRbDepreciation: totalRb,
        slSchedule: slSchedule,
        rbSchedule: rbSchedule,
      );
    });
  }

  void _reset() {
    setState(() {
      _assetCostController.clear();
      _salvageValueController.clear();
      _usefulLife = 10.0;
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
                  buildSectionTitle('Asset Details'),
                  AppTextField(
                    label: 'Asset Cost',
                    hint: '10,00,000',
                    controller: _assetCostController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid cost';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Salvage Value',
                    hint: '1,00,000',
                    controller: _salvageValueController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = NumberFormatter.tryParse(v) ?? 0;
                      if (val < 0) return 'Enter a valid salvage value';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Useful Life',
                    value: _usefulLife,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _usefulLife = v;
                      _result = null;
                    }),
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
              const SizedBox(height: 16),
              _buildComparisonTable(symbol),
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
          buildSectionTitle('Depreciation Methods Compared'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.business.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.business.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Straight-Line',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormatter.formatCurrency(
                          r.slAnnualDepreciation, symbol: symbol),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.business,
                      ),
                    ),
                    const Text(
                      'per year',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.border,
                ),
                Column(
                  children: [
                    const Text(
                      'Reducing Balance',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormatter.formatPercent(r.rbRate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.business,
                      ),
                    ),
                    const Text(
                      'per year',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total SL Depreciation',
                  value: NumberFormatter.formatCurrency(
                      r.totalSlDepreciation, symbol: symbol),
                  valueColor: AppColors.business,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total RB Depreciation',
                  value: NumberFormatter.formatCurrency(
                      r.totalRbDepreciation, symbol: symbol),
                  valueColor: AppColors.business,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Depreciation Summary',
            items: [
              ResultItem(
                label: 'Asset Cost',
                value:
                    NumberFormatter.formatCurrency(_assetCost, symbol: symbol),
              ),
              ResultItem(
                label: 'Salvage Value',
                value: NumberFormatter.formatCurrency(
                    _salvageValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Useful Life',
                value: '${_usefulLife.toInt()} years',
              ),
              ResultItem(
                label: 'SL Annual Depreciation',
                value: NumberFormatter.formatCurrency(
                    r.slAnnualDepreciation, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'RB Rate',
                value: NumberFormatter.formatPercent(r.rbRate),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Total SL Depreciation',
                value: NumberFormatter.formatCurrency(
                    r.totalSlDepreciation, symbol: symbol),
              ),
              ResultItem(
                label: 'Total RB Depreciation',
                value: NumberFormatter.formatCurrency(
                    r.totalRbDepreciation, symbol: symbol),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(String symbol) {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Year-by-Year Comparison'),
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                  width: 36,
                  child: Text('Yr',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint))),
              Expanded(
                child: Text('Straight-Line',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint)),
              ),
              Expanded(
                child: Text('Reducing Balance',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(r.slSchedule.length, (i) {
            final sl = r.slSchedule[i];
            final rb = r.rbSchedule[i];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${sl.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      NumberFormatter.formatCurrency(
                          sl.depreciation, symbol: symbol),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      NumberFormatter.formatCurrency(
                          rb.depreciation, symbol: symbol),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DepreciationResult {
  final double slAnnualDepreciation;
  final double rbRate;
  final double totalSlDepreciation;
  final double totalRbDepreciation;
  final List<DepreciationYearData> slSchedule;
  final List<DepreciationYearData> rbSchedule;

  const DepreciationResult({
    required this.slAnnualDepreciation,
    required this.rbRate,
    required this.totalSlDepreciation,
    required this.totalRbDepreciation,
    required this.slSchedule,
    required this.rbSchedule,
  });
}

class DepreciationYearData {
  final int year;
  final double depreciation;
  final double accumulated;
  final double bookValue;

  const DepreciationYearData({
    required this.year,
    required this.depreciation,
    required this.accumulated,
    required this.bookValue,
  });
}

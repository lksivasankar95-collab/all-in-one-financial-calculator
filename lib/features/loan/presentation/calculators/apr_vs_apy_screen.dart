import 'dart:math';

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

class AprVsApyScreen extends CalculatorBaseScreen {
  const AprVsApyScreen({super.key})
      : super(
          calculatorId: 'apr_vs_apy',
          calculatorName: 'APR vs APY',
          category: 'Loan',
        );

  @override
  ConsumerState<AprVsApyScreen> createState() => _AprVsApyScreenState();
}

class _CompoundingFrequency {
  final String label;
  final int periods;

  const _CompoundingFrequency(this.label, this.periods);
}

class _AprVsApyResult {
  final double nominalRate;
  final int selectedPeriods;
  final double apy;
  final double difference;
  final List<_FrequencyRow> frequencies;

  const _AprVsApyResult({
    required this.nominalRate,
    required this.selectedPeriods,
    required this.apy,
    required this.difference,
    required this.frequencies,
  });
}

class _FrequencyRow {
  final String label;
  final int periods;
  final double effectiveRate;
  final double difference;

  const _FrequencyRow({
    required this.label,
    required this.periods,
    required this.effectiveRate,
    required this.difference,
  });
}

class _AprVsApyScreenState extends CalculatorBaseState<AprVsApyScreen> {
  final _principalController = TextEditingController();
  final _yearsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _nominalRate = 8.5;
  int _selectedFrequencyIndex = 2;

  static const List<_CompoundingFrequency> _frequencies = [
    _CompoundingFrequency('Daily (365)', 365),
    _CompoundingFrequency('Weekly (52)', 52),
    _CompoundingFrequency('Monthly (12)', 12),
    _CompoundingFrequency('Quarterly (4)', 4),
    _CompoundingFrequency('Semi-Annual (2)', 2),
    _CompoundingFrequency('Annually (1)', 1),
  ];

  _AprVsApyResult? _result;

  @override
  void dispose() {
    _principalController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _principalValue =>
      NumberFormatter.tryParse(_principalController.text) ?? 0;

  int get _yearsValue =>
      (NumberFormatter.tryParse(_yearsController.text) ?? 0).round();

  _CompoundingFrequency get _selectedFrequency =>
      _frequencies[_selectedFrequencyIndex];

  @override
  Map<String, dynamic> get currentInputs {
    return {
      'Nominal Rate': NumberFormatter.formatPercent(_nominalRate),
      'Compounding': _selectedFrequency.label,
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    return {
      'APR': NumberFormatter.formatPercent(_result!.nominalRate),
      'APY': NumberFormatter.formatPercent(_result!.apy, decimals: 3),
      'Difference': NumberFormatter.formatPercent(_result!.difference, decimals: 3),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    return 'APR: ${NumberFormatter.formatPercent(_result!.nominalRate)} | '
        'APY: ${NumberFormatter.formatPercent(_result!.apy, decimals: 3)} | '
        'Diff: ${NumberFormatter.formatPercent(_result!.difference, decimals: 3)}';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final principal = _principalValue;
    final years = _yearsValue;

    final double r = _nominalRate / 100;
    final int n = _selectedFrequency.periods;

    final double apy = (pow(1 + r / n, n) - 1) * 100;
    final double difference = apy - _nominalRate;

    final frequencies = _frequencies.map((f) {
      final eff = (pow(1 + r / f.periods, f.periods) - 1) * 100;
      return _FrequencyRow(
        label: f.label,
        periods: f.periods,
        effectiveRate: eff,
        difference: eff - _nominalRate,
      );
    }).toList();

    setState(() {
      _result = _AprVsApyResult(
        nominalRate: _nominalRate,
        selectedPeriods: n,
        apy: apy,
        difference: difference,
        frequencies: frequencies,
      );
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _yearsController.clear();
      _nominalRate = 8.5;
      _selectedFrequencyIndex = 2;
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
                  buildSectionTitle('Input'),
                  AppSliderField(
                    label: 'Nominal Interest Rate (APR)',
                    value: _nominalRate,
                    min: 0.1,
                    max: 40,
                    divisions: 399,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _nominalRate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Compounding Frequency',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFrequencySelector(),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Principal Amount (optional)',
                    hint: '100000',
                    controller: _principalController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Time Period in Years (optional)',
                    hint: '5',
                    controller: _yearsController,
                    keyboardType: TextInputType.number,
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
                          icon: Icons.transform_rounded,
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

  Widget _buildFrequencySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_frequencies.length, (i) {
            final selected = i == _selectedFrequencyIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFrequencyIndex = i;
                  if (_result != null) _result = null;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.loan.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: selected
                      ? Border.all(
                          color: AppColors.loan.withValues(alpha: 0.5))
                      : null,
                ),
                child: Text(
                  _frequencies[i].label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.loan
                        : AppColors.textHint,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('APR vs APY'),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    AnimatedResultValue(
                      value: r.apy,
                      formatter: (v) =>
                          '${v.toStringAsFixed(3)}%',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.loan,
                      ),
                    ),
                    const Text(
                      'Effective Annual Rate (APY)',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Nominal Rate (APR)',
                      value: NumberFormatter.formatPercent(r.nominalRate),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'APY',
                      value:
                          '${r.apy.toStringAsFixed(3)}%',
                      isHighlighted: true,
                      valueColor: AppColors.loan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ResultCard(
                label: 'Difference (APY - APR)',
                value: '${r.difference.toStringAsFixed(3)}%',
                isHighlighted: true,
                valueColor: AppColors.success,
                subtitle: 'With ${_selectedFrequency.label.toLowerCase()} compounding',
              ),
            ],
          ),
        ),
        if (_principalValue > 0 && _yearsValue > 0) ...[
          const SizedBox(height: 16),
          _buildMonetaryImpact(symbol),
        ],
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Compounding Frequency Comparison'),
              const SizedBox(height: 8),
              _buildFrequencyTable(r),
              const SizedBox(height: 12),
              ResultSummaryCard(
                title: 'Summary',
                items: [
                  ResultItem(
                    label: 'Nominal Rate (APR)',
                    value: NumberFormatter.formatPercent(r.nominalRate),
                  ),
                  ResultItem(
                    label: 'Compounding',
                    value: _selectedFrequency.label,
                  ),
                  ResultItem(
                    label: 'APY (Effective Rate)',
                    value: '${r.apy.toStringAsFixed(3)}%',
                    isHighlighted: true,
                    color: AppColors.loan,
                  ),
                  ResultItem(
                    label: 'Difference',
                    value: '${r.difference.toStringAsFixed(3)}%',
                    isHighlighted: true,
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonetaryImpact(String symbol) {
    final r = _result!;
    final double aprAmount = _principalValue *
        pow(1 + r.nominalRate / 100, _yearsValue).toDouble();
    final double apyAmount = _principalValue *
        pow(1 + r.apy / 100, _yearsValue).toDouble();
    final double differenceAmount = apyAmount - aprAmount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Growth Difference Over $_yearsValue Years'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'With APR',
                  value: NumberFormatter.formatCurrency(
                      aprAmount, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'With APY',
                  value: NumberFormatter.formatCurrency(
                      apyAmount, symbol: symbol),
                  isHighlighted: true,
                  valueColor: AppColors.loan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Extra Earnings with APY',
            value: NumberFormatter.formatCurrency(
                differenceAmount, symbol: symbol),
            isHighlighted: true,
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyTable(_AprVsApyResult r) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 36,
        columnSpacing: 14,
        headingTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.textPrimary,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        columns: const [
          DataColumn(label: Text('Frequency')),
          DataColumn(label: Text('Periods')),
          DataColumn(label: Text('Effective Rate')),
          DataColumn(label: Text('Difference')),
        ],
        rows: r.frequencies.map((f) {
          final isSelected = f.periods == r.selectedPeriods;
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color?>((states) {
              if (isSelected) {
                return AppColors.loan.withValues(alpha: 0.1);
              }
              return null;
            }),
            cells: [
              DataCell(Text(f.label,
                  style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400))),
              DataCell(Text(f.periods.toString())),
              DataCell(Text('${f.effectiveRate.toStringAsFixed(3)}%')),
              DataCell(Text('${f.difference.toStringAsFixed(3)}%')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

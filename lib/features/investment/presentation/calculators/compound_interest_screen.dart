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

class CompoundInterestScreen extends CalculatorBaseScreen {
  const CompoundInterestScreen({super.key})
      : super(
          calculatorId: 'compound_interest',
          calculatorName: 'Compound Interest',
          category: 'Investment',
        );

  @override
  ConsumerState<CompoundInterestScreen> createState() =>
      _CompoundInterestScreenState();
}

class _CompoundInterestScreenState
    extends CalculatorBaseState<CompoundInterestScreen> {
  final _principalController = TextEditingController();
  double _rate = 10.0;
  int _years = 5;
  int _compoundsPerYear = 1; // 1=Annual, 2=Semi, 4=Quarterly, 12=Monthly, 365=Daily
  CompoundResult? _result;
  final _formKey = GlobalKey<FormState>();

  static const _compoundingOptions = [
    _CompoundOption(label: 'Annually', value: 1),
    _CompoundOption(label: 'Semi-Annually', value: 2),
    _CompoundOption(label: 'Quarterly', value: 4),
    _CompoundOption(label: 'Monthly', value: 12),
    _CompoundOption(label: 'Daily', value: 365),
  ];

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Principal':
            NumberFormatter.formatCurrency(_principalValue, symbol: _symbol),
        'Annual Rate': NumberFormatter.formatPercent(_rate),
        'Time': '$_years years',
        'Compounding':
            _compoundingOptions.firstWhere((o) => o.value == _compoundsPerYear).label,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Maturity Amount':
              NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol),
          'Compound Interest':
              NumberFormatter.formatCurrency(_result!.interest, symbol: _symbol),
          'Effective Annual Rate':
              NumberFormatter.formatPercent(_result!.effectiveRate),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'CI: ${NumberFormatter.formatCurrency(_principalValue, symbol: _symbol)} @ $_rate% '
          'for $_years yrs = ${NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _principalValue =>
      NumberFormatter.tryParse(_principalController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculateCompoundInterest(
        principal: _principalValue,
        rate: _rate,
        years: _years,
        compoundsPerYear: _compoundsPerYear,
      );
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _rate = 10.0;
      _years = 5;
      _compoundsPerYear = 1;
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
                  buildSectionTitle('Investment Details'),
                  AppTextField(
                    label: 'Principal Amount',
                    hint: '1,00,000',
                    controller: _principalController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid principal';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Interest Rate',
                    value: _rate,
                    min: 0.5,
                    max: 36,
                    divisions: 710,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _rate = v;
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Time Period',
                    value: _years.toDouble(),
                    min: 1,
                    max: 40,
                    divisions: 39,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _years = v.toInt();
                        if (_result != null) _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildCompoundingDropdown(),
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

  Widget _buildCompoundingDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compounding Frequency',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<int>(
            value: _compoundsPerYear,
            isExpanded: true,
            dropdownColor: AppColors.card,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded,
                color: AppColors.textHint, size: 20),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            items: _compoundingOptions
                .map((o) => DropdownMenuItem(
                      value: o.value,
                      child: Text(o.label),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _compoundsPerYear = v;
                if (_result != null) _result = null;
              });
            },
          ),
        ),
      ],
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
                  'Maturity Amount',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.maturityAmount,
                  formatter: (v) =>
                      NumberFormatter.formatCurrency(v, symbol: symbol),
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
                  label: 'Principal',
                  value: NumberFormatter.formatCurrency(_principalValue,
                      symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Compound Interest',
                  value: NumberFormatter.formatCurrency(r.interest,
                      symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Effective Annual Rate (EAR)',
            value: NumberFormatter.formatPercent(r.effectiveRate),
            isHighlighted: true,
            subtitle:
                'Actual yearly yield after compounding',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Principal',
                value: NumberFormatter.formatCurrency(_principalValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Rate (Nominal)',
                value: NumberFormatter.formatPercent(_rate),
              ),
              ResultItem(
                label: 'Period',
                value: '$_years years',
              ),
              ResultItem(
                label: 'Compounding',
                value: _compoundingOptions
                    .firstWhere((o) => o.value == _compoundsPerYear)
                    .label,
              ),
              ResultItem(
                label: 'Compound Interest',
                value: NumberFormatter.formatCurrency(r.interest,
                    symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Maturity Amount',
                value: NumberFormatter.formatCurrency(r.maturityAmount,
                    symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Effective Annual Rate',
                value: NumberFormatter.formatPercent(r.effectiveRate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompoundOption {
  final String label;
  final int value;
  const _CompoundOption({required this.label, required this.value});
}

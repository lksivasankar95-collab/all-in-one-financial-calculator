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
import '../../domain/savings_calculators.dart';

class FdScreen extends CalculatorBaseScreen {
  const FdScreen({super.key})
      : super(
          calculatorId: 'fd',
          calculatorName: 'FD Calculator',
          category: 'Savings',
        );

  @override
  ConsumerState<FdScreen> createState() => _FdScreenState();
}

class _FdScreenState extends CalculatorBaseState<FdScreen> {
  final _principalController = TextEditingController();
  double _annualRate = 7.0;
  int _years = 1;
  int _months = 0;
  int _compoundingFrequency = 4; // Quarterly default
  FdResult? _result;
  final _formKey = GlobalKey<FormState>();

  static const _compoundingOptions = [
    _CompoundingOption('Monthly', 12),
    _CompoundingOption('Quarterly', 4),
    _CompoundingOption('Half-Yearly', 2),
    _CompoundingOption('Yearly', 1),
    _CompoundingOption('Simple Interest', 0),
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
        'Principal': NumberFormatter.formatCurrency(_principalValue, symbol: _symbol),
        'Annual Rate': NumberFormatter.formatPercent(_annualRate),
        'Duration': _durationLabel,
        'Compounding': _selectedCompoundingLabel,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Maturity Amount': NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol),
          'Interest Earned': NumberFormatter.formatCurrency(_result!.interestEarned, symbol: _symbol),
          'Effective Rate': NumberFormatter.formatPercent(_result!.effectiveRate),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'FD of ${NumberFormatter.formatCurrency(_principalValue, symbol: _symbol)} '
          'for $_durationLabel @ ${_annualRate.toStringAsFixed(1)}% = '
          '${NumberFormatter.formatCurrency(_result!.maturityAmount, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _principalValue => NumberFormatter.tryParse(_principalController.text) ?? 0;

  String get _durationLabel {
    if (_years == 0) return '$_months months';
    if (_months == 0) return '$_years ${_years == 1 ? "yr" : "yrs"}';
    return '$_years yr${_years > 1 ? "s" : ""} $_months mo';
  }

  String get _selectedCompoundingLabel =>
      _compoundingOptions.firstWhere((o) => o.value == _compoundingFrequency).label;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_years == 0 && _months == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a duration greater than 0')),
      );
      return;
    }
    final principal = _principalValue;
    if (principal <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateFd(
        principal: principal,
        annualRate: _annualRate,
        years: _years,
        months: _months,
        compoundingFrequency: _compoundingFrequency,
      );
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _annualRate = 7.0;
      _years = 1;
      _months = 0;
      _compoundingFrequency = 4;
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
                  buildSectionTitle('Deposit Details'),
                  AppTextField(
                    label: 'Principal Amount',
                    hint: '1,00,000',
                    controller: _principalController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Interest Rate',
                    value: _annualRate,
                    min: 1,
                    max: 15,
                    divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualRate = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Duration (Years)',
                    value: _years.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    displayValue: (v) =>
                        v.toInt() == 0 ? '0 yrs' : '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) => setState(() {
                      _years = v.toInt();
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Duration (Months)',
                    value: _months.toDouble(),
                    min: 0,
                    max: 11,
                    divisions: 11,
                    displayValue: (v) =>
                        v.toInt() == 0 ? '0 mo' : '${v.toInt()} mo',
                    onChanged: (v) => setState(() {
                      _months = v.toInt();
                      _result = null;
                    }),
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
                          color: AppColors.savings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.savings,
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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _compoundingFrequency,
              isExpanded: true,
              dropdownColor: AppColors.card,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.savings),
              items: _compoundingOptions
                  .map((o) => DropdownMenuItem(
                        value: o.value,
                        child: Text(o.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _compoundingFrequency = v;
                    _result = null;
                  });
                }
              },
            ),
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
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.savings,
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
                  value: NumberFormatter.formatCurrency(_principalValue, symbol: symbol),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Interest Earned',
                  value: NumberFormatter.formatCurrency(r.interestEarned, symbol: symbol),
                  valueColor: AppColors.savings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Effective Annual Rate',
            value: NumberFormatter.formatPercent(r.effectiveRate),
            isHighlighted: true,
            subtitle: '$_selectedCompoundingLabel compounding over $_durationLabel',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Principal',
                value: NumberFormatter.formatCurrency(_principalValue, symbol: symbol),
              ),
              ResultItem(
                label: 'Rate',
                value: '${_annualRate.toStringAsFixed(1)}% p.a. ($_selectedCompoundingLabel)',
              ),
              ResultItem(
                label: 'Duration',
                value: _durationLabel,
              ),
              ResultItem(
                label: 'Interest Earned',
                value: NumberFormatter.formatCurrency(r.interestEarned, symbol: symbol),
                color: AppColors.savings,
              ),
              ResultItem(
                label: 'Maturity Amount',
                value: NumberFormatter.formatCurrency(r.maturityAmount, symbol: symbol),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompoundingOption {
  final String label;
  final int value;
  const _CompoundingOption(this.label, this.value);
}

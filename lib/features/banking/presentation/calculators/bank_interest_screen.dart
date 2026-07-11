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

class BankInterestScreen extends CalculatorBaseScreen {
  const BankInterestScreen({super.key})
      : super(
          calculatorId: 'bank_interest',
          calculatorName: 'Bank Interest Calculator',
          category: 'Banking',
        );

  @override
  ConsumerState<BankInterestScreen> createState() => _BankInterestScreenState();
}

class _BankInterestScreenState extends CalculatorBaseState<BankInterestScreen> {
  final _principalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _rate = 7.0;
  int _months = 12;
  int _compounding = 4;
  double? _maturityAmount;
  double? _interestEarned;

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
  bool get hasResult => _maturityAmount != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _principalValue => NumberFormatter.tryParse(_principalController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Principal': NumberFormatter.formatCurrency(_principalValue, symbol: _symbol),
        'Rate': NumberFormatter.formatPercent(_rate),
        'Period': '$_months months',
        'Compounding': _selectedLabel,
      };

  @override
  Map<String, dynamic> get currentResults => _maturityAmount == null
      ? {}
      : {
          'Maturity Amount': NumberFormatter.formatCurrency(_maturityAmount!, symbol: _symbol),
          'Interest Earned': NumberFormatter.formatCurrency(_interestEarned!, symbol: _symbol),
        };

  @override
  String get resultSummary => _maturityAmount == null
      ? ''
      : 'Maturity: ${NumberFormatter.formatCurrency(_maturityAmount!, symbol: _symbol)} | '
          'Interest: ${NumberFormatter.formatCurrency(_interestEarned!, symbol: _symbol)}';

  String get _selectedLabel =>
      _compoundingOptions.firstWhere((o) => o.value == _compounding).label;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final principal = _principalValue;
    if (principal <= 0) return;

    final t = _months / 12.0;
    final r = _rate / 100;
    double maturity;
    double interest;

    if (_compounding == 0) {
      interest = principal * r * t;
      maturity = principal + interest;
    } else {
      final n = _compounding;
      maturity = principal * pow(1 + r / n, n * t);
      interest = maturity - principal;
    }

    setState(() {
      _maturityAmount = maturity;
      _interestEarned = interest;
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _rate = 7.0;
      _months = 12;
      _compounding = 4;
      _maturityAmount = null;
      _interestEarned = null;
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
                    hint: '100000',
                    controller: _principalController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_maturityAmount != null) setState(() { _maturityAmount = null; _interestEarned = null; }); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Interest Rate',
                    value: _rate,
                    min: 1, max: 15, divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _rate = v; _maturityAmount = null; _interestEarned = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Duration (Months)',
                    value: _months.toDouble(),
                    min: 1, max: 60, divisions: 59,
                    displayValue: (v) => '${v.toInt()} months',
                    onChanged: (v) => setState(() { _months = v.toInt(); _maturityAmount = null; _interestEarned = null; }),
                  ),
                  const SizedBox(height: 20),
                  _buildCompoundingDropdown(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate', icon: Icons.calculate_rounded,
                          onPressed: _calculate, width: double.infinity,
                          color: AppColors.banking,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.banking),
                    ],
                  ),
                ],
              ),
            ),
            if (_maturityAmount != null) ...[
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
        const Text('Compounding Frequency',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _compounding,
              isExpanded: true,
              dropdownColor: AppColors.card,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.banking),
              items: _compoundingOptions
                  .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() { _compounding = v; _maturityAmount = null; _interestEarned = null; });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(String symbol) {
    final maturity = _maturityAmount!;
    final interest = _interestEarned!;
    final effectiveRate = _principalValue > 0
        ? (interest / _principalValue) * (12.0 / _months) * 100
        : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Center(
            child: Column(
              children: [
                const Text('Maturity Amount', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: maturity,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.banking),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Principal', value: NumberFormatter.formatCurrency(_principalValue, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Interest Earned', value: NumberFormatter.formatCurrency(interest, symbol: symbol),
                    valueColor: AppColors.banking),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Effective Annual Rate',
            value: NumberFormatter.formatPercent(effectiveRate),
            isHighlighted: true,
            subtitle: '$_selectedLabel over $_months months @ ${_rate.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(label: 'Principal', value: NumberFormatter.formatCurrency(_principalValue, symbol: symbol)),
              ResultItem(label: 'Rate', value: '${_rate.toStringAsFixed(1)}% p.a. ($_selectedLabel)'),
              ResultItem(label: 'Duration', value: '$_months months'),
              ResultItem(label: 'Interest Earned', value: NumberFormatter.formatCurrency(interest, symbol: symbol), color: AppColors.banking),
              ResultItem(label: 'Maturity Amount', value: NumberFormatter.formatCurrency(maturity, symbol: symbol), isHighlighted: true),
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

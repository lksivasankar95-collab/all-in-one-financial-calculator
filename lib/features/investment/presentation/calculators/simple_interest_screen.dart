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

class SimpleInterestScreen extends CalculatorBaseScreen {
  const SimpleInterestScreen({super.key})
      : super(
          calculatorId: 'simple_interest',
          calculatorName: 'Simple Interest',
          category: 'Investment',
        );

  @override
  ConsumerState<SimpleInterestScreen> createState() =>
      _SimpleInterestScreenState();
}

class _SimpleInterestScreenState
    extends CalculatorBaseState<SimpleInterestScreen> {
  final _principalController = TextEditingController();
  double _rate = 8.0;
  int _years = 3;
  SimpleResult? _result;
  final _formKey = GlobalKey<FormState>();

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
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Simple Interest':
              NumberFormatter.formatCurrency(_result!.interest, symbol: _symbol),
          'Total Amount':
              NumberFormatter.formatCurrency(_result!.totalAmount, symbol: _symbol),
          'Monthly Interest':
              NumberFormatter.formatCurrency(_result!.interest / (_years * 12), symbol: _symbol),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'SI: ${NumberFormatter.formatCurrency(_principalValue, symbol: _symbol)} @ ${_rate}% '
          'for $_years yrs = Interest ${NumberFormatter.formatCurrency(_result!.interest, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _principalValue =>
      NumberFormatter.tryParse(_principalController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _result = InvestmentCalculators.calculateSimpleInterest(
        principal: _principalValue,
        rate: _rate,
        years: _years,
      );
    });
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _rate = 8.0;
      _years = 3;
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
                  buildSectionTitle('Loan / Investment Details'),
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
                    max: 30,
                    divisions: 29,
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
    final monthlyInterest = r.interest / (_years * 12);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Results'),
          Row(
            children: [
              Expanded(
                child: _BigResultTile(
                  label: 'Simple Interest',
                  value: NumberFormatter.formatCurrency(r.interest,
                      symbol: symbol),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigResultTile(
                  label: 'Total Amount',
                  value: NumberFormatter.formatCurrency(r.totalAmount,
                      symbol: symbol),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultCard(
            label: 'Monthly Interest Earned',
            value: NumberFormatter.formatCurrency(monthlyInterest, symbol: symbol),
            isHighlighted: true,
            subtitle: 'P × R / 1200 per month',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Principal (P)',
                value: NumberFormatter.formatCurrency(_principalValue,
                    symbol: symbol),
              ),
              ResultItem(
                label: 'Rate (R)',
                value: NumberFormatter.formatPercent(_rate),
              ),
              ResultItem(
                label: 'Time (T)',
                value: '$_years years',
              ),
              ResultItem(
                label: 'Simple Interest (P×R×T/100)',
                value: NumberFormatter.formatCurrency(r.interest,
                    symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Total Amount (P + SI)',
                value: NumberFormatter.formatCurrency(r.totalAmount,
                    symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Monthly Interest',
                value: NumberFormatter.formatCurrency(monthlyInterest,
                    symbol: symbol),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BigResultTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

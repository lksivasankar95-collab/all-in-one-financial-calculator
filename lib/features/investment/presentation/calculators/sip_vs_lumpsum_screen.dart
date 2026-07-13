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

class SipVsLumpsumScreen extends CalculatorBaseScreen {
  const SipVsLumpsumScreen({super.key})
      : super(
          calculatorId: 'sip_vs_lumpsum',
          calculatorName: 'SIP vs Lumpsum',
          category: 'Investment',
        );

  @override
  ConsumerState<SipVsLumpsumScreen> createState() => _SipVsLumpsumScreenState();
}

class _SipVsLumpsumScreenState extends CalculatorBaseState<SipVsLumpsumScreen> {
  final _amountController = TextEditingController();
  double _annualReturn = 12.0;
  int _years = 10;
  double? _lumpsumValue;
  double? _sipValue;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _lumpsumValue != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Total Investment':
            NumberFormatter.formatCurrency(_totalAmount, symbol: _symbol),
        'Annual Return Rate': NumberFormatter.formatPercent(_annualReturn),
        'Investment Period': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _lumpsumValue == null
      ? {}
      : {
          'Lumpsum Value':
              NumberFormatter.formatCurrency(_lumpsumValue!, symbol: _symbol),
          'SIP Value':
              NumberFormatter.formatCurrency(_sipValue!, symbol: _symbol),
          'Difference':
              NumberFormatter.formatCurrency(_difference, symbol: _symbol),
        };

  @override
  String get resultSummary => _lumpsumValue == null
      ? ''
      : 'SIP vs Lumpsum: Lumpsum=${NumberFormatter.formatCurrency(_lumpsumValue!, symbol: _symbol)} | '
          'SIP=${NumberFormatter.formatCurrency(_sipValue!, symbol: _symbol)} | $_recommendation';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _totalAmount =>
      NumberFormatter.tryParse(_amountController.text) ?? 0;
  double get _monthlySip => _totalAmount / (_years * 12);
  double get _difference => (_lumpsumValue! - _sipValue!).abs();
  String get _recommendation =>
      _lumpsumValue! >= _sipValue! ? 'Lumpsum is better' : 'SIP is better';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final total = _totalAmount;
    if (total <= 0) return;

    final double r = _annualReturn / 1200;
    final int n = _years * 12;
    final double monthly = total / n;

    double sipFV;
    if (r == 0) {
      sipFV = monthly * n;
    } else {
      sipFV = monthly * (((pow(1 + r, n) - 1) / r) * (1 + r));
    }

    final double lumpsumFV = total * pow(1 + _annualReturn / 100, _years);

    setState(() {
      _lumpsumValue = lumpsumFV;
      _sipValue = sipFV;
    });
  }

  void _reset() {
    setState(() {
      _amountController.clear();
      _annualReturn = 12.0;
      _years = 10;
      _lumpsumValue = null;
      _sipValue = null;
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
                    label: 'Total Investment Amount',
                    hint: '12,00,000',
                    controller: _amountController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_lumpsumValue != null) {
                        setState(() => _lumpsumValue = null);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Expected Annual Return',
                    value: _annualReturn,
                    min: 1,
                    max: 30,
                    divisions: 290,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      setState(() {
                        _annualReturn = v;
                        if (_lumpsumValue != null) _lumpsumValue = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Investment Period',
                    value: _years.toDouble(),
                    min: 1,
                    max: 40,
                    divisions: 39,
                    displayValue: (v) =>
                        '${v.toInt()} ${v.toInt() == 1 ? "yr" : "yrs"}',
                    onChanged: (v) {
                      setState(() {
                        _years = v.toInt();
                        if (_lumpsumValue != null) _lumpsumValue = null;
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
            if (_lumpsumValue != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final lumpsum = _lumpsumValue!;
    final sip = _sipValue!;
    final diff = _difference;
    final lumpsumBetter = lumpsum >= sip;
    final monthly = _monthlySip;

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Side-by-Side Comparison'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Lumpsum Value',
                      value: NumberFormatter.formatCurrency(
                          lumpsum, symbol: symbol),
                      valueColor: lumpsumBetter
                          ? AppColors.success
                          : AppColors.textPrimary,
                      isHighlighted: lumpsumBetter,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'SIP Value',
                      value: NumberFormatter.formatCurrency(
                          sip, symbol: symbol),
                      valueColor: !lumpsumBetter
                          ? AppColors.success
                          : AppColors.textPrimary,
                      isHighlighted: !lumpsumBetter,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Difference',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 4),
                    AnimatedResultValue(
                      value: diff,
                      formatter: (v) =>
                          NumberFormatter.formatCurrency(v, symbol: symbol),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color:
                            lumpsumBetter ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (lumpsumBetter ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (lumpsumBetter ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      lumpsumBetter
                          ? Icons.trending_up_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: lumpsumBetter
                          ? AppColors.success
                          : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommendation: $_recommendation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: lumpsumBetter
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultSummaryCard(
          title: 'Detailed Comparison',
          items: [
            ResultItem(
              label: 'Total Investment',
              value: NumberFormatter.formatCurrency(
                  _totalAmount, symbol: symbol),
            ),
            ResultItem(
              label: 'Monthly SIP',
              value: NumberFormatter.formatCurrency(monthly, symbol: symbol),
            ),
            ResultItem(
              label: 'Lumpsum Final Value',
              value: NumberFormatter.formatCurrency(
                  lumpsum, symbol: symbol),
              color: lumpsumBetter ? AppColors.success : AppColors.textPrimary,
            ),
            ResultItem(
              label: 'SIP Final Value',
              value: NumberFormatter.formatCurrency(sip, symbol: symbol),
              color:
                  !lumpsumBetter ? AppColors.success : AppColors.textPrimary,
            ),
            ResultItem(
              label: 'Difference',
              value: NumberFormatter.formatCurrency(diff, symbol: symbol),
              color: lumpsumBetter ? AppColors.success : AppColors.error,
            ),
            ResultItem(
              label: 'Recommendation',
              value: _recommendation,
              isHighlighted: true,
              color: lumpsumBetter ? AppColors.success : AppColors.error,
            ),
          ],
        ),
      ],
    );
  }
}

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

class MutualFundReturnsScreen extends CalculatorBaseScreen {
  const MutualFundReturnsScreen({super.key})
      : super(
          calculatorId: 'mutual_fund_returns',
          calculatorName: 'Mutual Fund Returns',
          category: 'Investment',
        );

  @override
  ConsumerState<MutualFundReturnsScreen> createState() =>
      _MutualFundReturnsScreenState();
}

class _MutualFundReturnsScreenState
    extends CalculatorBaseState<MutualFundReturnsScreen> {
  final _lumpsumController = TextEditingController();
  final _monthlyController = TextEditingController();
  double _annualReturn = 12.0;
  int _years = 10;
  SipResult? _sipResult;
  LumpsumResult? _lumpsumResult;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _lumpsumController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _sipResult != null && _lumpsumResult != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Lumpsum Investment':
            NumberFormatter.formatCurrency(_lumpsumValue, symbol: _symbol),
        'Monthly SIP':
            NumberFormatter.formatCurrency(_monthlyValue, symbol: _symbol),
        'Annual Return Rate': NumberFormatter.formatPercent(_annualReturn),
        'Investment Period': '$_years years',
      };

  @override
  Map<String, dynamic> get currentResults => _sipResult == null
      ? {}
      : {
          'SIP Total Value':
              NumberFormatter.formatCurrency(_sipResult!.totalValue, symbol: _symbol),
          'SIP Invested':
              NumberFormatter.formatCurrency(_sipResult!.totalInvested, symbol: _symbol),
          'SIP Returns':
              NumberFormatter.formatCurrency(_sipResult!.estimatedReturns, symbol: _symbol),
          'Lumpsum Total Value':
              NumberFormatter.formatCurrency(_lumpsumResult!.totalValue, symbol: _symbol),
          'Lumpsum Profit':
              NumberFormatter.formatCurrency(_lumpsumResult!.totalProfit, symbol: _symbol),
          'Combined Value':
              NumberFormatter.formatCurrency(_combinedValue, symbol: _symbol),
        };

  @override
  String get resultSummary => _sipResult == null
      ? ''
      : 'Mutual Fund: SIP=${NumberFormatter.formatCurrency(_sipResult!.totalValue, symbol: _symbol)} + '
          'Lumpsum=${NumberFormatter.formatCurrency(_lumpsumResult!.totalValue, symbol: _symbol)} = '
          '${NumberFormatter.formatCurrency(_combinedValue, symbol: _symbol)}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _lumpsumValue =>
      NumberFormatter.tryParse(_lumpsumController.text) ?? 0;
  double get _monthlyValue =>
      NumberFormatter.tryParse(_monthlyController.text) ?? 0;
  double get _combinedValue =>
      (_sipResult?.totalValue ?? 0) + (_lumpsumResult?.totalValue ?? 0);

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sipResult = InvestmentCalculators.calculateSip(
        monthlyInvestment: _monthlyValue,
        annualReturnRate: _annualReturn,
        years: _years,
      );
      _lumpsumResult = InvestmentCalculators.calculateLumpsum(
        principal: _lumpsumValue,
        annualReturnRate: _annualReturn,
        years: _years,
        compoundingFrequency: 12,
      );
    });
  }

  void _reset() {
    setState(() {
      _lumpsumController.clear();
      _monthlyController.clear();
      _annualReturn = 12.0;
      _years = 10;
      _sipResult = null;
      _lumpsumResult = null;
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
                    label: 'Lumpsum Investment',
                    hint: '1,00,000',
                    controller: _lumpsumController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_sipResult != null) setState(() => _sipResult = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly SIP',
                    hint: '5,000',
                    controller: _monthlyController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_sipResult != null) setState(() => _sipResult = null);
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
                        if (_sipResult != null) _sipResult = null;
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
                        if (_sipResult != null) _sipResult = null;
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
            if (_sipResult != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final sip = _sipResult!;
    final lump = _lumpsumResult!;
    final combined = _combinedValue;

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('SIP Returns'),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'SIP Total Value',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 6),
                    AnimatedResultValue(
                      value: sip.totalValue,
                      formatter: (v) =>
                          NumberFormatter.formatCurrency(v, symbol: symbol),
                      style: const TextStyle(
                        fontSize: 28,
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
                      label: 'Total Invested',
                      value: NumberFormatter.formatCurrency(sip.totalInvested,
                          symbol: symbol),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Est. Returns',
                      value: NumberFormatter.formatCurrency(
                          sip.estimatedReturns,
                          symbol: symbol),
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Lumpsum Returns'),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Lumpsum Total Value',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 6),
                    AnimatedResultValue(
                      value: lump.totalValue,
                      formatter: (v) =>
                          NumberFormatter.formatCurrency(v, symbol: symbol),
                      style: const TextStyle(
                        fontSize: 28,
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
                      value: NumberFormatter.formatCurrency(
                          _lumpsumValue,
                          symbol: symbol),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Est. Profit',
                      value: NumberFormatter.formatCurrency(lump.totalProfit,
                          symbol: symbol),
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Combined Portfolio'),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Total Portfolio Value',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 6),
                    AnimatedResultValue(
                      value: combined,
                      formatter: (v) =>
                          NumberFormatter.formatCurrency(v, symbol: symbol),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResultSummaryCard(
                title: 'Comparison Summary',
                items: [
                  ResultItem(
                    label: 'SIP Total Investment',
                    value: NumberFormatter.formatCurrency(
                        sip.totalInvested, symbol: symbol),
                  ),
                  ResultItem(
                    label: 'SIP Final Value',
                    value: NumberFormatter.formatCurrency(
                        sip.totalValue, symbol: symbol),
                    color: AppColors.success,
                  ),
                  ResultItem(
                    label: 'SIP Returns',
                    value: NumberFormatter.formatCurrency(
                        sip.estimatedReturns, symbol: symbol),
                    color: AppColors.success,
                  ),
                  ResultItem(
                    label: 'Lumpsum Investment',
                    value: NumberFormatter.formatCurrency(
                        _lumpsumValue, symbol: symbol),
                  ),
                  ResultItem(
                    label: 'Lumpsum Final Value',
                    value: NumberFormatter.formatCurrency(
                        lump.totalValue, symbol: symbol),
                    color: AppColors.success,
                  ),
                  ResultItem(
                    label: 'Lumpsum Profit',
                    value: NumberFormatter.formatCurrency(
                        lump.totalProfit, symbol: symbol),
                    color: AppColors.success,
                  ),
                  ResultItem(
                    label: 'Combined Portfolio Value',
                    value: NumberFormatter.formatCurrency(
                        combined, symbol: symbol),
                    isHighlighted: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

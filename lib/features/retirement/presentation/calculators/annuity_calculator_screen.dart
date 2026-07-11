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
import '../../domain/retirement_calculators.dart';

class AnnuityCalculatorScreen extends CalculatorBaseScreen {
  const AnnuityCalculatorScreen({super.key})
      : super(
          calculatorId: 'annuity_calculator',
          calculatorName: 'Annuity Calculator',
          category: 'Retirement',
        );

  @override
  ConsumerState<AnnuityCalculatorScreen> createState() => _AnnuityCalculatorScreenState();
}

class _AnnuityCalculatorScreenState extends CalculatorBaseState<AnnuityCalculatorScreen> {
  final _corpusController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _annuityRate = 6.0;
  int _termYears = 20;
  AnnuityResult? _result;

  @override
  void dispose() {
    _corpusController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _corpusValue => NumberFormatter.tryParse(_corpusController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Corpus': NumberFormatter.formatCurrency(_corpusValue, symbol: _symbol),
        'Annuity Rate': NumberFormatter.formatPercent(_annuityRate),
        'Term': '$_termYears years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Annual Income': NumberFormatter.formatCurrency(_result!.annualPayout, symbol: _symbol),
        'Monthly Income': NumberFormatter.formatCurrency(_result!.monthlyPayout, symbol: _symbol),
        'Total Payout': NumberFormatter.formatCurrency(_result!.totalPayout, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Annual: ${NumberFormatter.formatCurrency(_result!.annualPayout, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.totalPayout, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_corpusValue <= 0) return;

    setState(() {
      _result = RetirementCalculators.calculateAnnuity(
        corpus: _corpusValue,
        annuityRate: _annuityRate,
        termYears: _termYears,
      );
    });
  }

  void _reset() {
    setState(() {
      _corpusController.clear();
      _annuityRate = 6.0;
      _termYears = 20;
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
                  buildSectionTitle('Annuity Details'),
                  AppTextField(
                    label: 'Corpus / Investment Amount',
                    hint: '5000000',
                    controller: _corpusController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annuity Rate',
                    value: _annuityRate,
                    min: 1, max: 12, divisions: 110,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _annuityRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Term (Years)',
                    value: _termYears.toDouble(),
                    min: 5, max: 40, divisions: 35,
                    displayValue: (v) => '${v.toInt()} years',
                    onChanged: (v) => setState(() { _termYears = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate', icon: Icons.calculate_rounded,
                          onPressed: _calculate, width: double.infinity,
                          color: AppColors.retirement,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.retirement),
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
    final effectiveReturn = _corpusValue > 0 ? (r.totalPayout / _corpusValue - 1) * 100 : 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Annuity Income'),
          Center(
            child: Column(
              children: [
                const Text('Annual Annuity Income', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.annualPayout,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.retirement),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Monthly Income',
                    value: NumberFormatter.formatCurrency(r.monthlyPayout, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Total Payout',
                    value: NumberFormatter.formatCurrency(r.totalPayout, symbol: symbol),
                    valueColor: AppColors.retirement),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Effective Return',
            value: NumberFormatter.formatPercent(effectiveReturn),
            isHighlighted: true,
            subtitle: 'Over $_termYears years @ ${_annuityRate.toStringAsFixed(1)}% p.a.',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Annuity Summary',
            items: [
              ResultItem(label: 'Corpus Invested', value: NumberFormatter.formatCurrency(_corpusValue, symbol: symbol)),
              ResultItem(label: 'Annuity Rate', value: NumberFormatter.formatPercent(_annuityRate)),
              ResultItem(label: 'Term', value: '$_termYears years'),
              ResultItem(label: 'Monthly Income', value: NumberFormatter.formatCurrency(r.monthlyPayout, symbol: symbol)),
              ResultItem(label: 'Annual Income', value: NumberFormatter.formatCurrency(r.annualPayout, symbol: symbol), isHighlighted: true, color: AppColors.retirement),
              ResultItem(label: 'Total Payout', value: NumberFormatter.formatCurrency(r.totalPayout, symbol: symbol)),
            ],
          ),
        ],
      ),
    );
  }
}

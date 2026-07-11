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

class RentalYieldScreen extends CalculatorBaseScreen {
  const RentalYieldScreen({super.key})
      : super(
          calculatorId: 'rental_yield',
          calculatorName: 'Rental Yield Calculator',
          category: 'Real Estate',
        );

  @override
  ConsumerState<RentalYieldScreen> createState() => _RentalYieldScreenState();
}

class _RentalYieldScreenState extends CalculatorBaseState<RentalYieldScreen> {
  final _priceController = TextEditingController();
  final _rentController = TextEditingController();
  final _expensesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  RentalYieldResult? _result;

  @override
  void dispose() {
    _priceController.dispose();
    _rentController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _priceValue => NumberFormatter.tryParse(_priceController.text) ?? 0;
  double get _rentValue => NumberFormatter.tryParse(_rentController.text) ?? 0;
  double get _expensesValue => NumberFormatter.tryParse(_expensesController.text) ?? 0;
  double get _annualRent => _rentValue * 12;

  @override
  Map<String, dynamic> get currentInputs => {
        'Property Price': NumberFormatter.formatCurrency(_priceValue, symbol: _symbol),
        'Monthly Rent': NumberFormatter.formatCurrency(_rentValue, symbol: _symbol),
        'Annual Expenses': NumberFormatter.formatCurrency(_expensesValue, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Gross Yield': NumberFormatter.formatPercent(_result!.grossYield),
        'Net Yield': NumberFormatter.formatPercent(_result!.netYield),
        'Net Annual Income': NumberFormatter.formatCurrency(_result!.netIncome, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Gross: ${NumberFormatter.formatPercent(_result!.grossYield)} | Net: ${NumberFormatter.formatPercent(_result!.netYield)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_priceValue <= 0 || _rentValue <= 0) return;

    setState(() {
      _result = RealEstateCalculators.calculateRentalYield(
        propertyPrice: _priceValue,
        annualRent: _annualRent,
        expenses: _expensesValue,
      );
    });
  }

  void _reset() {
    setState(() {
      _priceController.clear();
      _rentController.clear();
      _expensesController.clear();
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
                  buildSectionTitle('Property Details'),
                  AppTextField(
                    label: 'Property Price / Market Value',
                    hint: '5000000', controller: _priceController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Rent Received',
                    hint: '25000', controller: _rentController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Annual Expenses (Maintenance, Tax, Insurance)',
                    hint: '50000', controller: _expensesController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return null; if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Calculate', icon: Icons.calculate_rounded,
                            onPressed: _calculate, width: double.infinity, color: AppColors.realEstate),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.realEstate),
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
    final roiAssessment = r.netYield >= 8 ? 'Excellent' : r.netYield >= 5 ? 'Good' : r.netYield >= 3 ? 'Average' : 'Below Average';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Yield Analysis'),
          Center(
            child: Column(
              children: [
                const Text('Net Rental Yield', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.netYield,
                  formatter: (v) => NumberFormatter.formatPercent(v),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.realEstate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Gross Yield', value: NumberFormatter.formatPercent(r.grossYield)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Annual Cash Flow',
                    value: NumberFormatter.formatCurrency(r.netIncome, symbol: symbol),
                    valueColor: r.netIncome >= 0 ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'ROI Assessment',
            value: roiAssessment,
            isHighlighted: true,
            valueColor: r.netYield >= 5 ? AppColors.success : r.netYield >= 3 ? AppColors.warning : AppColors.error,
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Yield Breakdown',
            items: [
              ResultItem(label: 'Property Value', value: NumberFormatter.formatCurrency(_priceValue, symbol: symbol)),
              ResultItem(label: 'Annual Rent', value: NumberFormatter.formatCurrency(_annualRent, symbol: symbol)),
              ResultItem(label: 'Annual Expenses', value: NumberFormatter.formatCurrency(_expensesValue, symbol: symbol)),
              ResultItem(label: 'Net Income', value: NumberFormatter.formatCurrency(r.netIncome, symbol: symbol),
                  color: r.netIncome >= 0 ? AppColors.success : AppColors.error),
              ResultItem(label: 'Gross Yield', value: NumberFormatter.formatPercent(r.grossYield)),
              ResultItem(label: 'Net Yield', value: NumberFormatter.formatPercent(r.netYield), isHighlighted: true, color: AppColors.realEstate),
            ],
          ),
        ],
      ),
    );
  }
}

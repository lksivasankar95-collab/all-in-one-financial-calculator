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
import '../../domain/insurance_calculators.dart';

class CarInsuranceScreen extends CalculatorBaseScreen {
  const CarInsuranceScreen({super.key})
      : super(
          calculatorId: 'car_insurance',
          calculatorName: 'Car Insurance Calculator',
          category: 'Insurance',
        );

  @override
  ConsumerState<CarInsuranceScreen> createState() => _CarInsuranceScreenState();
}

class _CarInsuranceScreenState extends CalculatorBaseState<CarInsuranceScreen> {
  final _carValueController = TextEditingController();
  final _excessController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _carAge = 5;
  double _noClaimBonus = 20;
  double? _totalPremium;
  double? _idv;

  @override
  void dispose() {
    _carValueController.dispose();
    _excessController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _totalPremium != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _carValue => NumberFormatter.tryParse(_carValueController.text) ?? 0;
  double get _excessValue => NumberFormatter.tryParse(_excessController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Car Value': NumberFormatter.formatCurrency(_carValue, symbol: _symbol),
        'Car Age': '$_carAge years',
        'NCB': '${_noClaimBonus.toStringAsFixed(0)}%',
      };

  @override
  Map<String, dynamic> get currentResults => _totalPremium == null ? {} : {
        'Total Premium': NumberFormatter.formatCurrency(_totalPremium!, symbol: _symbol),
        'IDV': NumberFormatter.formatCurrency(_idv!, symbol: _symbol),
      };

  @override
  String get resultSummary => _totalPremium == null ? ''
      : 'Premium: ${NumberFormatter.formatCurrency(_totalPremium!, symbol: _symbol)} | IDV: ${NumberFormatter.formatCurrency(_idv!, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_carValue <= 0) return;

    final result = InsuranceCalculators.calculateCarInsurance(
      carValue: _carValue,
      ageOfCar: _carAge,
      noClaimBonus: _noClaimBonus,
    );

    final excessDeduction = result.idv > 0 ? (_excessValue / result.idv) * result.annualPremium : 0;
    final finalPremium = result.annualPremium + excessDeduction;

    setState(() {
      _totalPremium = finalPremium;
      _idv = result.idv;
    });
  }

  void _reset() {
    setState(() {
      _carValueController.clear();
      _excessController.clear();
      _carAge = 5;
      _noClaimBonus = 20;
      _totalPremium = null;
      _idv = null;
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
                  buildSectionTitle('Vehicle Details'),
                  AppTextField(
                    label: 'Car Value (Ex-Showroom)',
                    hint: '800000',
                    controller: _carValueController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_totalPremium != null) setState(() { _totalPremium = null; _idv = null; }); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Car Age',
                    value: _carAge.toDouble(),
                    min: 1, max: 15, divisions: 14,
                    displayValue: (v) => '${v.toInt()} ${v.toInt() == 1 ? 'year' : 'years'}',
                    onChanged: (v) => setState(() { _carAge = v.toInt(); _totalPremium = null; _idv = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'No Claim Bonus (NCB)',
                    value: _noClaimBonus,
                    min: 0, max: 50, divisions: 50,
                    displayValue: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() { _noClaimBonus = v; _totalPremium = null; _idv = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Voluntary Excess',
                    hint: '0',
                    controller: _excessController,
                    prefix: symbol,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) { if (_totalPremium != null) setState(() { _totalPremium = null; _idv = null; }); },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate', icon: Icons.calculate_rounded,
                          onPressed: _calculate, width: double.infinity,
                          color: AppColors.insurance,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.insurance),
                    ],
                  ),
                ],
              ),
            ),
            if (_totalPremium != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(symbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String symbol) {
    final premium = _totalPremium!;
    final idv = _idv!;
    final savings = _noClaimBonus > 0 ? premium * _noClaimBonus / 100 : 0.0;
    final ownDamage = premium * 0.65;
    final thirdParty = premium * 0.35;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Insurance Premium'),
          Center(
            child: Column(
              children: [
                const Text('Total Premium', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: premium,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.insurance),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'IDV', value: NumberFormatter.formatCurrency(idv, symbol: symbol),
                    valueColor: AppColors.insurance),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'NCB Savings', value: NumberFormatter.formatCurrency(savings, symbol: symbol),
                    valueColor: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Own Damage Premium',
            value: NumberFormatter.formatCurrency(ownDamage, symbol: symbol),
            subtitle: '~65% of total premium',
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Third Party Premium',
            value: NumberFormatter.formatCurrency(thirdParty, symbol: symbol),
            subtitle: '~35% of total premium',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Premium Breakdown',
            items: [
              ResultItem(label: 'Car Value', value: NumberFormatter.formatCurrency(_carValue, symbol: symbol)),
              ResultItem(label: 'IDV', value: NumberFormatter.formatCurrency(idv, symbol: symbol)),
              ResultItem(label: 'Own Damage', value: NumberFormatter.formatCurrency(ownDamage, symbol: symbol)),
              ResultItem(label: 'Third Party', value: NumberFormatter.formatCurrency(thirdParty, symbol: symbol)),
              ResultItem(label: 'Total Premium', value: NumberFormatter.formatCurrency(premium, symbol: symbol), isHighlighted: true, color: AppColors.insurance),
            ],
          ),
        ],
      ),
    );
  }
}

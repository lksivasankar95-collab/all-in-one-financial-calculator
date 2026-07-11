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
import '../../domain/crypto_calculators.dart';

class CryptoStakingScreen extends CalculatorBaseScreen {
  const CryptoStakingScreen({super.key})
      : super(
          calculatorId: 'crypto_staking',
          calculatorName: 'Crypto Staking Calculator',
          category: 'Crypto',
        );

  @override
  ConsumerState<CryptoStakingScreen> createState() => _CryptoStakingScreenState();
}

class _CryptoStakingScreenState extends CalculatorBaseState<CryptoStakingScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _apr = 10.0;
  int _periodDays = 30;
  bool _compound = false;
  StakingResult? _result;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _amountValue => NumberFormatter.tryParse(_amountController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Staking Amount': '\$${_amountValue.toStringAsFixed(2)}',
        'APR': NumberFormatter.formatPercent(_apr),
        'Period': '$_periodDays days',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Total Rewards': '\$${_result!.totalRewards.toStringAsFixed(2)}',
        'Total Value': '\$${_result!.totalValue.toStringAsFixed(2)}',
        'Effective APY': NumberFormatter.formatPercent(_result!.effectiveApr),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Rewards: \$${_result!.totalRewards.toStringAsFixed(2)} | '
          'Value: \$${_result!.totalValue.toStringAsFixed(2)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_amountValue <= 0) return;

    final freq = _compound ? 365 : 0;

    setState(() {
      _result = CryptoCalculators.calculateCryptoStaking(
        stakingAmount: _amountValue,
        apr: _apr,
        stakingPeriodDays: _periodDays,
        compoundingFrequency: freq,
      );
    });
  }

  void _reset() {
    setState(() {
      _amountController.clear();
      _apr = 10.0;
      _periodDays = 30;
      _compound = false;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  buildSectionTitle('Staking Details'),
                  AppTextField(label: 'Staking Amount (USD)', hint: '1000', controller: _amountController, prefix: '\$',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); }),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'APR', value: _apr,
                    min: 1, max: 50, divisions: 490,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _apr = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Staking Period', value: _periodDays.toDouble(),
                    min: 1, max: 365, divisions: 364,
                    displayValue: (v) => '${v.toInt()} days',
                    onChanged: (v) => setState(() { _periodDays = v.toInt(); _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  _buildCompoundToggle(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Calculate', icon: Icons.calculate_rounded,
                            onPressed: _calculate, width: double.infinity, color: AppColors.crypto),
                      ),
                      const SizedBox(width: 10),
                      AppButton(label: 'Reset', isOutlined: true, onPressed: _reset, color: AppColors.crypto),
                    ],
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompoundToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Compounding',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleChip(label: 'Simple', selected: !_compound,
                  onTap: () => setState(() { _compound = false; _result = null; })),
              _ToggleChip(label: 'Compound Daily', selected: _compound,
                  onTap: () => setState(() { _compound = true; _result = null; })),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Staking Rewards'),
          Center(
            child: Column(
              children: [
                const Text('Staking Rewards Earned', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalRewards,
                  formatter: (v) => '\$${v.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.crypto),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Total Value',
                    value: '\$${r.totalValue.toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Effective APY',
                    value: NumberFormatter.formatPercent(r.effectiveApr),
                    valueColor: AppColors.crypto),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Staking Summary',
            items: [
              ResultItem(label: 'Staked Amount', value: '\$${_amountValue.toStringAsFixed(2)}'),
              ResultItem(label: 'APR', value: NumberFormatter.formatPercent(_apr)),
              ResultItem(label: 'Period', value: '$_periodDays days'),
              ResultItem(label: 'Compounding', value: _compound ? 'Daily' : 'None'),
              ResultItem(label: 'Total Rewards', value: '\$${r.totalRewards.toStringAsFixed(2)}', isHighlighted: true, color: AppColors.crypto),
              ResultItem(label: 'Total Value', value: '\$${r.totalValue.toStringAsFixed(2)}', isHighlighted: true),
              ResultItem(label: 'Effective APY', value: NumberFormatter.formatPercent(r.effectiveApr)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.crypto.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: selected ? Border.all(color: AppColors.crypto.withValues(alpha: 0.5)) : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? AppColors.crypto : AppColors.textHint,
        )),
      ),
    );
  }
}

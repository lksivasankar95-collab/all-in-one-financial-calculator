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

class WorkingCapitalScreen extends CalculatorBaseScreen {
  const WorkingCapitalScreen({super.key})
      : super(
          calculatorId: 'working_capital',
          calculatorName: 'Working Capital',
          category: 'Business',
        );

  @override
  ConsumerState<WorkingCapitalScreen> createState() =>
      _WorkingCapitalScreenState();
}

class _WorkingCapitalScreenState
    extends CalculatorBaseState<WorkingCapitalScreen> {
  final _currentAssetsController = TextEditingController();
  final _currentLiabilitiesController = TextEditingController();
  final _inventoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  WorkingCapitalResult? _result;

  @override
  void dispose() {
    _currentAssetsController.dispose();
    _currentLiabilitiesController.dispose();
    _inventoryController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _currentAssets =>
      NumberFormatter.tryParse(_currentAssetsController.text) ?? 0;
  double get _currentLiabilities =>
      NumberFormatter.tryParse(_currentLiabilitiesController.text) ?? 0;
  double get _inventory =>
      NumberFormatter.tryParse(_inventoryController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Current Assets':
            NumberFormatter.formatCurrency(_currentAssets, symbol: _symbol),
        'Current Liabilities': NumberFormatter.formatCurrency(
            _currentLiabilities, symbol: _symbol),
        'Inventory':
            NumberFormatter.formatCurrency(_inventory, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Working Capital': NumberFormatter.formatCurrency(
              _result!.workingCapital, symbol: _symbol),
          'Current Ratio':
              _result!.currentRatio.toStringAsFixed(2),
          'Quick Ratio':
              _result!.quickRatio.toStringAsFixed(2),
          'Assessment': _result!.healthAssessment,
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'WC: ${NumberFormatter.formatCurrency(_result!.workingCapital, symbol: _symbol)} | '
          'CR: ${_result!.currentRatio.toStringAsFixed(2)} | ${_result!.healthAssessment}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final double workingCapital = _currentAssets - _currentLiabilities;
    final double currentRatio =
        _currentLiabilities > 0 ? _currentAssets / _currentLiabilities : 0;
    final double quickRatio = _currentLiabilities > 0
        ? (_currentAssets - _inventory) / _currentLiabilities
        : 0;

    String healthAssessment;
    Color healthColor;
    IconData healthIcon;

    if (currentRatio >= 2 && quickRatio >= 1) {
      healthAssessment = 'Healthy';
      healthColor = AppColors.success;
      healthIcon = Icons.check_circle_rounded;
    } else if (currentRatio >= 1 && quickRatio >= 0.5) {
      healthAssessment = 'Moderate';
      healthColor = AppColors.warning;
      healthIcon = Icons.info_rounded;
    } else {
      healthAssessment = 'Risky';
      healthColor = AppColors.error;
      healthIcon = Icons.warning_rounded;
    }

    setState(() {
      _result = WorkingCapitalResult(
        workingCapital: workingCapital,
        currentRatio: currentRatio,
        quickRatio: quickRatio,
        healthAssessment: healthAssessment,
        healthColor: healthColor,
        healthIcon: healthIcon,
      );
    });
  }

  void _reset() {
    setState(() {
      _currentAssetsController.clear();
      _currentLiabilitiesController.clear();
      _inventoryController.clear();
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
                  buildSectionTitle('Balance Sheet Items'),
                  AppTextField(
                    label: 'Current Assets',
                    hint: '5,00,000',
                    controller: _currentAssetsController,
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
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Current Liabilities',
                    hint: '2,00,000',
                    controller: _currentLiabilitiesController,
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
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Inventory',
                    hint: '1,00,000',
                    controller: _inventoryController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) < 0) {
                        return 'Enter a valid inventory value';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
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
                          color: AppColors.business,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.business,
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Liquidity Analysis'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: r.healthColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: r.healthColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(r.healthIcon, color: r.healthColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  r.healthAssessment,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: r.healthColor,
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
                  label: 'Working Capital',
                  value: NumberFormatter.formatCurrency(
                      r.workingCapital, symbol: symbol),
                  valueColor: r.workingCapital >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Current Ratio',
                  value: r.currentRatio.toStringAsFixed(2),
                  valueColor: r.currentRatio >= 2
                      ? AppColors.success
                      : r.currentRatio >= 1
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Quick Ratio',
                  value: r.quickRatio.toStringAsFixed(2),
                  valueColor: r.quickRatio >= 1
                      ? AppColors.success
                      : r.quickRatio >= 0.5
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Net Working Capital',
                  value: NumberFormatter.formatCurrency(
                      r.workingCapital, symbol: symbol),
                  valueColor: r.workingCapital >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Working Capital Summary',
            items: [
              ResultItem(
                label: 'Current Assets',
                value: NumberFormatter.formatCurrency(
                    _currentAssets, symbol: symbol),
              ),
              ResultItem(
                label: '(-) Current Liabilities',
                value: '- ${NumberFormatter.formatCurrency(_currentLiabilities, symbol: symbol)}',
                color: AppColors.error,
              ),
              ResultItem(
                label: 'Working Capital',
                value: NumberFormatter.formatCurrency(
                    r.workingCapital, symbol: symbol),
                isHighlighted: true,
                color: r.workingCapital >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
              const ResultItem(label: '', value: ''),
              ResultItem(
                label: 'Current Ratio (CA/CL)',
                value: r.currentRatio.toStringAsFixed(2),
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Quick Ratio ((CA-Inv)/CL)',
                value: r.quickRatio.toStringAsFixed(2),
                isHighlighted: true,
              ),
              const ResultItem(label: '', value: ''),
              ResultItem(
                label: 'Assessment',
                value: r.healthAssessment,
                color: r.healthColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkingCapitalResult {
  final double workingCapital;
  final double currentRatio;
  final double quickRatio;
  final String healthAssessment;
  final Color healthColor;
  final IconData healthIcon;

  const WorkingCapitalResult({
    required this.workingCapital,
    required this.currentRatio,
    required this.quickRatio,
    required this.healthAssessment,
    required this.healthColor,
    required this.healthIcon,
  });
}

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

class GoalAdvancedScreen extends CalculatorBaseScreen {
  const GoalAdvancedScreen({super.key})
      : super(
          calculatorId: 'goal_advanced',
          calculatorName: 'Goal Advanced',
          category: 'Savings',
        );

  @override
  ConsumerState<GoalAdvancedScreen> createState() =>
      _GoalAdvancedScreenState();
}

class _GoalAdvancedScreenState extends CalculatorBaseState<GoalAdvancedScreen> {
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentSavingsController = TextEditingController();
  final _monthlyAdditionController = TextEditingController();
  double _annualReturn = 10.0;
  double _targetYears = 10.0;
  GoalAdvancedResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _currentSavingsController.dispose();
    _monthlyAdditionController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Goal Name': _goalNameController.text.isNotEmpty
            ? _goalNameController.text
            : 'Unnamed Goal',
        'Target Amount': NumberFormatter.formatCurrency(
            _targetAmount, symbol: _symbol),
        'Current Savings': NumberFormatter.formatCurrency(
            _currentSavings, symbol: _symbol),
        'Monthly Addition':
            NumberFormatter.formatCurrency(_monthlyAddition, symbol: _symbol),
        'Annual Return': NumberFormatter.formatPercent(_annualReturn),
        'Target Years': '${_targetYears.toInt()} years',
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Projected Amount': NumberFormatter.formatCurrency(
              _result!.projectedAmount, symbol: _symbol),
          'Shortfall/Surplus': NumberFormatter.formatCurrency(
              _result!.shortfall, symbol: _symbol),
          'Adjusted Monthly Needed': NumberFormatter.formatCurrency(
              _result!.adjustedMonthly, symbol: _symbol),
          'Status': _result!.status,
          'Progress': NumberFormatter.formatPercent(_result!.progressPercent),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Goal: ${_goalNameController.text.isNotEmpty ? _goalNameController.text : "Unnamed"} | '
          'Projected: ${NumberFormatter.formatCurrency(_result!.projectedAmount, symbol: _symbol)} | '
          'Status: ${_result!.status}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _targetAmount =>
      NumberFormatter.tryParse(_targetAmountController.text) ?? 0;
  double get _currentSavings =>
      NumberFormatter.tryParse(_currentSavingsController.text) ?? 0;
  double get _monthlyAddition =>
      NumberFormatter.tryParse(_monthlyAdditionController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final target = _targetAmount;
    if (target <= 0) return;

    final int t = _targetYears.toInt();
    final double r = _annualReturn / 1200;
    final int n = t * 12;

    final double fvCurrent = _currentSavings * pow(1 + r, n);
    final double fvAddition = _monthlyAddition *
        (((pow(1 + r, n) - 1) / r) * (1 + r));
    final double projectedAmount = fvCurrent + fvAddition;
    final double shortfall = target - projectedAmount;

    double adjustedMonthly;
    if (shortfall <= 0) {
      adjustedMonthly = 0;
    } else if (r <= 0) {
      adjustedMonthly = shortfall / n;
    } else {
      adjustedMonthly = shortfall / ((pow(1 + r, n) - 1) / r);
    }

    final double progressPercent =
        target > 0 ? (projectedAmount / target) * 100 : 0;

    String status;
    String recommendation;
    Color statusColor;
    IconData statusIcon;

    if (progressPercent >= 110) {
      status = 'Ahead';
      statusColor = AppColors.success;
      statusIcon = Icons.emoji_events_rounded;
      recommendation =
          'You are ahead of your goal! Consider increasing your target or reallocating surplus funds.';
    } else if (progressPercent >= 95) {
      status = 'On Track';
      statusColor = AppColors.savings;
      statusIcon = Icons.check_circle_rounded;
      recommendation =
          'You are on track to reach your goal. Keep up your current savings plan!';
    } else if (progressPercent >= 75) {
      status = 'Slightly Behind';
      statusColor = AppColors.warning;
      statusIcon = Icons.trending_up_rounded;
      recommendation =
          'You are slightly behind. Consider increasing your monthly contribution to stay on track.';
    } else {
      status = 'Behind';
      statusColor = AppColors.error;
      statusIcon = Icons.warning_rounded;
      recommendation =
          'You are significantly behind your goal. Try increasing your monthly savings or extending your timeline.';
    }

    setState(() {
      _result = GoalAdvancedResult(
        projectedAmount: projectedAmount,
        shortfall: shortfall,
        adjustedMonthly: adjustedMonthly,
        progressPercent: progressPercent,
        status: status,
        statusColor: statusColor,
        statusIcon: statusIcon,
        recommendation: recommendation,
      );
    });
  }

  void _reset() {
    setState(() {
      _goalNameController.clear();
      _targetAmountController.clear();
      _currentSavingsController.clear();
      _monthlyAdditionController.clear();
      _annualReturn = 10.0;
      _targetYears = 10.0;
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
                  buildSectionTitle('Goal Details'),
                  AppTextField(
                    label: 'Goal Name',
                    hint: 'e.g., Down Payment',
                    controller: _goalNameController,
                    keyboardType: TextInputType.text,
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Target Amount',
                    hint: '50,00,000',
                    controller: _targetAmountController,
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
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Current Savings',
                    hint: '0',
                    controller: _currentSavingsController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Monthly Addition',
                    hint: '10,000',
                    controller: _monthlyAdditionController,
                    prefix: symbol,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Annual Return',
                    value: _annualReturn,
                    min: 1,
                    max: 15,
                    divisions: 140,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      _annualReturn = v;
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Target Years',
                    value: _targetYears,
                    min: 1,
                    max: 40,
                    divisions: 39,
                    displayValue: (v) => '${v.toInt()} yrs',
                    onChanged: (v) => setState(() {
                      _targetYears = v;
                      _result = null;
                    }),
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

  Widget _buildResultSection(String symbol) {
    final r = _result!;
    final goalName = _goalNameController.text.isNotEmpty
        ? _goalNameController.text
        : 'Goal';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Goal Analysis - $goalName'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: r.statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: r.statusColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(r.statusIcon, color: r.statusColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      r.status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: r.statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.recommendation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'Progress',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.progressPercent,
                  formatter: (v) => NumberFormatter.formatPercent(v),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: r.statusColor,
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
                  label: 'Projected Amount',
                  value: NumberFormatter.formatCurrency(
                      r.projectedAmount, symbol: symbol),
                  valueColor: AppColors.savings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: r.shortfall >= 0 ? 'Shortfall' : 'Surplus',
                  value: NumberFormatter.formatCurrency(
                      r.shortfall.abs(), symbol: symbol),
                  valueColor:
                      r.shortfall >= 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: r.adjustedMonthly > 0
                ? 'Adjusted Monthly Needed'
                : 'Additional Monthly Needed',
            value: r.adjustedMonthly > 0
                ? NumberFormatter.formatCurrency(
                    r.adjustedMonthly, symbol: symbol)
                : '${symbol}0',
            isHighlighted: true,
            valueColor: r.adjustedMonthly > 0
                ? AppColors.warning
                : AppColors.success,
            subtitle: r.adjustedMonthly <= 0
                ? 'You are already on track!'
                : 'Increase monthly addition to close the gap',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: '$goalName Details',
            items: [
              ResultItem(
                label: 'Target Amount',
                value: NumberFormatter.formatCurrency(
                    _targetAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Current Savings',
                value: NumberFormatter.formatCurrency(
                    _currentSavings, symbol: symbol),
              ),
              ResultItem(
                label: 'Monthly Addition',
                value: NumberFormatter.formatCurrency(
                    _monthlyAddition, symbol: symbol),
              ),
              ResultItem(
                label: 'Expected Return',
                value: NumberFormatter.formatPercent(_annualReturn),
              ),
              ResultItem(
                label: 'Time Horizon',
                value: '${_targetYears.toInt()} years',
              ),
              ResultItem(
                label: 'Projected Amount',
                value: NumberFormatter.formatCurrency(
                    r.projectedAmount, symbol: symbol),
                isHighlighted: true,
              ),
              ResultItem(
                label: r.shortfall >= 0 ? 'Shortfall' : 'Surplus',
                value: NumberFormatter.formatCurrency(
                    r.shortfall.abs(), symbol: symbol),
                color: r.shortfall >= 0 ? AppColors.error : AppColors.success,
              ),
              ResultItem(
                label: 'Progress',
                value: NumberFormatter.formatPercent(r.progressPercent),
                isHighlighted: true,
                color: r.statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GoalAdvancedResult {
  final double projectedAmount;
  final double shortfall;
  final double adjustedMonthly;
  final double progressPercent;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final String recommendation;

  const GoalAdvancedResult({
    required this.projectedAmount,
    required this.shortfall,
    required this.adjustedMonthly,
    required this.progressPercent,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.recommendation,
  });
}

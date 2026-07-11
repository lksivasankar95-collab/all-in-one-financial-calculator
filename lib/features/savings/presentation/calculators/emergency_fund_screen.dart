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
import '../../domain/savings_calculators.dart';

class EmergencyFundScreen extends CalculatorBaseScreen {
  const EmergencyFundScreen({super.key})
      : super(
          calculatorId: 'emergency_fund',
          calculatorName: 'Emergency Fund',
          category: 'Savings',
        );

  @override
  ConsumerState<EmergencyFundScreen> createState() => _EmergencyFundScreenState();
}

class _EmergencyFundScreenState extends CalculatorBaseState<EmergencyFundScreen> {
  final _monthlyExpenseController = TextEditingController();
  final _existingSavingsController = TextEditingController();
  int _months = 6;
  EmergencyFundResult? _result;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _monthlyExpenseController.dispose();
    _existingSavingsController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Monthly Expenses': NumberFormatter.formatCurrency(_monthlyExpense, symbol: _symbol),
        'Months of Coverage': '$_months months',
        'Existing Savings': NumberFormatter.formatCurrency(_existingSavings, symbol: _symbol),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Target Emergency Fund': NumberFormatter.formatCurrency(_result!.targetAmount, symbol: _symbol),
          'Current Shortfall': NumberFormatter.formatCurrency(_result!.shortfall, symbol: _symbol),
          'Time to Build': _buildTimeLabel(_result!.monthsToAchieve),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Emergency fund target: ${NumberFormatter.formatCurrency(_result!.targetAmount, symbol: _symbol)} '
          '($_months months). '
          '${_result!.shortfall <= 0 ? "Fund is ADEQUATE." : "Shortfall: ${NumberFormatter.formatCurrency(_result!.shortfall, symbol: _symbol)}"}';

  String get _symbol => ref.read(currencySymbolProvider);
  double get _monthlyExpense => NumberFormatter.tryParse(_monthlyExpenseController.text) ?? 0;
  double get _existingSavings => NumberFormatter.tryParse(_existingSavingsController.text) ?? 0;

  bool get _isAdequate => _result != null && _result!.shortfall <= 0;

  String _buildTimeLabel(double months) {
    if (months <= 0) return 'Already achieved';
    if (months.isInfinite) return 'N/A';
    if (months < 1) return 'Less than a month';
    final int yrs = months ~/ 12;
    final int mo = months.toInt() % 12;
    if (yrs == 0) return '~$mo ${mo == 1 ? "month" : "months"}';
    if (mo == 0) return '~$yrs ${yrs == 1 ? "year" : "years"}';
    return '~$yrs yr${yrs > 1 ? "s" : ""} $mo mo';
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final expense = _monthlyExpense;
    if (expense <= 0) return;

    setState(() {
      _result = SavingsCalculators.calculateEmergencyFund(
        monthlyExpense: expense,
        months: _months,
        existingSavings: _existingSavings,
      );
    });
  }

  void _reset() {
    setState(() {
      _monthlyExpenseController.clear();
      _existingSavingsController.clear();
      _months = 6;
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
            // Intro Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.savings.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.savings.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.health_and_safety_rounded,
                      color: AppColors.savings, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Financial experts recommend 3–6 months of expenses as your emergency fund.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Expense Details'),
                  AppTextField(
                    label: 'Monthly Expenses',
                    hint: '40,000',
                    controller: _monthlyExpenseController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Months of Coverage',
                    value: _months.toDouble(),
                    min: 3,
                    max: 12,
                    divisions: 9,
                    displayValue: (v) => '${v.toInt()} months',
                    onChanged: (v) => setState(() {
                      _months = v.toInt();
                      _result = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Quick-select chips
                  Row(
                    children: [3, 6, 9, 12].map((m) {
                      final bool selected = _months == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _months = m;
                            _result = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.savings.withValues(alpha: 0.15)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.savings
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              '$m mo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.savings
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Existing Emergency Savings',
                    hint: '0',
                    controller: _existingSavingsController,
                    prefix: symbol,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    final double savingRate = _monthlyExpense * 0.20;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Emergency Fund Analysis'),
          // Status Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isAdequate
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAdequate
                    ? AppColors.success.withValues(alpha: 0.35)
                    : AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isAdequate
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isAdequate ? 'ADEQUATE' : 'NEEDS ATTENTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _isAdequate ? AppColors.success : AppColors.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isAdequate
                        ? 'Your emergency fund covers $_months months of expenses. Great work!'
                        : 'You need ${NumberFormatter.formatCurrency(r.shortfall, symbol: symbol)} more to reach your target.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isAdequate
                          ? AppColors.textSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                const Text(
                  'Target Emergency Fund',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.targetAmount,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.savings,
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
                  label: 'Existing Savings',
                  value: NumberFormatter.formatCurrency(_existingSavings, symbol: symbol),
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Shortfall',
                  value: _isAdequate
                      ? 'None'
                      : NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
                  valueColor: _isAdequate ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_isAdequate) ...[
            ResultCard(
              label: 'Estimated Time to Build Fund',
              value: _buildTimeLabel(r.monthsToAchieve),
              isHighlighted: true,
              subtitle:
                  'Saving 20% of expenses (${NumberFormatter.formatCurrency(savingRate, symbol: symbol)}/mo)',
            ),
            const SizedBox(height: 12),
          ],
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Monthly Expenses',
                value: NumberFormatter.formatCurrency(_monthlyExpense, symbol: symbol),
              ),
              ResultItem(
                label: 'Coverage Period',
                value: '$_months months',
              ),
              ResultItem(
                label: 'Target Fund',
                value: NumberFormatter.formatCurrency(r.targetAmount, symbol: symbol),
              ),
              ResultItem(
                label: 'Current Savings',
                value: NumberFormatter.formatCurrency(_existingSavings, symbol: symbol),
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Shortfall',
                value: _isAdequate
                    ? 'None'
                    : NumberFormatter.formatCurrency(r.shortfall, symbol: symbol),
                color: _isAdequate ? AppColors.success : AppColors.error,
              ),
              if (!_isAdequate)
                ResultItem(
                  label: 'Time to Build (saving 20%)',
                  value: _buildTimeLabel(r.monthsToAchieve),
                  isHighlighted: true,
                ),
              if (_isAdequate)
                const ResultItem(
                  label: 'Status',
                  value: 'Fully Funded',
                  isHighlighted: true,
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

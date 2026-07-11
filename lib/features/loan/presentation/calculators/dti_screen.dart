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
import '../../domain/loan_calculators.dart';

class DtiScreen extends CalculatorBaseScreen {
  const DtiScreen({super.key})
      : super(
          calculatorId: 'dti',
          calculatorName: 'Debt-to-Income Ratio',
          category: 'Loan',
        );

  @override
  ConsumerState<DtiScreen> createState() => _DtiScreenState();
}

class _DtiScreenState extends CalculatorBaseState<DtiScreen> {
  final _incomeController = TextEditingController();
  final _rentController = TextEditingController();
  final _autoController = TextEditingController();
  final _studentController = TextEditingController();
  final _creditCardController = TextEditingController();
  final _otherController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DtiResult? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    _rentController.dispose();
    _autoController.dispose();
    _studentController.dispose();
    _creditCardController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  double get _incomeValue =>
      NumberFormatter.tryParse(_incomeController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs {
    final symbol = ref.read(currencySymbolProvider);
    final debts = _allDebts();
    return {
      'Monthly Income':
          NumberFormatter.formatCurrency(_incomeValue, symbol: symbol),
      'Rent/Mortgage':
          NumberFormatter.formatCurrency(debts[0], symbol: symbol),
      'Auto Loan':
          NumberFormatter.formatCurrency(debts[1], symbol: symbol),
      'Student Loan':
          NumberFormatter.formatCurrency(debts[2], symbol: symbol),
      'Credit Cards':
          NumberFormatter.formatCurrency(debts[3], symbol: symbol),
      'Other Loans':
          NumberFormatter.formatCurrency(debts[4], symbol: symbol),
    };
  }

  @override
  Map<String, dynamic> get currentResults {
    if (_result == null) return {};
    final symbol = ref.read(currencySymbolProvider);
    return {
      'DTI Ratio': NumberFormatter.formatPercent(_result!.dtiRatio, decimals: 1),
      'Status': _result!.status,
      'Total Monthly Debt':
          NumberFormatter.formatCurrency(_result!.totalMonthlyDebt, symbol: symbol),
      'Monthly Income':
          NumberFormatter.formatCurrency(_result!.grossMonthlyIncome, symbol: symbol),
      'Available for Debt':
          NumberFormatter.formatCurrency(_result!.availableForDebt, symbol: symbol),
    };
  }

  @override
  String get resultSummary {
    if (_result == null) return '';
    final symbol = ref.read(currencySymbolProvider);
    return 'DTI: ${NumberFormatter.formatPercent(_result!.dtiRatio, decimals: 1)} - ${_result!.status} | '
        'Total Debt: ${NumberFormatter.formatCurrency(_result!.totalMonthlyDebt, symbol: symbol)}';
  }

  List<double> _allDebts() {
    return [
      NumberFormatter.tryParse(_rentController.text) ?? 0,
      NumberFormatter.tryParse(_autoController.text) ?? 0,
      NumberFormatter.tryParse(_studentController.text) ?? 0,
      NumberFormatter.tryParse(_creditCardController.text) ?? 0,
      NumberFormatter.tryParse(_otherController.text) ?? 0,
    ];
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final income = _incomeValue;
    if (income <= 0) return;

    setState(() {
      _result = LoanCalculators.calculateDti(
        monthlyIncome: income,
        monthlyDebts: _allDebts(),
      );
    });
  }

  void _reset() {
    setState(() {
      _incomeController.clear();
      _rentController.clear();
      _autoController.clear();
      _studentController.clear();
      _creditCardController.clear();
      _otherController.clear();
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
                  buildSectionTitle('Income'),
                  AppTextField(
                    label: 'Gross Monthly Income',
                    hint: '60000',
                    controller: _incomeController,
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Monthly Debt Payments'),
                  _debtField(
                    label: 'Rent / Mortgage',
                    controller: _rentController,
                    symbol: symbol,
                  ),
                  const SizedBox(height: 16),
                  _debtField(
                    label: 'Auto Loan',
                    controller: _autoController,
                    symbol: symbol,
                  ),
                  const SizedBox(height: 16),
                  _debtField(
                    label: 'Student Loan',
                    controller: _studentController,
                    symbol: symbol,
                  ),
                  const SizedBox(height: 16),
                  _debtField(
                    label: 'Credit Card Payments',
                    controller: _creditCardController,
                    symbol: symbol,
                  ),
                  const SizedBox(height: 16),
                  _debtField(
                    label: 'Other Loans',
                    controller: _otherController,
                    symbol: symbol,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Calculate DTI',
                          icon: Icons.analytics_rounded,
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

  Widget _debtField({
    required String label,
    required TextEditingController controller,
    required String symbol,
  }) {
    return AppTextField(
      label: label,
      hint: '0',
      controller: controller,
      prefix: symbol,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) {
        if (_result != null) setState(() => _result = null);
      },
    );
  }

  Widget _buildResultSection(String symbol) {
    final r = _result!;

    final Color statusColor;
    final IconData statusIcon;
    switch (r.status) {
      case 'Healthy':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Moderate':
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
    }

    final dtiPercent = r.dtiRatio.clamp(0.0, 100.0);

    return Column(
      children: [
        // DTI Gauge
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('DTI Ratio'),
              const SizedBox(height: 8),
              _buildDtiGauge(dtiPercent),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    AnimatedResultValue(
                      value: r.dtiRatio,
                      formatter: (v) =>
                          NumberFormatter.formatPercent(v, decimals: 1),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            r.status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Breakdown'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Total Monthly Debt',
                      value: NumberFormatter.formatCurrency(
                          r.totalMonthlyDebt, symbol: symbol),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultCard(
                      label: 'Monthly Income',
                      value: NumberFormatter.formatCurrency(
                          r.grossMonthlyIncome, symbol: symbol),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ResultCard(
                label: 'Available for New Debt',
                value: NumberFormatter.formatCurrency(
                    r.availableForDebt, symbol: symbol),
                isHighlighted: r.availableForDebt > 0,
                valueColor: r.availableForDebt > 0
                    ? AppColors.success
                    : AppColors.error,
                subtitle: 'Based on 43% max DTI threshold',
              ),
              const SizedBox(height: 12),
              _buildDtiLegend(),
              const SizedBox(height: 12),
              ResultSummaryCard(
                title: 'Summary',
                items: [
                  ResultItem(
                    label: 'Monthly Income',
                    value: NumberFormatter.formatCurrency(
                        r.grossMonthlyIncome, symbol: symbol),
                  ),
                  ResultItem(
                    label: 'Total Monthly Debt',
                    value: NumberFormatter.formatCurrency(
                        r.totalMonthlyDebt, symbol: symbol),
                    color: AppColors.error,
                  ),
                  ResultItem(
                    label: 'DTI Ratio',
                    value: NumberFormatter.formatPercent(
                        r.dtiRatio, decimals: 1),
                    isHighlighted: true,
                    color: statusColor,
                  ),
                  ResultItem(
                    label: 'Status',
                    value: r.status,
                    isHighlighted: true,
                    color: statusColor,
                  ),
                  ResultItem(
                    label: 'Available for New Debt',
                    value: NumberFormatter.formatCurrency(
                        r.availableForDebt, symbol: symbol),
                    isHighlighted: r.availableForDebt > 0,
                    color: r.availableForDebt > 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDtiGauge(double dtiPercent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 24,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 36,
                      child: Container(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    Expanded(
                      flex: 7,
                      child: Container(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    Expanded(
                      flex: 57,
                      child: Container(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
                // Marker for current DTI
                Positioned(
                  left: (dtiPercent / 100) *
                      MediaQuery.of(context).size.width *
                      0.85,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: dtiPercent < 36
                          ? AppColors.success
                          : dtiPercent <= 43
                              ? AppColors.warning
                              : AppColors.error,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: dtiPercent < 36
                              ? AppColors.success.withValues(alpha: 0.6)
                              : dtiPercent <= 43
                                  ? AppColors.warning.withValues(alpha: 0.6)
                                  : AppColors.error.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: dtiPercent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: dtiPercent < 36
                            ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                            : dtiPercent <= 43
                                ? [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)]
                                : [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDtiLegend() {
    return Row(
      children: [
        _legendDot(AppColors.success, 'Healthy (<36%)'),
        const SizedBox(width: 16),
        _legendDot(AppColors.warning, 'Moderate (36-43%)'),
        const SizedBox(width: 16),
        _legendDot(AppColors.error, 'Risky (>43%)'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

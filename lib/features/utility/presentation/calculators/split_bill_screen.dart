import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../domain/utility_calculators.dart';

class SplitBillScreen extends CalculatorBaseScreen {
  const SplitBillScreen({super.key})
      : super(
          calculatorId: 'split_bill',
          calculatorName: 'Split Bill',
          category: 'Utility',
        );

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends CalculatorBaseState<SplitBillScreen> {
  final _billController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SplitBillResult? _result;

  double _tipPercent = 10;
  double _taxPercent = 8;
  int _peopleCount = 2;

  @override
  void dispose() {
    _billController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Bill Amount': _billController.text,
        'Tip %': _tipPercent.toStringAsFixed(0),
        'Tax %': _taxPercent.toStringAsFixed(0),
        'People': _peopleCount.toString(),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Grand Total': NumberFormatter.formatCurrency(_result!.grandTotal),
          'Per Person': NumberFormatter.formatCurrency(_result!.perPersonAmount),
          'Tip': NumberFormatter.formatCurrency(_result!.tipAmount),
          'Tax': NumberFormatter.formatCurrency(_result!.taxAmount),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Total: ${NumberFormatter.formatCurrency(_result!.grandTotal)}, Per Person: ${NumberFormatter.formatCurrency(_result!.perPersonAmount)}';

  double get _billAmount =>
      NumberFormatter.tryParse(_billController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = UtilityCalculators.calculateSplitBill(
        billAmount: _billAmount,
        tipPercent: _tipPercent,
        taxPercent: _taxPercent,
        peopleCount: _peopleCount,
      );
    });
  }

  void _reset() {
    setState(() {
      _billController.clear();
      _tipPercent = 10;
      _taxPercent = 8;
      _peopleCount = 2;
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
                  buildSectionTitle('Bill Details'),
                  AppTextField(
                    label: 'Bill Amount',
                    hint: '2000',
                    controller: _billController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                    prefix: '₹',
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Tip Percentage',
                    value: _tipPercent,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    displayValue: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) {
                      setState(() {
                        _tipPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Tax Percentage',
                    value: _taxPercent,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    displayValue: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) {
                      setState(() {
                        _taxPercent = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Number of People',
                    value: _peopleCount.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    displayValue: (v) => '${v.toStringAsFixed(0)} ${v == 1 ? 'person' : 'people'}',
                    onChanged: (v) {
                      setState(() {
                        _peopleCount = v.round();
                        _result = null;
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
                          color: AppColors.utility,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Reset',
                        isOutlined: true,
                        onPressed: _reset,
                        color: AppColors.utility,
                      ),
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

  Widget _buildResultSection() {
    final r = _result!;

    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              buildSectionTitle('Grand Total'),
              const SizedBox(height: 8),
              AnimatedResultValue(
                value: r.grandTotal,
                formatter: (v) => NumberFormatter.formatCurrency(v),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.utility,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ResultCard(
                      label: 'Tip',
                      value: NumberFormatter.formatCurrency(r.tipAmount),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResultCard(
                      label: 'Tax',
                      value: NumberFormatter.formatCurrency(r.taxAmount),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_peopleCount > 1) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                buildSectionTitle('Per Person'),
                const SizedBox(height: 8),
                AnimatedResultValue(
                  value: r.perPersonAmount,
                  formatter: (v) => NumberFormatter.formatCurrency(v),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.utility,
                  ),
                ),
                const SizedBox(height: 12),
                ...r.shares.map((share) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            share.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            NumberFormatter.formatCurrency(share.amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        ResultSummaryCard(
          title: 'Split Summary',
          onCopy: copyResult,
          items: [
            ResultItem(label: 'Bill Amount', value: NumberFormatter.formatCurrency(r.totalAmount)),
            ResultItem(label: 'Tip (${_tipPercent.toStringAsFixed(0)}%)', value: NumberFormatter.formatCurrency(r.tipAmount)),
            ResultItem(label: 'Tax (${_taxPercent.toStringAsFixed(0)}%)', value: NumberFormatter.formatCurrency(r.taxAmount)),
            ResultItem(
              label: 'Grand Total',
              value: NumberFormatter.formatCurrency(r.grandTotal),
              isHighlighted: true,
              color: AppColors.utility,
            ),
            if (_peopleCount > 1)
              ResultItem(
                label: 'Per Person ($_peopleCount)',
                value: NumberFormatter.formatCurrency(r.perPersonAmount),
                color: AppColors.utility,
              ),
          ],
        ),
      ],
    );
  }
}

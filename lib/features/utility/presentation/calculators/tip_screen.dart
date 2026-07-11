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

class TipScreen extends CalculatorBaseScreen {
  const TipScreen({super.key})
      : super(
          calculatorId: 'tip',
          calculatorName: 'Tip Calculator',
          category: 'Utility',
        );

  @override
  ConsumerState<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends CalculatorBaseState<TipScreen> {
  final _billController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  TipResult? _result;

  static const _presetTips = [10.0, 15.0, 18.0, 20.0];
  double _tipPercent = 15;
  int _splitCount = 1;
  bool _customTip = false;

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
        'Split Count': _splitCount.toString(),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Tip Amount': NumberFormatter.formatCurrency(_result!.tipAmount),
          'Total Amount': NumberFormatter.formatCurrency(_result!.totalAmount),
          'Per Person': NumberFormatter.formatCurrency(_result!.perPersonAmount),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Tip: ${NumberFormatter.formatCurrency(_result!.tipAmount)}, Total: ${NumberFormatter.formatCurrency(_result!.totalAmount)}';

  double get _billAmount =>
      NumberFormatter.tryParse(_billController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = UtilityCalculators.calculateTip(
        billAmount: _billAmount,
        tipPercent: _tipPercent,
        splitCount: _splitCount,
      );
    });
  }

  void _reset() {
    setState(() {
      _billController.clear();
      _tipPercent = 15;
      _splitCount = 1;
      _customTip = false;
      _result = null;
    });
  }

  void _selectTip(double percent) {
    setState(() {
      _tipPercent = percent;
      _customTip = false;
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
                    hint: '1000',
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
                  const SizedBox(height: 20),
                  buildSectionTitle('Tip Percentage'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._presetTips.map((p) {
                        final selected = !_customTip && _tipPercent == p;
                        return ActionChip(
                          label: Text(
                            '${p.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.black : AppColors.utility,
                            ),
                          ),
                          backgroundColor: selected
                              ? AppColors.utility
                              : AppColors.surface,
                          side: BorderSide(
                            color: selected
                                ? AppColors.utility
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onPressed: () => _selectTip(p),
                        );
                      }),
                      ActionChip(
                      label: Text(
                        'Custom',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _customTip ? Colors.black : AppColors.utility,
                        ),
                      ),
                      backgroundColor: _customTip
                          ? AppColors.utility
                          : AppColors.surface,
                      side: BorderSide(
                        color: _customTip
                            ? AppColors.utility
                            : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onPressed: () {
                        setState(() {
                          _customTip = true;
                          _tipPercent = 12;
                          _result = null;
                        });
                      },
                    ),
                    ],
                  ),
                  if (_customTip) ...[
                    const SizedBox(height: 12),
                    AppSliderField(
                      label: 'Custom Tip',
                      value: _tipPercent,
                      min: 0,
                      max: 100,
                      divisions: 50,
                      displayValue: (v) => '${v.toStringAsFixed(0)}%',
                      onChanged: (v) {
                        setState(() {
                          _tipPercent = v;
                          _result = null;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppSliderField(
                    label: 'Split Count',
                    value: _splitCount.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    displayValue: (v) => '${v.toStringAsFixed(0)} ${v == 1 ? 'person' : 'people'}',
                    onChanged: (v) {
                      setState(() {
                        _splitCount = v.round();
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
              buildSectionTitle('Tip Amount'),
              const SizedBox(height: 8),
              AnimatedResultValue(
                value: r.tipAmount,
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
                      label: 'Total Bill',
                      value: NumberFormatter.formatCurrency(r.totalAmount),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResultCard(
                      label: 'Tip %',
                      value: '${r.tipPercent.toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_splitCount > 1) ...[
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
                const SizedBox(height: 4),
                Text(
                  'Split $_splitCount ways',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        ResultSummaryCard(
          title: 'Summary',
          onCopy: copyResult,
          items: [
            ResultItem(label: 'Bill Amount', value: NumberFormatter.formatCurrency(r.billAmount)),
            ResultItem(label: 'Tip (${r.tipPercent.toStringAsFixed(0)}%)', value: NumberFormatter.formatCurrency(r.tipAmount)),
            ResultItem(
              label: 'Total Amount',
              value: NumberFormatter.formatCurrency(r.totalAmount),
              isHighlighted: true,
              color: AppColors.utility,
            ),
            if (_splitCount > 1)
              ResultItem(
                label: 'Per Person ($_splitCount)',
                value: NumberFormatter.formatCurrency(r.perPersonAmount),
                color: AppColors.utility,
              ),
          ],
        ),
      ],
    );
  }
}

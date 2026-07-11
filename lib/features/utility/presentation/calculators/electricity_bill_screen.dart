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

class ElectricityBillScreen extends CalculatorBaseScreen {
  const ElectricityBillScreen({super.key})
      : super(
          calculatorId: 'electricity_bill',
          calculatorName: 'Electricity Bill',
          category: 'Utility',
        );

  @override
  ConsumerState<ElectricityBillScreen> createState() =>
      _ElectricityBillScreenState();
}

class _ElectricityBillScreenState
    extends CalculatorBaseState<ElectricityBillScreen> {
  final _fixedChargesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ElectricityResult? _result;

  double _unitsConsumed = 300;
  List<ElectricitySlab> _slabs = UtilityCalculators.defaultSlabs;

  @override
  void dispose() {
    _fixedChargesController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Units Consumed': _unitsConsumed.toStringAsFixed(0),
        'Fixed Charges': _fixedChargesController.text,
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Total Bill': NumberFormatter.formatCurrency(_result!.totalBill),
          'Units Consumed': _result!.unitsConsumed.toStringAsFixed(0),
          'Avg Rate/Unit': NumberFormatter.formatCurrency(_result!.averageRatePerUnit),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Bill: ${NumberFormatter.formatCurrency(_result!.totalBill)} for ${_result!.unitsConsumed.toStringAsFixed(0)} units';

  double get _fixedCharges =>
      NumberFormatter.tryParse(_fixedChargesController.text) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _result = UtilityCalculators.calculateElectricityBill(
        unitsConsumed: _unitsConsumed.round(),
        slabs: _slabs,
        fixedCharges: _fixedCharges,
      );
    });
  }

  void _reset() {
    setState(() {
      _fixedChargesController.clear();
      _unitsConsumed = 300;
      _slabs = UtilityCalculators.defaultSlabs;
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
                  buildSectionTitle('Usage Details'),
                  AppSliderField(
                    label: 'Units Consumed',
                    value: _unitsConsumed,
                    min: 0,
                    max: 2000,
                    divisions: 200,
                    displayValue: (v) => '${v.toStringAsFixed(0)} units',
                    onChanged: (v) {
                      setState(() {
                        _unitsConsumed = v;
                        _result = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Fixed Charges',
                    hint: '50',
                    controller: _fixedChargesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val < 0) return 'Enter valid charges';
                      return null;
                    },
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                    prefix: '₹',
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
              buildSectionTitle('Total Bill'),
              const SizedBox(height: 8),
              AnimatedResultValue(
                value: r.totalBill,
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
                      label: 'Units Consumed',
                      value: '${r.unitsConsumed.toStringAsFixed(0)} units',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResultCard(
                      label: 'Avg Rate/Unit',
                      value: NumberFormatter.formatCurrency(r.averageRatePerUnit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('Slab Breakdown'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    ...r.slabDetails.asMap().entries.map(
                          (entry) => _buildTableRow(
                            entry.value,
                            isLast: entry.key == r.slabDetails.length - 1,
                          ),
                        ),
                    _buildTotalRow(r),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResultSummaryCard(
          title: 'Bill Summary',
          onCopy: copyResult,
          items: [
            ResultItem(label: 'Units Consumed', value: r.unitsConsumed.toStringAsFixed(0)),
            ...r.slabDetails.map(
              (s) => ResultItem(
                label: 'Slab ${s.slab} (@₹${s.rate.toStringAsFixed(1)})',
                value: NumberFormatter.formatCurrency(s.amount),
              ),
            ),
            ResultItem(
              label: 'Fixed Charges',
              value: NumberFormatter.formatCurrency(r.fixedCharges),
            ),
            ResultItem(
              label: 'Total Bill',
              value: NumberFormatter.formatCurrency(r.totalBill),
              isHighlighted: true,
              color: AppColors.utility,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _tableCell('Slab', flex: 2),
          _tableCell('Units', flex: 2),
          _tableCell('Rate', flex: 1),
          _tableCell('Amount', flex: 2, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildTableRow(SlabDetail detail, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: isLast
          ? const BoxDecoration()
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
      child: Row(
        children: [
          _tableCell(detail.slab, flex: 2),
          _tableCell(detail.units.toStringAsFixed(0), flex: 2),
          _tableCell('₹${detail.rate.toStringAsFixed(1)}', flex: 1),
          _tableCell(
            NumberFormatter.formatCurrency(detail.amount),
            flex: 2,
            align: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(ElectricityResult r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.utility.withValues(alpha: 0.08),
        border: Border(top: BorderSide(color: AppColors.utility.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          _tableCell('Total', flex: 2, bold: true),
          _tableCell(r.unitsConsumed.toStringAsFixed(0), flex: 2, bold: true),
          _tableCell('', flex: 1),
          _tableCell(
            NumberFormatter.formatCurrency(r.totalBill),
            flex: 2,
            align: TextAlign.right,
            bold: true,
            color: AppColors.utility,
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text,
      {int flex = 1, TextAlign align = TextAlign.start, bool bold = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}

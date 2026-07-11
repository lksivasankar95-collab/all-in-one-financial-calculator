import 'package:fl_chart/fl_chart.dart';
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

class StampDutyScreen extends CalculatorBaseScreen {
  const StampDutyScreen({super.key})
      : super(
          calculatorId: 'stamp_duty',
          calculatorName: 'Stamp Duty Calculator',
          category: 'Real Estate',
        );

  @override
  ConsumerState<StampDutyScreen> createState() => _StampDutyScreenState();
}

class _StampDutyScreenState extends CalculatorBaseState<StampDutyScreen> {
  final _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _stampDutyRate = 6.0;
  double _registrationRate = 2.0;
  StampDutyResult? _result;
  int _touchedIndex = -1;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _result != null;

  String get _symbol => ref.read(currencySymbolProvider);
  double get _propertyValue => NumberFormatter.tryParse(_valueController.text) ?? 0;

  @override
  Map<String, dynamic> get currentInputs => {
        'Property Value': NumberFormatter.formatCurrency(_propertyValue, symbol: _symbol),
        'Stamp Duty Rate': NumberFormatter.formatPercent(_stampDutyRate),
        'Registration Rate': NumberFormatter.formatPercent(_registrationRate),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null ? {} : {
        'Stamp Duty': NumberFormatter.formatCurrency(_result!.stampDuty, symbol: _symbol),
        'Registration': NumberFormatter.formatCurrency(_result!.registration, symbol: _symbol),
        'Total Cost': NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol),
      };

  @override
  String get resultSummary => _result == null ? ''
      : 'Stamp Duty: ${NumberFormatter.formatCurrency(_result!.stampDuty, symbol: _symbol)} | '
          'Total: ${NumberFormatter.formatCurrency(_result!.totalCost, symbol: _symbol)}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_propertyValue <= 0) return;

    setState(() {
      _result = RealEstateCalculators.calculateStampDuty(
        propertyValue: _propertyValue,
        stampDutyRate: _stampDutyRate,
        registrationRate: _registrationRate,
      );
    });
  }

  void _reset() {
    setState(() {
      _valueController.clear();
      _stampDutyRate = 6.0;
      _registrationRate = 2.0;
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
                    label: 'Property Value / Agreement Value',
                    hint: '5000000', controller: _valueController, prefix: symbol,
                    validator: (v) { if (v == null || v.isEmpty) return 'Required'; if ((NumberFormatter.tryParse(v) ?? 0) <= 0) return 'Invalid'; return null; },
                    onChanged: (_) { if (_result != null) setState(() => _result = null); },
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Stamp Duty Rate', value: _stampDutyRate,
                    min: 3, max: 10, divisions: 70,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _stampDutyRate = v; _result = null; }),
                  ),
                  const SizedBox(height: 20),
                  AppSliderField(
                    label: 'Registration Rate', value: _registrationRate,
                    min: 1, max: 5, divisions: 40,
                    displayValue: (v) => '${v.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _registrationRate = v; _result = null; }),
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
              const SizedBox(height: 16),
              _buildPieChart(),
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
          buildSectionTitle('Cost Breakdown'),
          Center(
            child: Column(
              children: [
                const Text('Total Additional Cost', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                const SizedBox(height: 6),
                AnimatedResultValue(
                  value: r.totalCost,
                  formatter: (v) => NumberFormatter.formatCurrency(v, symbol: symbol),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.realEstate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ResultCard(label: 'Stamp Duty',
                    value: NumberFormatter.formatCurrency(r.stampDuty, symbol: symbol)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(label: 'Registration',
                    value: NumberFormatter.formatCurrency(r.registration, symbol: symbol),
                    valueColor: AppColors.realEstate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Total Property Cost (Incl. Duties)',
            value: NumberFormatter.formatCurrency(_propertyValue + r.totalCost, symbol: symbol),
            isHighlighted: true,
            subtitle: 'Property: ${NumberFormatter.formatCurrency(_propertyValue, symbol: symbol)} + Fees',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Fee Breakdown',
            items: [
              ResultItem(label: 'Property Value', value: NumberFormatter.formatCurrency(_propertyValue, symbol: symbol)),
              ResultItem(label: 'Stamp Duty (${_stampDutyRate.toStringAsFixed(1)}%)', value: NumberFormatter.formatCurrency(r.stampDuty, symbol: symbol)),
              ResultItem(label: 'Registration (${_registrationRate.toStringAsFixed(1)}%)', value: NumberFormatter.formatCurrency(r.registration, symbol: symbol)),
              ResultItem(label: 'Total Fees', value: NumberFormatter.formatCurrency(r.totalCost, symbol: symbol), isHighlighted: true, color: AppColors.realEstate),
              ResultItem(label: 'Grand Total', value: NumberFormatter.formatCurrency(_propertyValue + r.totalCost, symbol: symbol), isHighlighted: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final r = _result!;
    final total = _propertyValue + r.totalCost;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Cost Distribution'),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(PieChartData(
                    sectionsSpace: 3, centerSpaceRadius: 52,
                    pieTouchData: PieTouchData(touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                          _touchedIndex = -1; return;
                        }
                        _touchedIndex = response.touchedSection!.touchedSectionIndex;
                      });
                    }),
                    sections: [
                      PieChartSectionData(value: _propertyValue, color: AppColors.realEstate,
                        title: _touchedIndex == 0 ? 'Property' : '',
                        radius: _touchedIndex == 0 ? 60 : 52,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      PieChartSectionData(value: r.stampDuty, color: AppColors.warning,
                        title: _touchedIndex == 1 ? 'Stamp Duty' : '',
                        radius: _touchedIndex == 1 ? 60 : 52,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      PieChartSectionData(value: r.registration, color: AppColors.info,
                        title: _touchedIndex == 2 ? 'Registration' : '',
                        radius: _touchedIndex == 2 ? 60 : 52,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  )),
                ),
                const SizedBox(width: 16),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _PieLegend(color: AppColors.realEstate, label: 'Property',
                      value: '${(_propertyValue / total * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 10),
                  _PieLegend(color: AppColors.warning, label: 'Stamp Duty',
                      value: '${(r.stampDuty / total * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 10),
                  _PieLegend(color: AppColors.info, label: 'Registration',
                      value: '${(r.registration / total * 100).toStringAsFixed(1)}%'),
                ]),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _PieLegend({required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
    ]);
  }
}

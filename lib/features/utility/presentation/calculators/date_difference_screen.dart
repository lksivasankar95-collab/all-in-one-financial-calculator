import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../domain/utility_calculators.dart';

class DateDifferenceScreen extends CalculatorBaseScreen {
  const DateDifferenceScreen({super.key})
      : super(
          calculatorId: 'date_difference',
          calculatorName: 'Date Difference',
          category: 'Utility',
        );

  @override
  ConsumerState<DateDifferenceScreen> createState() =>
      _DateDifferenceScreenState();
}

class _DateDifferenceScreenState
    extends CalculatorBaseState<DateDifferenceScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  DateDiffResult? _result;

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Start Date': NumberFormatter.formatDate(_startDate),
        'End Date': NumberFormatter.formatDate(_endDate),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Total Days': '${_result!.totalDays} days',
          'Working Days': '${_result!.workingDays} days',
          'Weekends': '${_result!.weekends} days',
          'Years': '${_result!.years}',
          'Months': '${_result!.months}',
          'Days': '${_result!.days}',
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : '${NumberFormatter.formatDate(_startDate)} to ${NumberFormatter.formatDate(_endDate)}: '
          '${_result!.years > 0 ? "${_result!.years}y " : ""}'
          '${_result!.months > 0 ? "${_result!.months}m " : ""}'
          '${_result!.days}d (${_result!.totalDays} total days, '
          '${_result!.workingDays} working days)';

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _result = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _result = null;
      });
    }
  }

  Widget _datePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.utility,
          onPrimary: AppColors.background,
          surface: AppColors.card,
          onSurface: AppColors.textPrimary,
        ),
      ),
      child: child!,
    );
  }

  void _swapDates() {
    setState(() {
      final temp = _startDate;
      _startDate = _endDate;
      _endDate = temp;
      _result = null;
    });
  }

  void _calculate() {
    setState(() {
      _result = UtilityCalculators.calculateDateDiff(
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  void _reset() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildCalculatorScaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('Select Date Range'),
                _DatePickerField(
                  label: 'Start Date',
                  date: _startDate,
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: _swapDates,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.utility.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.utility.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: AppColors.utility,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _DatePickerField(
                  label: 'End Date',
                  date: _endDate,
                  onTap: _pickEndDate,
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
    );
  }

  Widget _buildResultSection() {
    final r = _result!;
    final isEndAfterStart = !_endDate.isBefore(_startDate);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Date Difference'),
          // Total days hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.utility.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.utility.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Difference',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (r.years > 0) ...[
                      _DiffUnit(value: r.years, label: 'Years'),
                      const SizedBox(width: 12),
                    ],
                    if (r.months > 0) ...[
                      _DiffUnit(value: r.months, label: 'Months'),
                      const SizedBox(width: 12),
                    ],
                    _DiffUnit(value: r.days, label: 'Days'),
                  ],
                ),
                if (!isEndAfterStart) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'End date is before start date',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.warning),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Days',
                  value: '${NumberFormatter.formatInteger(r.totalDays)} days',
                  valueColor: AppColors.utility,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Working Days',
                  value: '${NumberFormatter.formatInteger(r.workingDays)} days',
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResultCard(
            label: 'Weekends',
            value: '${NumberFormatter.formatInteger(r.weekends)} days',
            subtitle: 'Saturdays and Sundays',
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Breakdown',
            items: [
              ResultItem(
                label: 'Start Date',
                value: NumberFormatter.formatDate(_startDate),
              ),
              ResultItem(
                label: 'End Date',
                value: NumberFormatter.formatDate(_endDate),
              ),
              if (r.years > 0)
                ResultItem(
                  label: 'Years',
                  value: '${r.years}',
                ),
              if (r.months > 0)
                ResultItem(
                  label: 'Months',
                  value: '${r.months}',
                ),
              ResultItem(
                label: 'Remaining Days',
                value: '${r.days}',
              ),
              ResultItem(
                label: 'Total Days',
                value: '${NumberFormatter.formatInteger(r.totalDays)} days',
                isHighlighted: true,
                color: AppColors.utility,
              ),
              ResultItem(
                label: 'Working Days (Mon-Fri)',
                value: '${NumberFormatter.formatInteger(r.workingDays)} days',
                color: AppColors.success,
              ),
              ResultItem(
                label: 'Weekend Days (Sat-Sun)',
                value: '${NumberFormatter.formatInteger(r.weekends)} days',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 18, color: AppColors.utility),
                const SizedBox(width: 10),
                Text(
                  NumberFormatter.formatDate(date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiffUnit extends StatelessWidget {
  final int value;
  final String label;

  const _DiffUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.utility,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

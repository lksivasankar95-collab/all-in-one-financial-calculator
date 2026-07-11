import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/calculator_base_screen.dart';
import '../../../../core/widgets/result_card.dart';
import '../../domain/utility_calculators.dart';

class AgeCalculatorScreen extends CalculatorBaseScreen {
  const AgeCalculatorScreen({super.key})
      : super(
          calculatorId: 'age_calculator',
          calculatorName: 'Age Calculator',
          category: 'Utility',
        );

  @override
  ConsumerState<AgeCalculatorScreen> createState() =>
      _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState
    extends CalculatorBaseState<AgeCalculatorScreen> {
  DateTime? _dob;
  DateTime _targetDate = DateTime.now();
  AgeResult? _result;

  @override
  bool get hasResult => _result != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Date of Birth':
            _dob == null ? '-' : NumberFormatter.formatDate(_dob!),
        'Target Date': NumberFormatter.formatDate(_targetDate),
      };

  @override
  Map<String, dynamic> get currentResults => _result == null
      ? {}
      : {
          'Age': '${_result!.years} yrs ${_result!.months} mo ${_result!.days} days',
          'Total Days': NumberFormatter.formatInteger(_result!.totalDays),
          'Total Months': NumberFormatter.formatInteger(_result!.totalMonths),
        };

  @override
  String get resultSummary => _result == null
      ? ''
      : 'Age: ${_result!.years} years, ${_result!.months} months, ${_result!.days} days '
          '(${NumberFormatter.formatInteger(_result!.totalDays)} total days)';

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _result = null;
      });
    }
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
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

  void _calculate() {
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth')),
      );
      return;
    }
    if (_targetDate.isBefore(_dob!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Target date must be after Date of Birth')),
      );
      return;
    }

    setState(() {
      _result = UtilityCalculators.calculateAge(
        dob: _dob!,
        targetDate: _targetDate,
      );
    });
  }

  void _reset() {
    setState(() {
      _dob = null;
      _targetDate = DateTime.now();
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
                buildSectionTitle('Date Details'),
                _DatePickerField(
                  label: 'Date of Birth',
                  date: _dob,
                  onTap: _pickDob,
                  placeholder: 'Select Date of Birth',
                ),
                const SizedBox(height: 16),
                _DatePickerField(
                  label: 'Target Date (Default: Today)',
                  date: _targetDate,
                  onTap: _pickTargetDate,
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
    final now = DateTime.now();
    final nextBirthday = _nextBirthday(now);
    final daysToNextBirthday = nextBirthday.difference(now).inDays;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Age Result'),
          // Primary age display
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
                  'Age',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AgeUnit(value: r.years, label: 'Years'),
                    const SizedBox(width: 16),
                    _AgeUnit(value: r.months, label: 'Months'),
                    const SizedBox(width: 16),
                    _AgeUnit(value: r.days, label: 'Days'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ResultCard(
                  label: 'Total Days Lived',
                  value: NumberFormatter.formatInteger(r.totalDays),
                  valueColor: AppColors.utility,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultCard(
                  label: 'Total Months',
                  value: NumberFormatter.formatInteger(r.totalMonths),
                  valueColor: AppColors.utility,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Next birthday countdown
          if (_dob != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Birthday',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                        Text(
                          daysToNextBirthday == 0
                              ? 'Today is your birthday!'
                              : daysToNextBirthday == 1
                                  ? 'Tomorrow!'
                                  : '$daysToNextBirthday days away (${NumberFormatter.formatDate(nextBirthday)})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Summary',
            items: [
              ResultItem(
                label: 'Date of Birth',
                value: NumberFormatter.formatDate(_dob!),
              ),
              ResultItem(
                label: 'Target Date',
                value: NumberFormatter.formatDate(_targetDate),
              ),
              ResultItem(
                label: 'Age',
                value:
                    '${r.years} yrs ${r.months} mo ${r.days} days',
                isHighlighted: true,
                color: AppColors.utility,
              ),
              ResultItem(
                label: 'Total Days',
                value: NumberFormatter.formatInteger(r.totalDays),
              ),
              ResultItem(
                label: 'Total Months',
                value: NumberFormatter.formatInteger(r.totalMonths),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _nextBirthday(DateTime now) {
    if (_dob == null) return now;
    var next = DateTime(now.year, _dob!.month, _dob!.day);
    if (next.isBefore(now) ||
        (next.day == now.day &&
            next.month == now.month &&
            next.year == now.year)) {
      // If today is birthday, return today; else next year
      if (next.month == now.month && next.day == now.day) return now;
      next = DateTime(now.year + 1, _dob!.month, _dob!.day);
    }
    return next;
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String? placeholder;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
    this.placeholder,
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
                  date != null
                      ? NumberFormatter.formatDate(date!)
                      : (placeholder ?? 'Select date'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: date != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
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

class _AgeUnit extends StatelessWidget {
  final int value;
  final String label;

  const _AgeUnit({required this.value, required this.label});

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

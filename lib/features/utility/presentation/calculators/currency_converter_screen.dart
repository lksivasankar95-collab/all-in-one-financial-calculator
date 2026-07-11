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

class CurrencyConverterScreen extends CalculatorBaseScreen {
  const CurrencyConverterScreen({super.key})
      : super(
          calculatorId: 'currency_converter',
          calculatorName: 'Currency Converter',
          category: 'Utility',
        );

  @override
  ConsumerState<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState
    extends CalculatorBaseState<CurrencyConverterScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const List<_CurrencyInfo> _currencies = [
    _CurrencyInfo(name: 'USD - US Dollar', code: 'USD', rate: 1.0, flag: '\$'),
    _CurrencyInfo(name: 'INR - Indian Rupee', code: 'INR', rate: 83.0, flag: '₹'),
    _CurrencyInfo(name: 'EUR - Euro', code: 'EUR', rate: 0.92, flag: '€'),
    _CurrencyInfo(name: 'GBP - British Pound', code: 'GBP', rate: 0.79, flag: '£'),
    _CurrencyInfo(name: 'JPY - Japanese Yen', code: 'JPY', rate: 149.0, flag: '¥'),
    _CurrencyInfo(name: 'CAD - Canadian Dollar', code: 'CAD', rate: 1.36, flag: 'C\$'),
    _CurrencyInfo(name: 'AUD - Australian Dollar', code: 'AUD', rate: 1.54, flag: 'A\$'),
    _CurrencyInfo(name: 'CHF - Swiss Franc', code: 'CHF', rate: 0.88, flag: 'Fr'),
    _CurrencyInfo(name: 'CNY - Chinese Yuan', code: 'CNY', rate: 7.24, flag: '¥'),
    _CurrencyInfo(name: 'SGD - Singapore Dollar', code: 'SGD', rate: 1.34, flag: 'S\$'),
    _CurrencyInfo(name: 'HKD - Hong Kong Dollar', code: 'HKD', rate: 7.82, flag: 'HK\$'),
    _CurrencyInfo(name: 'KRW - South Korean Won', code: 'KRW', rate: 1320.0, flag: '₩'),
    _CurrencyInfo(name: 'SEK - Swedish Krona', code: 'SEK', rate: 10.42, flag: 'kr'),
    _CurrencyInfo(name: 'NOK - Norwegian Krone', code: 'NOK', rate: 10.65, flag: 'kr'),
    _CurrencyInfo(name: 'NZD - New Zealand Dollar', code: 'NZD', rate: 1.66, flag: 'NZ\$'),
    _CurrencyInfo(name: 'MXN - Mexican Peso', code: 'MXN', rate: 17.15, flag: 'MX\$'),
    _CurrencyInfo(name: 'TRY - Turkish Lira', code: 'TRY', rate: 30.50, flag: '₺'),
    _CurrencyInfo(name: 'BRL - Brazilian Real', code: 'BRL', rate: 4.97, flag: 'R\$'),
    _CurrencyInfo(name: 'ZAR - South African Rand', code: 'ZAR', rate: 18.70, flag: 'R'),
    _CurrencyInfo(name: 'AED - UAE Dirham', code: 'AED', rate: 3.67, flag: 'د.إ'),
  ];

  _CurrencyInfo _fromCurrency = _currencies[0];
  _CurrencyInfo _toCurrency = _currencies[1];
  double? _convertedAmount;
  double? _exchangeRate;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  bool get hasResult => _convertedAmount != null;

  @override
  Map<String, dynamic> get currentInputs => {
        'Amount': _amountController.text,
        'From': _fromCurrency.code,
        'To': _toCurrency.code,
        'Exchange Rate': _exchangeRate?.toStringAsFixed(4) ?? '',
      };

  @override
  Map<String, dynamic> get currentResults => _convertedAmount == null
      ? {}
      : {
          'Converted Amount': _convertedAmount!.toStringAsFixed(2),
          'Exchange Rate': _exchangeRate?.toStringAsFixed(4) ?? '',
        };

  @override
  String get resultSummary => _convertedAmount == null
      ? ''
      : '${_amountController.text} ${_fromCurrency.code} = '
          '${_convertedAmount!.toStringAsFixed(2)} ${_toCurrency.code}';

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final amount = NumberFormatter.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final double rate = _toCurrency.rate / _fromCurrency.rate;
    setState(() {
      _exchangeRate = rate;
      _convertedAmount = amount * rate;
    });
  }

  void _reset() {
    setState(() {
      _amountController.clear();
      _convertedAmount = null;
      _exchangeRate = null;
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _convertedAmount = null;
      _exchangeRate = null;
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
                  buildSectionTitle('Currency Conversion'),
                  AppTextField(
                    label: 'Amount',
                    hint: '1000',
                    controller: _amountController,
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
                      if (_convertedAmount != null) {
                        setState(() {
                          _convertedAmount = null;
                          _exchangeRate = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildCurrencyDropdown(
                    label: 'From Currency',
                    value: _fromCurrency,
                    currencies: _currencies,
                    onChanged: (c) => setState(() {
                      _fromCurrency = c;
                      _convertedAmount = null;
                      _exchangeRate = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.swap_vert_rounded,
                          color: AppColors.utility, size: 28),
                      onPressed: _swapCurrencies,
                      tooltip: 'Swap currencies',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCurrencyDropdown(
                    label: 'To Currency',
                    value: _toCurrency,
                    currencies: _currencies,
                    onChanged: (c) => setState(() {
                      _toCurrency = c;
                      _convertedAmount = null;
                      _exchangeRate = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Convert',
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
            if (_convertedAmount != null) ...[
              const SizedBox(height: 16),
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required _CurrencyInfo value,
    required List<_CurrencyInfo> currencies,
    required void Function(_CurrencyInfo) onChanged,
  }) {
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_CurrencyInfo>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.card,
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textHint, size: 20),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: currencies
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.flag} ${c.code} - ${c.name}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    final amount = NumberFormatter.tryParse(_amountController.text) ?? 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle('Conversion Result'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.utility.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.utility.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_fromCurrency.flag} ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: AppColors.utility),
                    ),
                    Text(
                      '${_toCurrency.flag} ${_convertedAmount!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.utility,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                AnimatedResultValue(
                  value: _convertedAmount!,
                  formatter: (v) =>
                      '${_toCurrency.flag} ${v.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.utility,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ResultCard(
            label: 'Exchange Rate',
            value: '1 ${_fromCurrency.code} = ${_exchangeRate!.toStringAsFixed(4)} ${_toCurrency.code}',
            isHighlighted: true,
          ),
          const SizedBox(height: 12),
          ResultSummaryCard(
            title: 'Conversion Details',
            items: [
              ResultItem(
                label: 'Amount',
                value: '${_fromCurrency.flag} ${amount.toStringAsFixed(2)}',
              ),
              ResultItem(
                label: 'From Currency',
                value: _fromCurrency.code,
              ),
              ResultItem(
                label: 'To Currency',
                value: _toCurrency.code,
              ),
              ResultItem(
                label: 'Exchange Rate',
                value: '1 ${_fromCurrency.code} = ${_exchangeRate!.toStringAsFixed(4)} ${_toCurrency.code}',
                isHighlighted: true,
              ),
              ResultItem(
                label: 'Converted Amount',
                value: '${_toCurrency.flag} ${_convertedAmount!.toStringAsFixed(2)}',
                isHighlighted: true,
                color: AppColors.utility,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyInfo {
  final String name;
  final String code;
  final double rate;
  final String flag;

  const _CurrencyInfo({
    required this.name,
    required this.code,
    required this.rate,
    required this.flag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CurrencyInfo &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

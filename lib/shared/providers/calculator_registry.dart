import 'package:flutter/material.dart';
import '../models/calculator_item.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';

class CalculatorRegistry {
  CalculatorRegistry._();

  static List<CalculatorCategory> get categories => [
    _investment,
    _loan,
    _savings,
    _tax,
    _business,
    _utility,
  ];

  static List<CalculatorItem> get allCalculators =>
      categories.expand((c) => c.calculators).toList();

  static CalculatorItem? findById(String id) {
    try {
      return allCalculators.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<CalculatorItem> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return allCalculators
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q))
        .toList();
  }

  static final CalculatorCategory _investment = CalculatorCategory(
    id: 'investment',
    name: 'Investment',
    icon: Icons.trending_up_rounded,
    color: AppColors.investment,
    calculators: [
      CalculatorItem(
        id: 'sip',
        name: 'SIP Calculator',
        description: 'Systematic Investment Plan returns',
        category: 'Investment',
        icon: Icons.auto_graph_rounded,
        color: AppColors.investment,
        route: AppRoutes.sip,
      ),
      CalculatorItem(
        id: 'swp',
        name: 'SWP Calculator',
        description: 'Systematic Withdrawal Plan',
        category: 'Investment',
        icon: Icons.savings_rounded,
        color: AppColors.investment,
        route: AppRoutes.swp,
      ),
      CalculatorItem(
        id: 'lumpsum',
        name: 'Lumpsum Calculator',
        description: 'One-time investment growth',
        category: 'Investment',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.investment,
        route: AppRoutes.lumpsum,
      ),
      CalculatorItem(
        id: 'cagr',
        name: 'CAGR Calculator',
        description: 'Compound Annual Growth Rate',
        category: 'Investment',
        icon: Icons.bar_chart_rounded,
        color: AppColors.investment,
        route: AppRoutes.cagr,
      ),
      CalculatorItem(
        id: 'roi',
        name: 'ROI Calculator',
        description: 'Return on Investment',
        category: 'Investment',
        icon: Icons.percent_rounded,
        color: AppColors.investment,
        route: AppRoutes.roi,
      ),
      CalculatorItem(
        id: 'compound_interest',
        name: 'Compound Interest',
        description: 'Interest compounded over time',
        category: 'Investment',
        icon: Icons.show_chart_rounded,
        color: AppColors.investment,
        route: AppRoutes.compoundInterest,
      ),
      CalculatorItem(
        id: 'simple_interest',
        name: 'Simple Interest',
        description: 'Basic interest calculation',
        category: 'Investment',
        icon: Icons.functions_rounded,
        color: AppColors.investment,
        route: AppRoutes.simpleInterest,
      ),
    ],
  );

  static final CalculatorCategory _loan = CalculatorCategory(
    id: 'loan',
    name: 'Loan',
    icon: Icons.account_balance_rounded,
    color: AppColors.loan,
    calculators: [
      CalculatorItem(
        id: 'emi',
        name: 'EMI Calculator',
        description: 'Equated Monthly Installment',
        category: 'Loan',
        icon: Icons.payments_rounded,
        color: AppColors.loan,
        route: AppRoutes.emi,
      ),
      CalculatorItem(
        id: 'loan_eligibility',
        name: 'Loan Eligibility',
        description: 'Check your loan eligibility',
        category: 'Loan',
        icon: Icons.verified_rounded,
        color: AppColors.loan,
        route: AppRoutes.loanEligibility,
      ),
      CalculatorItem(
        id: 'prepayment',
        name: 'Prepayment Calculator',
        description: 'Savings from loan prepayment',
        category: 'Loan',
        icon: Icons.price_check_rounded,
        color: AppColors.loan,
        route: AppRoutes.prepayment,
      ),
      CalculatorItem(
        id: 'balance_transfer',
        name: 'Balance Transfer',
        description: 'Loan balance transfer savings',
        category: 'Loan',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.loan,
        route: AppRoutes.balanceTransfer,
      ),
    ],
  );

  static final CalculatorCategory _savings = CalculatorCategory(
    id: 'savings',
    name: 'Savings',
    icon: Icons.savings_rounded,
    color: AppColors.savings,
    calculators: [
      CalculatorItem(
        id: 'fd',
        name: 'FD Calculator',
        description: 'Fixed Deposit maturity',
        category: 'Savings',
        icon: Icons.lock_rounded,
        color: AppColors.savings,
        route: AppRoutes.fd,
      ),
      CalculatorItem(
        id: 'rd',
        name: 'RD Calculator',
        description: 'Recurring Deposit returns',
        category: 'Savings',
        icon: Icons.repeat_rounded,
        color: AppColors.savings,
        route: AppRoutes.rd,
      ),
      CalculatorItem(
        id: 'ppf',
        name: 'PPF Calculator',
        description: 'Public Provident Fund',
        category: 'Savings',
        icon: Icons.account_box_rounded,
        color: AppColors.savings,
        route: AppRoutes.ppf,
      ),
      CalculatorItem(
        id: 'epf',
        name: 'EPF Calculator',
        description: 'Employee Provident Fund',
        category: 'Savings',
        icon: Icons.people_rounded,
        color: AppColors.savings,
        route: AppRoutes.epf,
      ),
      CalculatorItem(
        id: 'nps',
        name: 'NPS Calculator',
        description: 'National Pension Scheme',
        category: 'Savings',
        icon: Icons.elderly_rounded,
        color: AppColors.savings,
        route: AppRoutes.nps,
      ),
      CalculatorItem(
        id: 'retirement',
        name: 'Retirement Planner',
        description: 'Plan your retirement corpus',
        category: 'Savings',
        icon: Icons.beach_access_rounded,
        color: AppColors.savings,
        route: AppRoutes.retirement,
      ),
      CalculatorItem(
        id: 'emergency_fund',
        name: 'Emergency Fund',
        description: 'Build your safety net',
        category: 'Savings',
        icon: Icons.health_and_safety_rounded,
        color: AppColors.savings,
        route: AppRoutes.emergencyFund,
      ),
    ],
  );

  static final CalculatorCategory _tax = CalculatorCategory(
    id: 'tax',
    name: 'Tax',
    icon: Icons.receipt_long_rounded,
    color: AppColors.tax,
    calculators: [
      CalculatorItem(
        id: 'gst',
        name: 'GST Calculator',
        description: 'Goods and Services Tax',
        category: 'Tax',
        icon: Icons.receipt_rounded,
        color: AppColors.tax,
        route: AppRoutes.gst,
      ),
      CalculatorItem(
        id: 'income_tax',
        name: 'Income Tax',
        description: 'FY 2024-25 tax calculation',
        category: 'Tax',
        icon: Icons.attach_money_rounded,
        color: AppColors.tax,
        route: AppRoutes.incomeTax,
      ),
      CalculatorItem(
        id: 'hra',
        name: 'HRA Calculator',
        description: 'House Rent Allowance exemption',
        category: 'Tax',
        icon: Icons.home_rounded,
        color: AppColors.tax,
        route: AppRoutes.hra,
      ),
      CalculatorItem(
        id: 'capital_gain',
        name: 'Capital Gain Tax',
        description: 'Short & long term capital gains',
        category: 'Tax',
        icon: Icons.trending_up_rounded,
        color: AppColors.tax,
        route: AppRoutes.capitalGain,
      ),
    ],
  );

  static final CalculatorCategory _business = CalculatorCategory(
    id: 'business',
    name: 'Business',
    icon: Icons.business_center_rounded,
    color: AppColors.business,
    calculators: [
      CalculatorItem(
        id: 'profit_margin',
        name: 'Profit Margin',
        description: 'Gross and net profit margin',
        category: 'Business',
        icon: Icons.leaderboard_rounded,
        color: AppColors.business,
        route: AppRoutes.profitMargin,
      ),
      CalculatorItem(
        id: 'discount',
        name: 'Discount Calculator',
        description: 'Price after discount',
        category: 'Business',
        icon: Icons.local_offer_rounded,
        color: AppColors.business,
        route: AppRoutes.discount,
      ),
      CalculatorItem(
        id: 'commission',
        name: 'Commission Calculator',
        description: 'Sales commission calculation',
        category: 'Business',
        icon: Icons.handshake_rounded,
        color: AppColors.business,
        route: AppRoutes.commission,
      ),
      CalculatorItem(
        id: 'break_even',
        name: 'Break-Even Analysis',
        description: 'Units needed to break even',
        category: 'Business',
        icon: Icons.balance_rounded,
        color: AppColors.business,
        route: AppRoutes.breakEven,
      ),
    ],
  );

  static final CalculatorCategory _utility = CalculatorCategory(
    id: 'utility',
    name: 'Utility',
    icon: Icons.build_rounded,
    color: AppColors.utility,
    calculators: [
      CalculatorItem(
        id: 'percentage',
        name: 'Percentage Calculator',
        description: 'Percentage of a number',
        category: 'Utility',
        icon: Icons.percent_rounded,
        color: AppColors.utility,
        route: AppRoutes.percentage,
      ),
      CalculatorItem(
        id: 'inflation',
        name: 'Inflation Calculator',
        description: 'Future value with inflation',
        category: 'Utility',
        icon: Icons.price_change_rounded,
        color: AppColors.utility,
        route: AppRoutes.inflation,
      ),
      CalculatorItem(
        id: 'age_calculator',
        name: 'Age Calculator',
        description: 'Calculate exact age',
        category: 'Utility',
        icon: Icons.cake_rounded,
        color: AppColors.utility,
        route: AppRoutes.ageCalculator,
      ),
      CalculatorItem(
        id: 'date_difference',
        name: 'Date Difference',
        description: 'Days between two dates',
        category: 'Utility',
        icon: Icons.date_range_rounded,
        color: AppColors.utility,
        route: AppRoutes.dateDifference,
      ),
      CalculatorItem(
        id: 'unit_converter',
        name: 'Unit Converter',
        description: 'Convert between units',
        category: 'Utility',
        icon: Icons.swap_vert_rounded,
        color: AppColors.utility,
        route: AppRoutes.unitConverter,
      ),
    ],
  );
}

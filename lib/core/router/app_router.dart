import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
// Investment
import '../../features/investment/presentation/investment_screen.dart';
import '../../features/investment/presentation/calculators/sip_screen.dart';
import '../../features/investment/presentation/calculators/swp_screen.dart';
import '../../features/investment/presentation/calculators/lumpsum_screen.dart';
import '../../features/investment/presentation/calculators/cagr_screen.dart';
import '../../features/investment/presentation/calculators/roi_screen.dart';
import '../../features/investment/presentation/calculators/compound_interest_screen.dart';
import '../../features/investment/presentation/calculators/simple_interest_screen.dart';
import '../../features/investment/presentation/calculators/xirr_screen.dart';
import '../../features/investment/presentation/calculators/future_value_screen.dart';
import '../../features/investment/presentation/calculators/present_value_screen.dart';
import '../../features/investment/presentation/calculators/dca_screen.dart';
import '../../features/investment/presentation/calculators/rule_of_72_screen.dart';
import '../../features/investment/presentation/calculators/rule_of_114_screen.dart';
// Loan
import '../../features/loan/presentation/loan_screen.dart';
import '../../features/loan/presentation/calculators/emi_screen.dart';
import '../../features/loan/presentation/calculators/loan_eligibility_screen.dart';
import '../../features/loan/presentation/calculators/prepayment_screen.dart';
import '../../features/loan/presentation/calculators/balance_transfer_screen.dart';
import '../../features/loan/presentation/calculators/mortgage_screen.dart';
import '../../features/loan/presentation/calculators/home_loan_screen.dart';
import '../../features/loan/presentation/calculators/personal_loan_screen.dart';
import '../../features/loan/presentation/calculators/car_loan_screen.dart';
import '../../features/loan/presentation/calculators/education_loan_screen.dart';
import '../../features/loan/presentation/calculators/credit_card_emi_screen.dart';
import '../../features/loan/presentation/calculators/dti_screen.dart';
// Savings
import '../../features/savings/presentation/savings_screen.dart';
import '../../features/savings/presentation/calculators/fd_screen.dart';
import '../../features/savings/presentation/calculators/rd_screen.dart';
import '../../features/savings/presentation/calculators/ppf_screen.dart';
import '../../features/savings/presentation/calculators/epf_screen.dart';
import '../../features/savings/presentation/calculators/nps_screen.dart';
import '../../features/savings/presentation/calculators/retirement_screen.dart';
import '../../features/savings/presentation/calculators/emergency_fund_screen.dart';
import '../../features/savings/presentation/calculators/goal_savings_screen.dart';
import '../../features/savings/presentation/calculators/monthly_savings_screen.dart';
import '../../features/savings/presentation/calculators/education_savings_screen.dart';
import '../../features/savings/presentation/calculators/child_future_screen.dart';
// Tax
import '../../features/tax/presentation/tax_screen.dart';
import '../../features/tax/presentation/calculators/gst_screen.dart';
import '../../features/tax/presentation/calculators/income_tax_screen.dart';
import '../../features/tax/presentation/calculators/hra_screen.dart';
import '../../features/tax/presentation/calculators/capital_gain_screen.dart';
import '../../features/tax/presentation/calculators/tds_screen.dart';
import '../../features/tax/presentation/calculators/salary_take_home_screen.dart';
import '../../features/tax/presentation/calculators/old_vs_new_tax_screen.dart';
// Business
import '../../features/business/presentation/business_screen.dart';
import '../../features/business/presentation/calculators/profit_margin_screen.dart';
import '../../features/business/presentation/calculators/discount_screen.dart';
import '../../features/business/presentation/calculators/commission_screen.dart';
import '../../features/business/presentation/calculators/break_even_screen.dart';
import '../../features/business/presentation/calculators/profit_loss_screen.dart';
import '../../features/business/presentation/calculators/markup_screen.dart';
import '../../features/business/presentation/calculators/invoice_screen.dart';
import '../../features/business/presentation/calculators/gst_inclusive_exclusive_screen.dart';
import '../../features/business/presentation/calculators/payroll_screen.dart';
// Utility
import '../../features/utility/presentation/utility_screen.dart';
import '../../features/utility/presentation/calculators/percentage_screen.dart';
import '../../features/utility/presentation/calculators/inflation_screen.dart';
import '../../features/utility/presentation/calculators/age_calculator_screen.dart';
import '../../features/utility/presentation/calculators/date_difference_screen.dart';
import '../../features/utility/presentation/calculators/unit_converter_screen.dart';
import '../../features/utility/presentation/calculators/bmi_screen.dart';
import '../../features/utility/presentation/calculators/fuel_cost_screen.dart';
import '../../features/utility/presentation/calculators/electricity_bill_screen.dart';
import '../../features/utility/presentation/calculators/tip_screen.dart';
import '../../features/utility/presentation/calculators/split_bill_screen.dart';
import '../../features/utility/presentation/calculators/percent_change_screen.dart';

class AppRoutes {
  static const home = '/';
  static const history = '/history';
  static const favorites = '/favorites';
  static const settings = '/settings';
  // Investment
  static const investment = '/investment';
  static const sip = '/investment/sip';
  static const swp = '/investment/swp';
  static const lumpsum = '/investment/lumpsum';
  static const cagr = '/investment/cagr';
  static const roi = '/investment/roi';
  static const compoundInterest = '/investment/compound-interest';
  static const simpleInterest = '/investment/simple-interest';
  static const xirr = '/investment/xirr';
  static const futureValue = '/investment/future-value';
  static const presentValue = '/investment/present-value';
  static const dca = '/investment/dca';
  static const ruleOf72 = '/investment/rule-of-72';
  static const ruleOf114 = '/investment/rule-of-114';
  // Loan
  static const loan = '/loan';
  static const emi = '/loan/emi';
  static const loanEligibility = '/loan/eligibility';
  static const prepayment = '/loan/prepayment';
  static const balanceTransfer = '/loan/balance-transfer';
  static const mortgage = '/loan/mortgage';
  static const homeLoan = '/loan/home-loan';
  static const personalLoan = '/loan/personal-loan';
  static const carLoan = '/loan/car-loan';
  static const educationLoan = '/loan/education-loan';
  static const creditCardEmi = '/loan/credit-card-emi';
  static const dti = '/loan/dti';
  // Savings
  static const savings = '/savings';
  static const fd = '/savings/fd';
  static const rd = '/savings/rd';
  static const ppf = '/savings/ppf';
  static const epf = '/savings/epf';
  static const nps = '/savings/nps';
  static const retirement = '/savings/retirement';
  static const emergencyFund = '/savings/emergency-fund';
  static const goalSavings = '/savings/goal-savings';
  static const monthlySavings = '/savings/monthly-savings';
  static const educationSavings = '/savings/education-savings';
  static const childFuture = '/savings/child-future';
  // Tax
  static const tax = '/tax';
  static const gst = '/tax/gst';
  static const incomeTax = '/tax/income-tax';
  static const hra = '/tax/hra';
  static const capitalGain = '/tax/capital-gain';
  static const tds = '/tax/tds';
  static const salaryTakeHome = '/tax/salary-take-home';
  static const oldVsNewTax = '/tax/old-vs-new';
  // Business
  static const business = '/business';
  static const profitMargin = '/business/profit-margin';
  static const discount = '/business/discount';
  static const commission = '/business/commission';
  static const breakEven = '/business/break-even';
  static const profitLoss = '/business/profit-loss';
  static const markup = '/business/markup';
  static const invoice = '/business/invoice';
  static const gstBusiness = '/business/gst';
  static const payroll = '/business/payroll';
  // Utility
  static const utility = '/utility';
  static const percentage = '/utility/percentage';
  static const inflation = '/utility/inflation';
  static const ageCalculator = '/utility/age';
  static const dateDifference = '/utility/date-difference';
  static const unitConverter = '/utility/unit-converter';
  static const bmi = '/utility/bmi';
  static const fuelCost = '/utility/fuel-cost';
  static const electricityBill = '/utility/electricity-bill';
  static const tip = '/utility/tip';
  static const splitBill = '/utility/split-bill';
  static const percentChange = '/utility/percent-change';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.home, builder: (c, s) => const HomeScreen()),
        GoRoute(path: AppRoutes.history, builder: (c, s) => const HistoryScreen()),
        GoRoute(path: AppRoutes.favorites, builder: (c, s) => const FavoritesScreen()),
        GoRoute(path: AppRoutes.settings, builder: (c, s) => const SettingsScreen()),
      ],
    ),
    // Investment Category
    GoRoute(
      path: AppRoutes.investment,
      pageBuilder: (c, s) => _slide(const InvestmentScreen()),
      routes: [
        GoRoute(path: 'sip', pageBuilder: (c, s) => _slide(const SipScreen())),
        GoRoute(path: 'swp', pageBuilder: (c, s) => _slide(const SwpScreen())),
        GoRoute(path: 'lumpsum', pageBuilder: (c, s) => _slide(const LumpsumScreen())),
        GoRoute(path: 'cagr', pageBuilder: (c, s) => _slide(const CagrScreen())),
        GoRoute(path: 'roi', pageBuilder: (c, s) => _slide(const RoiScreen())),
        GoRoute(path: 'compound-interest', pageBuilder: (c, s) => _slide(const CompoundInterestScreen())),
        GoRoute(path: 'simple-interest', pageBuilder: (c, s) => _slide(const SimpleInterestScreen())),
        GoRoute(path: 'xirr', pageBuilder: (c, s) => _slide(const XirrScreen())),
        GoRoute(path: 'future-value', pageBuilder: (c, s) => _slide(const FutureValueScreen())),
        GoRoute(path: 'present-value', pageBuilder: (c, s) => _slide(const PresentValueScreen())),
        GoRoute(path: 'dca', pageBuilder: (c, s) => _slide(const DcaScreen())),
        GoRoute(path: 'rule-of-72', pageBuilder: (c, s) => _slide(const RuleOf72Screen())),
        GoRoute(path: 'rule-of-114', pageBuilder: (c, s) => _slide(const RuleOf114Screen())),
      ],
    ),
    // Loan Category
    GoRoute(
      path: AppRoutes.loan,
      pageBuilder: (c, s) => _slide(const LoanScreen()),
      routes: [
        GoRoute(path: 'emi', pageBuilder: (c, s) => _slide(const EmiScreen())),
        GoRoute(path: 'eligibility', pageBuilder: (c, s) => _slide(const LoanEligibilityScreen())),
        GoRoute(path: 'prepayment', pageBuilder: (c, s) => _slide(const PrepaymentScreen())),
        GoRoute(path: 'balance-transfer', pageBuilder: (c, s) => _slide(const BalanceTransferScreen())),
        GoRoute(path: 'mortgage', pageBuilder: (c, s) => _slide(const MortgageScreen())),
        GoRoute(path: 'home-loan', pageBuilder: (c, s) => _slide(const HomeLoanScreen())),
        GoRoute(path: 'personal-loan', pageBuilder: (c, s) => _slide(const PersonalLoanScreen())),
        GoRoute(path: 'car-loan', pageBuilder: (c, s) => _slide(const CarLoanScreen())),
        GoRoute(path: 'education-loan', pageBuilder: (c, s) => _slide(const EducationLoanScreen())),
        GoRoute(path: 'credit-card-emi', pageBuilder: (c, s) => _slide(const CreditCardEmiScreen())),
        GoRoute(path: 'dti', pageBuilder: (c, s) => _slide(const DtiScreen())),
      ],
    ),
    // Savings Category
    GoRoute(
      path: AppRoutes.savings,
      pageBuilder: (c, s) => _slide(const SavingsScreen()),
      routes: [
        GoRoute(path: 'fd', pageBuilder: (c, s) => _slide(const FdScreen())),
        GoRoute(path: 'rd', pageBuilder: (c, s) => _slide(const RdScreen())),
        GoRoute(path: 'ppf', pageBuilder: (c, s) => _slide(const PpfScreen())),
        GoRoute(path: 'epf', pageBuilder: (c, s) => _slide(const EpfScreen())),
        GoRoute(path: 'nps', pageBuilder: (c, s) => _slide(const NpsScreen())),
        GoRoute(path: 'retirement', pageBuilder: (c, s) => _slide(const RetirementScreen())),
        GoRoute(path: 'emergency-fund', pageBuilder: (c, s) => _slide(const EmergencyFundScreen())),
        GoRoute(path: 'goal-savings', pageBuilder: (c, s) => _slide(const GoalSavingsScreen())),
        GoRoute(path: 'monthly-savings', pageBuilder: (c, s) => _slide(const MonthlySavingsScreen())),
        GoRoute(path: 'education-savings', pageBuilder: (c, s) => _slide(const EducationSavingsScreen())),
        GoRoute(path: 'child-future', pageBuilder: (c, s) => _slide(const ChildFutureScreen())),
      ],
    ),
    // Tax Category
    GoRoute(
      path: AppRoutes.tax,
      pageBuilder: (c, s) => _slide(const TaxScreen()),
      routes: [
        GoRoute(path: 'gst', pageBuilder: (c, s) => _slide(const GstScreen())),
        GoRoute(path: 'income-tax', pageBuilder: (c, s) => _slide(const IncomeTaxScreen())),
        GoRoute(path: 'hra', pageBuilder: (c, s) => _slide(const HraScreen())),
        GoRoute(path: 'capital-gain', pageBuilder: (c, s) => _slide(const CapitalGainScreen())),
        GoRoute(path: 'tds', pageBuilder: (c, s) => _slide(const TdsScreen())),
        GoRoute(path: 'salary-take-home', pageBuilder: (c, s) => _slide(const SalaryTakeHomeScreen())),
        GoRoute(path: 'old-vs-new', pageBuilder: (c, s) => _slide(const OldVsNewTaxScreen())),
      ],
    ),
    // Business Category
    GoRoute(
      path: AppRoutes.business,
      pageBuilder: (c, s) => _slide(const BusinessScreen()),
      routes: [
        GoRoute(path: 'profit-margin', pageBuilder: (c, s) => _slide(const ProfitMarginScreen())),
        GoRoute(path: 'discount', pageBuilder: (c, s) => _slide(const DiscountScreen())),
        GoRoute(path: 'commission', pageBuilder: (c, s) => _slide(const CommissionScreen())),
        GoRoute(path: 'break-even', pageBuilder: (c, s) => _slide(const BreakEvenScreen())),
        GoRoute(path: 'profit-loss', pageBuilder: (c, s) => _slide(const ProfitLossScreen())),
        GoRoute(path: 'markup', pageBuilder: (c, s) => _slide(const MarkupScreen())),
        GoRoute(path: 'invoice', pageBuilder: (c, s) => _slide(const InvoiceScreen())),
        GoRoute(path: 'gst', pageBuilder: (c, s) => _slide(const GstInclusiveExclusiveScreen())),
        GoRoute(path: 'payroll', pageBuilder: (c, s) => _slide(const PayrollScreen())),
      ],
    ),
    // Utility Category
    GoRoute(
      path: AppRoutes.utility,
      pageBuilder: (c, s) => _slide(const UtilityScreen()),
      routes: [
        GoRoute(path: 'percentage', pageBuilder: (c, s) => _slide(const PercentageScreen())),
        GoRoute(path: 'inflation', pageBuilder: (c, s) => _slide(const InflationScreen())),
        GoRoute(path: 'age', pageBuilder: (c, s) => _slide(const AgeCalculatorScreen())),
        GoRoute(path: 'date-difference', pageBuilder: (c, s) => _slide(const DateDifferenceScreen())),
        GoRoute(path: 'unit-converter', pageBuilder: (c, s) => _slide(const UnitConverterScreen())),
        GoRoute(path: 'bmi', pageBuilder: (c, s) => _slide(const BmiScreen())),
        GoRoute(path: 'fuel-cost', pageBuilder: (c, s) => _slide(const FuelCostScreen())),
        GoRoute(path: 'electricity-bill', pageBuilder: (c, s) => _slide(const ElectricityBillScreen())),
        GoRoute(path: 'tip', pageBuilder: (c, s) => _slide(const TipScreen())),
        GoRoute(path: 'split-bill', pageBuilder: (c, s) => _slide(const SplitBillScreen())),
        GoRoute(path: 'percent-change', pageBuilder: (c, s) => _slide(const PercentChangeScreen())),
      ],
    ),
  ],
);

CustomTransitionPage<void> _slide(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _tabs = [
    AppRoutes.home,
    AppRoutes.favorites,
    AppRoutes.history,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF39FF14).withValues(alpha: 0.15),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            context.go(_tabs[index]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

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
import '../../features/investment/presentation/calculators/mutual_fund_returns_screen.dart';
import '../../features/investment/presentation/calculators/sip_vs_lumpsum_screen.dart';
import '../../features/investment/presentation/calculators/dividend_yield_screen.dart';
import '../../features/investment/presentation/calculators/sharpe_ratio_screen.dart';
import '../../features/investment/presentation/calculators/annualized_return_screen.dart';
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
import '../../features/loan/presentation/calculators/loan_comparison_screen.dart';
import '../../features/loan/presentation/calculators/car_affordability_screen.dart';
import '../../features/loan/presentation/calculators/apr_vs_apy_screen.dart';
import '../../features/loan/presentation/calculators/debt_snowball_screen.dart';
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
import '../../features/savings/presentation/calculators/sinking_fund_screen.dart';
import '../../features/savings/presentation/calculators/savings_projection_screen.dart';
import '../../features/savings/presentation/calculators/goal_advanced_screen.dart';
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
import '../../features/business/presentation/calculators/depreciation_screen.dart';
import '../../features/business/presentation/calculators/working_capital_screen.dart';
import '../../features/business/presentation/calculators/ebitda_screen.dart';
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
import '../../features/utility/presentation/calculators/currency_converter_screen.dart';
import '../../features/utility/presentation/calculators/percentage_difference_screen.dart';
import '../../features/utility/presentation/calculators/compound_growth_screen.dart';
// Banking
import '../../features/banking/presentation/banking_screen.dart';
import '../../features/banking/presentation/calculators/net_worth_screen.dart';
import '../../features/banking/presentation/calculators/savings_interest_screen.dart';
import '../../features/banking/presentation/calculators/credit_card_interest_screen.dart';
import '../../features/banking/presentation/calculators/cash_flow_screen.dart';
import '../../features/banking/presentation/calculators/monthly_budget_screen.dart';
import '../../features/banking/presentation/calculators/bank_interest_screen.dart';
// Insurance
import '../../features/insurance/presentation/insurance_screen.dart';
import '../../features/insurance/presentation/calculators/term_insurance_screen.dart';
import '../../features/insurance/presentation/calculators/life_insurance_screen.dart';
import '../../features/insurance/presentation/calculators/health_insurance_screen.dart';
import '../../features/insurance/presentation/calculators/car_insurance_screen.dart';
import '../../features/insurance/presentation/calculators/insurance_need_screen.dart';
// Retirement
import '../../features/retirement/presentation/retirement_screen.dart';
import '../../features/retirement/presentation/calculators/fire_calculator_screen.dart';
import '../../features/retirement/presentation/calculators/retirement_corpus_screen.dart';
import '../../features/retirement/presentation/calculators/pension_calculator_screen.dart';
import '../../features/retirement/presentation/calculators/annuity_calculator_screen.dart';
import '../../features/retirement/presentation/calculators/withdrawal_calculator_screen.dart';
// Real Estate
import '../../features/real_estate/presentation/real_estate_screen.dart';
import '../../features/real_estate/presentation/calculators/rent_vs_buy_screen.dart';
import '../../features/real_estate/presentation/calculators/rental_yield_screen.dart';
import '../../features/real_estate/presentation/calculators/property_valuation_screen.dart';
import '../../features/real_estate/presentation/calculators/stamp_duty_screen.dart';
import '../../features/real_estate/presentation/calculators/construction_cost_screen.dart';
// Stock Market
import '../../features/stock_market/presentation/stock_market_screen.dart';
import '../../features/stock_market/presentation/calculators/stock_profit_screen.dart';
import '../../features/stock_market/presentation/calculators/stock_average_screen.dart';
import '../../features/stock_market/presentation/calculators/break_even_price_screen.dart';
import '../../features/stock_market/presentation/calculators/position_size_screen.dart';
import '../../features/stock_market/presentation/calculators/brokerage_calculator_screen.dart';
import '../../features/stock_market/presentation/calculators/margin_calculator_screen.dart';
// Crypto
import '../../features/crypto/presentation/crypto_screen.dart';
import '../../features/crypto/presentation/calculators/crypto_profit_screen.dart';
import '../../features/crypto/presentation/calculators/crypto_average_screen.dart';
import '../../features/crypto/presentation/calculators/crypto_staking_screen.dart';
import '../../features/crypto/presentation/calculators/crypto_dca_screen.dart';
import '../../features/crypto/presentation/calculators/crypto_position_size_screen.dart';

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
  static const mutualFundReturns = '/investment/mutual-fund-returns';
  static const sipVsLumpsum = '/investment/sip-vs-lumpsum';
  static const dividendYield = '/investment/dividend-yield';
  static const sharpeRatio = '/investment/sharpe-ratio';
  static const annualizedReturn = '/investment/annualized-return';
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
  static const loanComparison = '/loan/loan-comparison';
  static const carAffordability = '/loan/car-affordability';
  static const aprVsApy = '/loan/apr-vs-apy';
  static const debtSnowball = '/loan/debt-snowball';
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
  static const sinkingFund = '/savings/sinking-fund';
  static const savingsProjection = '/savings/savings-projection';
  static const goalAdvanced = '/savings/goal-advanced';
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
  static const depreciation = '/business/depreciation';
  static const workingCapital = '/business/working-capital';
  static const ebitda = '/business/ebitda';
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
  static const currencyConverter = '/utility/currency-converter';
  static const percentageDifference = '/utility/percentage-difference';
  static const compoundGrowth = '/utility/compound-growth';
  // Banking
  static const banking = '/banking';
  static const netWorth = '/banking/net-worth';
  static const savingsInterest = '/banking/savings-interest';
  static const creditCardInterest = '/banking/credit-card-interest';
  static const cashFlow = '/banking/cash-flow';
  static const monthlyBudget = '/banking/monthly-budget';
  static const bankInterest = '/banking/bank-interest';
  // Insurance
  static const insurance = '/insurance';
  static const termInsurance = '/insurance/term-insurance';
  static const lifeInsurance = '/insurance/life-insurance';
  static const healthInsurance = '/insurance/health-insurance';
  static const carInsurance = '/insurance/car-insurance';
  static const insuranceNeed = '/insurance/insurance-need';
  // Retirement
  static const retirementCategory = '/retirement';
  static const fireCalculator = '/retirement/fire';
  static const retirementCorpus = '/retirement/corpus';
  static const pensionCalculator = '/retirement/pension';
  static const annuityCalculator = '/retirement/annuity';
  static const withdrawalCalculator = '/retirement/withdrawal';
  // Real Estate
  static const realEstate = '/real-estate';
  static const rentVsBuy = '/real-estate/rent-vs-buy';
  static const rentalYield = '/real-estate/rental-yield';
  static const propertyValuation = '/real-estate/property-valuation';
  static const stampDuty = '/real-estate/stamp-duty';
  static const constructionCost = '/real-estate/construction-cost';
  // Stock Market
  static const stockMarket = '/stock-market';
  static const stockProfit = '/stock-market/stock-profit';
  static const stockAverage = '/stock-market/stock-average';
  static const breakEvenPrice = '/stock-market/break-even-price';
  static const positionSize = '/stock-market/position-size';
  static const brokerageCalculator = '/stock-market/brokerage';
  static const marginCalculator = '/stock-market/margin';
  // Crypto
  static const crypto = '/crypto';
  static const cryptoProfit = '/crypto/profit';
  static const cryptoAverage = '/crypto/average';
  static const cryptoStaking = '/crypto/staking';
  static const cryptoDca = '/crypto/dca';
  static const cryptoPositionSize = '/crypto/position-size';
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
    // Investment
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
        GoRoute(path: 'mutual-fund-returns', pageBuilder: (c, s) => _slide(const MutualFundReturnsScreen())),
        GoRoute(path: 'sip-vs-lumpsum', pageBuilder: (c, s) => _slide(const SipVsLumpsumScreen())),
        GoRoute(path: 'dividend-yield', pageBuilder: (c, s) => _slide(const DividendYieldScreen())),
        GoRoute(path: 'sharpe-ratio', pageBuilder: (c, s) => _slide(const SharpeRatioScreen())),
        GoRoute(path: 'annualized-return', pageBuilder: (c, s) => _slide(const AnnualizedReturnScreen())),
      ],
    ),
    // Loan
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
        GoRoute(path: 'loan-comparison', pageBuilder: (c, s) => _slide(const LoanComparisonScreen())),
        GoRoute(path: 'car-affordability', pageBuilder: (c, s) => _slide(const CarAffordabilityScreen())),
        GoRoute(path: 'apr-vs-apy', pageBuilder: (c, s) => _slide(const AprVsApyScreen())),
        GoRoute(path: 'debt-snowball', pageBuilder: (c, s) => _slide(const DebtSnowballScreen())),
      ],
    ),
    // Savings
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
        GoRoute(path: 'sinking-fund', pageBuilder: (c, s) => _slide(const SinkingFundScreen())),
        GoRoute(path: 'savings-projection', pageBuilder: (c, s) => _slide(const SavingsProjectionScreen())),
        GoRoute(path: 'goal-advanced', pageBuilder: (c, s) => _slide(const GoalAdvancedScreen())),
      ],
    ),
    // Tax
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
    // Business
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
        GoRoute(path: 'depreciation', pageBuilder: (c, s) => _slide(const DepreciationScreen())),
        GoRoute(path: 'working-capital', pageBuilder: (c, s) => _slide(const WorkingCapitalScreen())),
        GoRoute(path: 'ebitda', pageBuilder: (c, s) => _slide(const EbitdaScreen())),
      ],
    ),
    // Utility
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
        GoRoute(path: 'currency-converter', pageBuilder: (c, s) => _slide(const CurrencyConverterScreen())),
        GoRoute(path: 'percentage-difference', pageBuilder: (c, s) => _slide(const PercentageDifferenceScreen())),
        GoRoute(path: 'compound-growth', pageBuilder: (c, s) => _slide(const CompoundGrowthScreen())),
      ],
    ),
    // Banking
    GoRoute(
      path: AppRoutes.banking,
      pageBuilder: (c, s) => _slide(const BankingScreen()),
      routes: [
        GoRoute(path: 'net-worth', pageBuilder: (c, s) => _slide(const NetWorthScreen())),
        GoRoute(path: 'savings-interest', pageBuilder: (c, s) => _slide(const SavingsInterestScreen())),
        GoRoute(path: 'credit-card-interest', pageBuilder: (c, s) => _slide(const CreditCardInterestScreen())),
        GoRoute(path: 'cash-flow', pageBuilder: (c, s) => _slide(const CashFlowScreen())),
        GoRoute(path: 'monthly-budget', pageBuilder: (c, s) => _slide(const MonthlyBudgetScreen())),
        GoRoute(path: 'bank-interest', pageBuilder: (c, s) => _slide(const BankInterestScreen())),
      ],
    ),
    // Insurance
    GoRoute(
      path: AppRoutes.insurance,
      pageBuilder: (c, s) => _slide(const InsuranceScreen()),
      routes: [
        GoRoute(path: 'term-insurance', pageBuilder: (c, s) => _slide(const TermInsuranceScreen())),
        GoRoute(path: 'life-insurance', pageBuilder: (c, s) => _slide(const LifeInsuranceScreen())),
        GoRoute(path: 'health-insurance', pageBuilder: (c, s) => _slide(const HealthInsuranceScreen())),
        GoRoute(path: 'car-insurance', pageBuilder: (c, s) => _slide(const CarInsuranceScreen())),
        GoRoute(path: 'insurance-need', pageBuilder: (c, s) => _slide(const InsuranceNeedScreen())),
      ],
    ),
    // Retirement
    GoRoute(
      path: AppRoutes.retirementCategory,
      pageBuilder: (c, s) => _slide(const RetirementScreen()),
      routes: [
        GoRoute(path: 'fire', pageBuilder: (c, s) => _slide(const FireCalculatorScreen())),
        GoRoute(path: 'corpus', pageBuilder: (c, s) => _slide(const RetirementCorpusScreen())),
        GoRoute(path: 'pension', pageBuilder: (c, s) => _slide(const PensionCalculatorScreen())),
        GoRoute(path: 'annuity', pageBuilder: (c, s) => _slide(const AnnuityCalculatorScreen())),
        GoRoute(path: 'withdrawal', pageBuilder: (c, s) => _slide(const WithdrawalCalculatorScreen())),
      ],
    ),
    // Real Estate
    GoRoute(
      path: AppRoutes.realEstate,
      pageBuilder: (c, s) => _slide(const RealEstateScreen()),
      routes: [
        GoRoute(path: 'rent-vs-buy', pageBuilder: (c, s) => _slide(const RentVsBuyScreen())),
        GoRoute(path: 'rental-yield', pageBuilder: (c, s) => _slide(const RentalYieldScreen())),
        GoRoute(path: 'property-valuation', pageBuilder: (c, s) => _slide(const PropertyValuationScreen())),
        GoRoute(path: 'stamp-duty', pageBuilder: (c, s) => _slide(const StampDutyScreen())),
        GoRoute(path: 'construction-cost', pageBuilder: (c, s) => _slide(const ConstructionCostScreen())),
      ],
    ),
    // Stock Market
    GoRoute(
      path: AppRoutes.stockMarket,
      pageBuilder: (c, s) => _slide(const StockMarketScreen()),
      routes: [
        GoRoute(path: 'stock-profit', pageBuilder: (c, s) => _slide(const StockProfitScreen())),
        GoRoute(path: 'stock-average', pageBuilder: (c, s) => _slide(const StockAverageScreen())),
        GoRoute(path: 'break-even-price', pageBuilder: (c, s) => _slide(const BreakEvenPriceScreen())),
        GoRoute(path: 'position-size', pageBuilder: (c, s) => _slide(const PositionSizeScreen())),
        GoRoute(path: 'brokerage', pageBuilder: (c, s) => _slide(const BrokerageCalculatorScreen())),
        GoRoute(path: 'margin', pageBuilder: (c, s) => _slide(const MarginCalculatorScreen())),
      ],
    ),
    // Crypto
    GoRoute(
      path: AppRoutes.crypto,
      pageBuilder: (c, s) => _slide(const CryptoScreen()),
      routes: [
        GoRoute(path: 'profit', pageBuilder: (c, s) => _slide(const CryptoProfitScreen())),
        GoRoute(path: 'average', pageBuilder: (c, s) => _slide(const CryptoAverageScreen())),
        GoRoute(path: 'staking', pageBuilder: (c, s) => _slide(const CryptoStakingScreen())),
        GoRoute(path: 'dca', pageBuilder: (c, s) => _slide(const CryptoDcaScreen())),
        GoRoute(path: 'position-size', pageBuilder: (c, s) => _slide(const CryptoPositionSizeScreen())),
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

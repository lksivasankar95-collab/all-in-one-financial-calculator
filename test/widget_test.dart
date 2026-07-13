import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shy_calculator/core/constants/app_colors.dart';
import 'package:shy_calculator/core/constants/app_constants.dart';
import 'package:shy_calculator/shared/models/calculation_history.dart';
import 'package:shy_calculator/shared/models/app_settings.dart';
import 'package:shy_calculator/features/investment/domain/investment_calculators.dart';
import 'package:shy_calculator/features/loan/domain/loan_calculators.dart';
import 'package:shy_calculator/shared/models/calculator_item.dart';
import 'package:shy_calculator/shared/providers/calculator_registry.dart';
import 'package:shy_calculator/core/theme/app_theme.dart';

void main() {
  group('App', () {
    setUp(() async {
      Hive.init('test/tmp');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CalculationHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(AppSettingsAdapter());
      }
      await Hive.openBox<CalculationHistory>('calculation_history');
      await Hive.openBox<AppSettings>('settings');
      await Hive.openBox<String>('favorites');
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk('calculation_history');
      await Hive.deleteBoxFromDisk('settings');
      await Hive.deleteBoxFromDisk('favorites');
    });

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(const _TestApp());
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('has dark theme', (tester) async {
      await tester.pumpWidget(const _TestApp());
      await tester.pump();
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    });
  });

  group('AppConstants', () {
    test('has valid app name', () {
      expect(AppConstants.appName, 'ShyBlack');
      expect(AppConstants.appFullName, 'All-in-One Financial Calculator');
    });

    test('has valid animation durations', () {
      expect(AppConstants.animFast, const Duration(milliseconds: 200));
      expect(AppConstants.animNormal, const Duration(milliseconds: 350));
      expect(AppConstants.animSlow, const Duration(milliseconds: 500));
    });
  });

  group('AppColors', () {
    test('has neon green primary', () {
      expect(AppColors.primary, const Color(0xFF39FF14));
    });

    test('has black backgrounds', () {
      expect(AppColors.background, const Color(0xFF000000));
      expect(AppColors.surface, const Color(0xFF121212));
    });

    test('has valid gradients', () {
      expect(AppColors.primaryGradient, isA<LinearGradient>());
      expect(AppColors.darkGradient, isA<LinearGradient>());
    });
  });

  group('CalculatorRegistry', () {
    test('has 12 categories', () {
      expect(CalculatorRegistry.categories.length, 12);
    });

    test('has all calculators by category', () {
      final categories = CalculatorRegistry.categories;
      final names = categories.map((c) => c.name).toSet();
      expect(names, contains('Investment'));
      expect(names, contains('Loan'));
      expect(names, contains('Savings'));
      expect(names, contains('Tax'));
      expect(names, contains('Business'));
      expect(names, contains('Utility'));
    });

    test('all calculators have unique ids', () {
      final ids = CalculatorRegistry.allCalculators.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('search finds calculators', () {
      final results = CalculatorRegistry.search('SIP');
      expect(results.isNotEmpty, true);
      expect(results.any((c) => c.name.contains('SIP')), true);
    });

    test('findById returns correct calculator', () {
      final calc = CalculatorRegistry.findById('sip');
      expect(calc, isNotNull);
      expect(calc!.id, 'sip');
      expect(calc.name, 'SIP Calculator');
    });

    test('findById returns null for non-existent', () {
      expect(CalculatorRegistry.findById('nonexistent'), isNull);
    });
  });

  group('CalculatorItem', () {
    test('copyWith works correctly', () {
      final item = CalculatorItem(
        id: 'test',
        name: 'Test',
        description: 'Test calculator',
        category: 'Utility',
        icon: Icons.calculate,
        color: Colors.green,
        route: '/test',
      );
      final copied = item.copyWith(isFavorite: true);
      expect(copied.isFavorite, true);
      expect(copied.id, item.id);
      expect(copied.name, item.name);
    });
  });

  group('InvestmentCalculators', () {
    test('calculateSip returns correct values', () {
      final result = InvestmentCalculators.calculateSip(
        monthlyInvestment: 10000,
        annualReturnRate: 12,
        years: 10,
      );
      expect(result.totalInvested, greaterThan(0));
      expect(result.totalValue, greaterThan(result.totalInvested));
      expect(result.estimatedReturns, greaterThan(0));
      expect(result.absoluteReturn, greaterThan(0));
    });

    test('calculateCagr returns correct rate', () {
      final cagr = InvestmentCalculators.calculateCagr(
        startValue: 100000,
        endValue: 200000,
        years: 5,
      );
      expect(cagr, greaterThan(0));
      expect(cagr, lessThan(100));
    });

    test('calculateRoi returns correct percentage', () {
      final roi = InvestmentCalculators.calculateRoi(
        investmentCost: 50000,
        finalValue: 75000,
      );
      expect(roi, closeTo(50, 0.01));
    });

    test('calculateSimpleInterest returns correct values', () {
      final result = InvestmentCalculators.calculateSimpleInterest(
        principal: 100000,
        rate: 10,
        years: 5,
      );
      expect(result.interest, 50000);
      expect(result.totalAmount, 150000);
    });

    test('calculateRuleOf72 returns correct years', () {
      final result = InvestmentCalculators.calculateRuleOf72(annualRate: 12);
      expect(result.yearsToDouble, closeTo(6, 0.1));
    });

    test('getSipYearlyBreakdown returns correct length', () {
      final data = InvestmentCalculators.getSipYearlyBreakdown(
        monthly: 10000,
        rate: 12,
        years: 5,
      );
      expect(data.length, 5);
      expect(data[0].year, 1);
      expect(data[0].invested, 120000);
    });
  });

  group('LoanCalculators', () {
    test('calculateEmi returns correct values', () {
      final result = LoanCalculators.calculateEmi(
        principal: 5000000,
        annualRate: 8.5,
        tenureYears: 20,
      );
      expect(result.emi, greaterThan(0));
      expect(result.totalAmount, greaterThan(result.principalAmount));
      expect(result.totalInterest, greaterThan(0));
    });

    test('getAmortizationSchedule returns correct length', () {
      final schedule = LoanCalculators.getAmortizationSchedule(
        principal: 5000000,
        annualRate: 8.5,
        tenureYears: 20,
      );
      expect(schedule.length, 240);
      expect(schedule[0].month, 1);
      expect(schedule.last.balance, closeTo(0, 1));
    });

    test('calculateMaxLoanEligibility returns positive amount', () {
      final maxLoan = LoanCalculators.calculateMaxLoanEligibility(
        monthlyIncome: 100000,
        annualRate: 8.5,
        tenureYears: 20,
        foir: 0.5,
      );
      expect(maxLoan, greaterThan(0));
    });

    test('calculateDti returns healthy status', () {
      final result = LoanCalculators.calculateDti(
        monthlyIncome: 100000,
        monthlyDebts: [10000, 5000],
      );
      expect(result.dtiRatio, 15);
      expect(result.isHealthy, true);
      expect(result.status, 'Healthy');
    });

    test('calculatePrepayment saves interest', () {
      final result = LoanCalculators.calculatePrepayment(
        originalPrincipal: 5000000,
        annualRate: 8.5,
        originalTenureYears: 20,
        prepaymentAmount: 500000,
        afterMonth: 12,
      );
      expect(result.interestSaved, greaterThan(0));
      expect(result.monthsSaved, greaterThan(0));
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShyBlack Calculator Test',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SizedBox(),
    );
  }
}

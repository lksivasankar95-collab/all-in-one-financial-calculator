import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Color(0xFF000000),
        primaryContainer: Color(0xFF003300),
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.accent,
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFF003B3B),
        onSecondaryContainer: AppColors.accent,
        tertiary: AppColors.primaryDark,
        onTertiary: Color(0xFF000000),
        error: AppColors.error,
        onError: Color(0xFF000000),
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      chipTheme: _buildChipTheme(),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      snackBarTheme: _buildSnackBarTheme(),
      dialogTheme: _buildDialogTheme(),
      switchTheme: _buildSwitchTheme(),
      checkboxTheme: _buildCheckboxTheme(),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
      sliderTheme: _buildSliderTheme(),
    );
  }

  static TextTheme _buildTextTheme() {
    final font = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return font.copyWith(
      displayLarge: font.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
      displayMedium: font.displayMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      displaySmall: font.displaySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineLarge: font.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineMedium: font.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      headlineSmall: font.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleLarge: font.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium: font.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      titleSmall: font.titleSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      bodyLarge: font.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: font.bodyMedium?.copyWith(color: AppColors.textSecondary),
      bodySmall: font.bodySmall?.copyWith(color: AppColors.textHint),
      labelLarge: font.labelLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      labelMedium: font.labelMedium?.copyWith(color: AppColors.textSecondary),
      labelSmall: font.labelSmall?.copyWith(color: AppColors.textHint),
    );
  }

  static AppBarTheme _buildAppBarTheme() => const AppBarTheme(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  static CardThemeData _buildCardTheme() => CardThemeData(
    color: AppColors.card,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
  );

  static InputDecorationTheme _buildInputDecorationTheme() => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    labelStyle: const TextStyle(color: AppColors.textHint),
    hintStyle: const TextStyle(color: AppColors.textHint),
    prefixIconColor: AppColors.textHint,
    suffixIconColor: AppColors.textHint,
    errorStyle: const TextStyle(color: AppColors.error),
  );

  static ElevatedButtonThemeData _buildElevatedButtonTheme() => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  static TextButtonThemeData _buildTextButtonTheme() => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static BottomNavigationBarThemeData _buildBottomNavTheme() => const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textHint,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 11),
  );

  static ChipThemeData _buildChipTheme() => ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.primary.withValues(alpha: 0.15),
    side: const BorderSide(color: AppColors.border),
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  static SnackBarThemeData _buildSnackBarTheme() => SnackBarThemeData(
    backgroundColor: AppColors.cardElevated,
    contentTextStyle: const TextStyle(color: AppColors.textPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
    elevation: 0,
  );

  static DialogThemeData _buildDialogTheme() => DialogThemeData(
    backgroundColor: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    titleTextStyle: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    contentTextStyle: const TextStyle(color: AppColors.textSecondary),
  );

  static SwitchThemeData _buildSwitchTheme() => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.black;
      return AppColors.textHint;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primary;
      return AppColors.border;
    }),
  );

  static CheckboxThemeData _buildCheckboxTheme() => CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primary;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(Colors.black),
    side: const BorderSide(color: AppColors.border, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );

  static SliderThemeData _buildSliderTheme() => const SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.border,
    thumbColor: AppColors.primary,
    overlayColor: Color(0x2039FF14),
    valueIndicatorColor: AppColors.primary,
    valueIndicatorTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
  );
}

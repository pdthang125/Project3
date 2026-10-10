import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens and color palette for the app (Light theme)
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5148E0);
  static const Color primaryLight = Color(0xFF8C85FF);
  static const Color primarySoft = Color(0xFFEEECFF); // nền tint nhẹ cho chip, icon
  static const Color accent = Color(0xFF00B894);
  static const Color accentDark = Color(0xFF009B7D);

  // Background (giữ tên cũ để không phải sửa các màn hình khác)
  static const Color backgroundDark = Color(0xFFF6F7FB); // nền scaffold
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundElevated = Color(0xFFF0F1FA);
  static const Color backgroundInput = Color(0xFFF3F4FA);

  // Surface
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0F2FA);

  // Text
  static const Color textPrimary = Color(0xFF1B1B2F);
  static const Color textSecondary = Color(0xFF5E6283);
  static const Color textMuted = Color(0xFF9A9DB5);
  static const Color textOnPrimary = Colors.white;

  // Status
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Category Colors (đậm hơn một chút để rõ trên nền sáng)
  static const Color catFood = Color(0xFFFF6B6B);
  static const Color catStudy = Color(0xFF4D9DE0);
  static const Color catTravel = Color(0xFFF5B700);
  static const Color catGear = Color(0xFF3DBE6B);
  static const Color catEntertainment = Color(0xFFA855F7);
  static const Color catOther = Color(0xFF8A8DA8);

  // Glass / border
  static const Color glassWhite = Color(0xB3FFFFFF);
  static const Color glassBorder = Color(0xFFE6E8F2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7F77FF), Color(0xFF5B52F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2DD4A7), Color(0xFF00A98A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return catFood;
      case 'study':
        return catStudy;
      case 'travel':
        return catTravel;
      case 'gear':
        return catGear;
      case 'entertainment':
        return catEntertainment;
      default:
        return catOther;
    }
  }
}

class AppTheme {
  AppTheme._();

  /// Theme sáng (chính)
  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundInput,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primarySoft,
        selectedColor: AppColors.primary,
        side: BorderSide.none,
        labelStyle: GoogleFonts.outfit(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Giữ lại tên cũ để code cũ gọi AppTheme.darkTheme vẫn chạy (trả về theme sáng).
  static ThemeData get darkTheme => lightTheme;
}

/// Application-wide constants for persistence, categories, and OCR parsing.
class AppConstants {
  AppConstants._();

  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;
  static const String transactionsTable = 'transactions';
  static const String categoriesTable = 'categories';

  static const List<String> defaultCategories = [
    'Food',
    'Study',
    'Travel',
    'Gear',
    'Entertainment',
    'Other',
  ];

  static const String amountPatternVND =
      r'([\d.,]+)\s*(?:VND|VNĐ|đ|₫)';
  static const String datePatternDMY =
      r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})\b';
  static const String datePatternFull =
      r'\b(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})\b';
}
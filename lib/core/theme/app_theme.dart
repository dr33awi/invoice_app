import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';

/// Enterprise Theme Configuration
/// Material 3 Design System
/// Optimized for 8+ hours daily use
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTypography.primaryFont,

        // ═══════════════════════════════════════════════════════════
        // COLOR SCHEME
        // ═══════════════════════════════════════════════════════════

        colorScheme: const ColorScheme.light(
          primary: AppColors.blue600,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD6E4FF),
          onPrimaryContainer: Color(0xFF001A41),
          secondary: AppColors.teal600,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFCCF4F0),
          onSecondaryContainer: Color(0xFF00201E),
          tertiary: AppColors.slate800,
          onTertiary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: Color(0xFFFEE2E2),
          onErrorContainer: Color(0xFF7F1D1D),
          surface: AppColors.surfaceBg,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.screenBg,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.borderColor,
          outlineVariant: Color(0xFFF1F5F9),
          shadow: Color(0x1A000000),
        ),

        // ═══════════════════════════════════════════════════════════
        // SCAFFOLD
        // ═══════════════════════════════════════════════════════════

        scaffoldBackgroundColor: AppColors.screenBg,

        // ═══════════════════════════════════════════════════════════
        // APP BAR
        // ═══════════════════════════════════════════════════════════

        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceBg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
          iconTheme: IconThemeData(
            color: AppColors.textSecondary,
            size: 22.sp,
          ),
          actionsIconTheme: IconThemeData(
            color: AppColors.textSecondary,
            size: 22.sp,
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // CARDS
        // ═══════════════════════════════════════════════════════════

        cardTheme: CardThemeData(
          color: AppColors.surfaceBg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusCard,
            side: const BorderSide(
              color: AppColors.borderColor,
              width: 1,
            ),
          ),
          margin: EdgeInsets.zero,
        ),

        // ═══════════════════════════════════════════════════════════
        // ELEVATED BUTTON
        // ═══════════════════════════════════════════════════════════

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue600,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.borderColor,
            disabledForegroundColor: AppColors.textMuted,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 12.h,
            ),
            minimumSize: Size(88.w, AppSpacing.buttonHeightMd),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusButton,
            ),
            textStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // FILLED BUTTON
        // ═══════════════════════════════════════════════════════════

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue600,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.borderColor,
            disabledForegroundColor: AppColors.textMuted,
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 12.h,
            ),
            minimumSize: Size(88.w, AppSpacing.buttonHeightMd),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusButton,
            ),
            textStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // OUTLINED BUTTON
        // ═══════════════════════════════════════════════════════════

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.blue600,
            disabledForegroundColor: AppColors.textMuted,
            side: const BorderSide(
              color: AppColors.blue600,
              width: 1.5,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 12.h,
            ),
            minimumSize: Size(88.w, AppSpacing.buttonHeightMd),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusButton,
            ),
            textStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // TEXT BUTTON
        // ═══════════════════════════════════════════════════════════

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.blue600,
            disabledForegroundColor: AppColors.textMuted,
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            minimumSize: Size(64.w, 36.h),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusButton,
            ),
            textStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // ICON BUTTON
        // ═══════════════════════════════════════════════════════════

        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            highlightColor: AppColors.hoverOverlay,
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // FLOATING ACTION BUTTON
        // ═══════════════════════════════════════════════════════════

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.blue600,
          foregroundColor: Colors.white,
          elevation: 2,
          focusElevation: 4,
          hoverElevation: 4,
          highlightElevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // INPUT DECORATION (TEXT FIELDS)
        // ═══════════════════════════════════════════════════════════

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceBg,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusField,
            borderSide: const BorderSide(
              color: AppColors.borderColor,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusField,
            borderSide: const BorderSide(
              color: AppColors.borderColor,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusField,
            borderSide: const BorderSide(
              color: AppColors.blue600,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusField,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusField,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusField,
            borderSide: const BorderSide(
              color: AppColors.borderColor,
              width: 1,
            ),
          ),
          labelStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          floatingLabelStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.blue600,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          errorStyle: AppTypography.labelSmall.copyWith(
            color: AppColors.error,
          ),
          prefixIconColor: AppColors.textSecondary,
          suffixIconColor: AppColors.textSecondary,
        ),

        // ═══════════════════════════════════════════════════════════
        // DIVIDER
        // ═══════════════════════════════════════════════════════════

        dividerTheme: const DividerThemeData(
          color: AppColors.borderColor,
          thickness: 1,
          space: 1,
        ),

        // ═══════════════════════════════════════════════════════════
        // CHIP
        // ═══════════════════════════════════════════════════════════

        chipTheme: ChipThemeData(
          backgroundColor: AppColors.screenBg,
          selectedColor: AppColors.blue600.withOpacity(0.1),
          disabledColor: AppColors.borderColor,
          labelStyle: AppTypography.labelMedium,
          secondaryLabelStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.blue600,
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusChip,
            side: const BorderSide(color: AppColors.borderColor),
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // DIALOG
        // ═══════════════════════════════════════════════════════════

        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceBg,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusDialog,
          ),
          titleTextStyle: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          contentTextStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // BOTTOM SHEET
        // ═══════════════════════════════════════════════════════════

        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surfaceBg,
          elevation: 8,
          modalBackgroundColor: AppColors.surfaceBg,
          modalElevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusBottomSheet,
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // SNACK BAR
        // ═══════════════════════════════════════════════════════════

        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.slate800,
          contentTextStyle: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusCard,
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // LIST TILE
        // ═══════════════════════════════════════════════════════════

        listTileTheme: ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusCard,
          ),
          titleTextStyle: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          subtitleTextStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          leadingAndTrailingTextStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // ═══════════════════════════════════════════════════════════
        // TAB BAR
        // ═══════════════════════════════════════════════════════════

        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.blue600,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.labelLarge,
          indicatorColor: AppColors.blue600,
          indicatorSize: TabBarIndicatorSize.label,
        ),

        // ═══════════════════════════════════════════════════════════
        // NAVIGATION BAR
        // ═══════════════════════════════════════════════════════════

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surfaceBg,
          elevation: 0,
          indicatorColor: AppColors.blue600.withOpacity(0.1),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTypography.labelSmall.copyWith(
                color: AppColors.blue600,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                color: AppColors.blue600,
                size: 24.sp,
              );
            }
            return IconThemeData(
              color: AppColors.textSecondary,
              size: 24.sp,
            );
          }),
        ),

        // ═══════════════════════════════════════════════════════════
        // PROGRESS INDICATOR
        // ═══════════════════════════════════════════════════════════

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.blue600,
          linearTrackColor: AppColors.borderColor,
          circularTrackColor: AppColors.borderColor,
        ),

        // ═══════════════════════════════════════════════════════════
        // TEXT THEME
        // ═══════════════════════════════════════════════════════════

        textTheme: TextTheme(
          displayLarge: AppTypography.displayLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          displayMedium: AppTypography.displayMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          displaySmall: AppTypography.displaySmall.copyWith(
            color: AppColors.textPrimary,
          ),
          headlineLarge: AppTypography.headlineLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          headlineMedium: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          headlineSmall: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          titleLarge: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          titleMedium: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          titleSmall: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          bodyLarge: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          bodyMedium: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          bodySmall: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          labelLarge: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          labelMedium: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          labelSmall: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Enterprise Typography System
/// Primary: IBM Plex Sans Arabic (UI text)
/// Mono: IBM Plex Mono (Numbers, Money)
/// Fallback: Cairo
abstract class AppTypography {
  // ═══════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ═══════════════════════════════════════════════════════════

  static const String primaryFont = 'IBM Plex Sans Arabic';
  static const String monoFont = 'IBM Plex Mono';
  static const String fallbackFont = 'Cairo';

  // ═══════════════════════════════════════════════════════════
  // DISPLAY STYLES (Large titles, hero text)
  // ═══════════════════════════════════════════════════════════

  static TextStyle get displayLarge => TextStyle(
        fontFamily: primaryFont,
        fontSize: 42.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: primaryFont,
        fontSize: 36.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.25,
      );

  static TextStyle get displaySmall => TextStyle(
        fontFamily: primaryFont,
        fontSize: 30.sp,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  // ═══════════════════════════════════════════════════════════
  // HEADLINE STYLES (Section headers, card titles)
  // ═══════════════════════════════════════════════════════════

  static TextStyle get headlineLarge => TextStyle(
        fontFamily: primaryFont,
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontFamily: primaryFont,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontFamily: primaryFont,
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // ═══════════════════════════════════════════════════════════
  // TITLE STYLES (List item titles, dialog titles)
  // ═══════════════════════════════════════════════════════════

  static TextStyle get titleLarge => TextStyle(
        fontFamily: primaryFont,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: primaryFont,
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get titleSmall => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  // ═══════════════════════════════════════════════════════════
  // BODY STYLES (Paragraphs, descriptions)
  // ═══════════════════════════════════════════════════════════

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: primaryFont,
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: primaryFont,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ═══════════════════════════════════════════════════════════
  // LABEL STYLES (Buttons, form labels, chips)
  // ═══════════════════════════════════════════════════════════

  static TextStyle get labelLarge => TextStyle(
        fontFamily: primaryFont,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: primaryFont,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: primaryFont,
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  // ═══════════════════════════════════════════════════════════
  // MONEY STYLES (Monospace for numbers and currency)
  // ═══════════════════════════════════════════════════════════

  static TextStyle get moneyLarge => TextStyle(
        fontFamily: monoFont,
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get moneyMedium => TextStyle(
        fontFamily: monoFont,
        fontSize: 18.sp,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get moneySmall => TextStyle(
        fontFamily: monoFont,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get moneyTiny => TextStyle(
        fontFamily: monoFont,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // ═══════════════════════════════════════════════════════════
  // CODE STYLES (Technical text, IDs, codes)
  // ═══════════════════════════════════════════════════════════

  static TextStyle get codeLarge => TextStyle(
        fontFamily: monoFont,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get codeSmall => TextStyle(
        fontFamily: monoFont,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );
}

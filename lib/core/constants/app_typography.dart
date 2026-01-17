import 'package:flutter/material.dart';

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

  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // ═══════════════════════════════════════════════════════════
  // HEADLINE STYLES (Section headers, card titles)
  // ═══════════════════════════════════════════════════════════

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════
  // TITLE STYLES (List item titles, dialog titles)
  // ═══════════════════════════════════════════════════════════

  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════
  // BODY STYLES (Paragraphs, descriptions)
  // ═══════════════════════════════════════════════════════════

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════
  // LABEL STYLES (Buttons, form labels, chips)
  // ═══════════════════════════════════════════════════════════

  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // ═══════════════════════════════════════════════════════════
  // MONEY STYLES (Monospace for numbers and currency)
  // ═══════════════════════════════════════════════════════════

  static const TextStyle moneyLarge = TextStyle(
    fontFamily: monoFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: monoFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle moneySmall = TextStyle(
    fontFamily: monoFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle moneyTiny = TextStyle(
    fontFamily: monoFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════
  // CODE STYLES (Technical text, IDs, codes)
  // ═══════════════════════════════════════════════════════════

  static const TextStyle codeLarge = TextStyle(
    fontFamily: monoFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle codeSmall = TextStyle(
    fontFamily: monoFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}

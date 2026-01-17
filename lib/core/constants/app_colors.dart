import 'package:flutter/material.dart';

/// Enterprise Accounting Color Palette
/// Designed for professional use (8+ hours daily)
abstract class AppColors {
  // ═══════════════════════════════════════════════════════════
  // PRIMARY PALETTE
  // ═══════════════════════════════════════════════════════════

  /// Main dark color for headers and primary elements
  static const slate800 = Color(0xFF1E293B);

  /// Primary action color
  static const blue600 = Color(0xFF2563EB);

  /// Secondary accent color
  static const teal600 = Color(0xFF0D9488);

  // ═══════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════

  /// Success states, positive values
  static const success = Color(0xFF15803D);

  /// Error states, negative values, warnings
  static const error = Color(0xFFDC2626);

  /// Warning states, caution indicators
  static const warning = Color(0xFFD97706);

  /// Informational states
  static const info = Color(0xFF2563EB);

  // ═══════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ═══════════════════════════════════════════════════════════

  /// Main screen background (light gray)
  static const screenBg = Color(0xFFF8FAFC);

  /// Surface background (white - cards, dialogs)
  static const surfaceBg = Color(0xFFFFFFFF);

  /// Border color for cards, inputs, dividers
  static const borderColor = Color(0xFFE2E8F0);

  /// Hover/pressed state overlay
  static const hoverOverlay = Color(0x0A000000);

  // ═══════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════

  /// Primary text (headings, important content)
  static const textPrimary = Color(0xFF1E293B);

  /// Secondary text (descriptions, labels)
  static const textSecondary = Color(0xFF64748B);

  /// Muted text (placeholders, hints)
  static const textMuted = Color(0xFF94A3B8);

  /// Disabled text
  static const textDisabled = Color(0xFFCBD5E1);

  // ═══════════════════════════════════════════════════════════
  // MONEY COLORS
  // ═══════════════════════════════════════════════════════════

  /// Positive money values (income, credit)
  static const moneyPositive = Color(0xFF15803D);

  /// Negative money values (expense, debit)
  static const moneyNegative = Color(0xFFDC2626);

  /// Neutral money values
  static const moneyNeutral = Color(0xFF1E293B);

  // ═══════════════════════════════════════════════════════════
  // STATUS COLORS
  // ═══════════════════════════════════════════════════════════

  /// Pending/draft status
  static const statusPending = Color(0xFFF59E0B);

  /// Completed/approved status
  static const statusCompleted = Color(0xFF10B981);

  /// Cancelled/rejected status
  static const statusCancelled = Color(0xFFEF4444);

  /// On hold status
  static const statusOnHold = Color(0xFF6366F1);

  // ═══════════════════════════════════════════════════════════
  // GRADIENT COLORS
  // ═══════════════════════════════════════════════════════════

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue600, teal600],
  );

  static const gradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [slate800, Color(0xFF334155)],
  );
}
